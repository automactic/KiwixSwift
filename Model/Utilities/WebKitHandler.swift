// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import os
import WebKit

/// Skipping handling for HTTP 206 Partial Content
/// For video playback, WebKit makes a large amount of requests with small byte range (e.g. 8 bytes)
/// to retrieve content of the video.
/// As a result of the large volume of small requests, CPU usage will be very high,
/// which can result in app or webpage frozen.
/// To mitigate, opting for the less "broken" behavior of ignoring Range header
/// until WebKit behavior is changed.
final class KiwixURLSchemeHandler: NSObject, WKURLSchemeHandler {
    static let KiwixScheme = "kiwix"
    private let inSync = InSync(label: "org.kiwix.url.scheme.sync")
    private var startedTasks: [Int: Bool] = [:]

    // MARK: Life cycle

    private func startFor(_ hashValue: Int) async {
        await withCheckedContinuation { continuation in
            inSync.execute {
                self.startedTasks[hashValue] = true
                continuation.resume()
            }
        }
    }

    private func isStartedFor(_ hashValue: Int) -> Bool {
        return inSync.read {
            self.startedTasks[hashValue] != nil
        }
    }

    private func stopFor(_ hashValue: Int) {
        inSync.execute {
            self.startedTasks.removeValue(forKey: hashValue)
        }
    }

    private func stopAll() {
        inSync.execute {
            self.startedTasks.removeAll()
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        stopFor(urlSchemeTask.hash)
    }

    func didFailProvisionalNavigation() {
        stopAll()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard isStartedFor(urlSchemeTask.hash) == false else { return }
        Task {
            await startFor(urlSchemeTask.hash)
            await handle(task: urlSchemeTask)
        }
    }

    @MainActor
    private func handle(task urlSchemeTask: WKURLSchemeTask) async {
        let request = urlSchemeTask.request
        guard let url = request.url, url.isKiwixURL else {
            urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
            stopFor(urlSchemeTask.hash)
            return
        }
        // blocking any video or ogv javascript files to be loaded
        let fileName = url.lastPathComponent
        if fileName.hasSuffix(".js"),
           (fileName.contains("video") || fileName.contains("ogv")) {
            urlSchemeTask.didFailWithError(URLError(.resourceUnavailable))
            stopFor(urlSchemeTask.hash)
        }

        guard let metaData = await contentMetaData(for: url) else {
            sendHTTP404Response(urlSchemeTask, url: url)
            return
        }

        guard let dataStream = await dataStream(for: url, metaData: metaData) else {
            sendHTTP404Response(urlSchemeTask, url: url)
            return
        }
        
        // send the headers
        guard isStartedFor(urlSchemeTask.hash) else { return }
        guard let responseHeaders = http200Response(urlSchemeTask, url: url, metaData: metaData) else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
            stopFor(urlSchemeTask.hash)
            return
        }
        urlSchemeTask.didReceive(responseHeaders)

        // send the data
        do {
            try await writeContent(to: urlSchemeTask, from: dataStream)
            guard isStartedFor(urlSchemeTask.hash) else { return }
            urlSchemeTask.didFinish()
        } catch {
            guard isStartedFor(urlSchemeTask.hash) else { return }
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
        stopFor(urlSchemeTask.hash)
    }

    // MARK: Reading content

    private func dataStream(for url: URL, metaData: URLContentMetaData) async -> DataStream<URLContent>? {
        let dataProvider: any DataProvider<URLContent>
        let ranges: [ClosedRange<UInt>] // the list of ranges we should use to stream data
        let size2MB: UInt = 2097152 // 2MB
        if metaData.isMediaType, let directAccess = await directAccessInfo(for: url) {
            dataProvider = ZimDirectContentProvider(directAccess: directAccess,
                                                    contentSize: metaData.size)
            ranges = ByteRanges.rangesFor(
                contentLength: metaData.size,
                rangeSize: size2MB
            )
        } else {
            dataProvider = ZimContentProvider(for: url)
            // if the data is larger than 2MB, read it "in chunks"
            if metaData.size > size2MB {
                ranges = ByteRanges.rangesFor(
                    contentLength: metaData.size,
                    rangeSize: size2MB
                )
            } else { // use the full range and read it in one go
                ranges = [0...metaData.size]
            }
        }
        return DataStream(dataProvider: dataProvider, ranges: ranges)
    }

    private func contentMetaData(for url: URL) async -> URLContentMetaData? {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .utility) {
                let metaData = ZimFileService.shared.getContentMetaData(url: url)
                continuation.resume(returning: metaData)
            }
        }
    }

    private func directAccessInfo(for url: URL) async -> DirectAccessInfo? {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .utility) {
                let directAccess = ZimFileService.shared.getDirectAccessInfo(url: url)
                continuation.resume(returning: directAccess)
            }
        }
    }

    // MARK: Writing content
    private func writeContent(
        to urlSchemeTask: WKURLSchemeTask,
        from dataStream: DataStream<URLContent>
    ) async throws {
        for try await urlContent in dataStream {
            await MainActor.run {
                guard isStartedFor(urlSchemeTask.hash) else { return }
                urlSchemeTask.didReceive(urlContent.data)
            }
        }
    }

    // MARK: Success responses
    private func http200Response(
        _ urlSchemeTask: WKURLSchemeTask,
        url: URL,
        metaData: URLContentMetaData
    ) -> HTTPURLResponse? {
        let headers = ["Content-Type": metaData.httpContentType,
                       "Content-Length": "\(metaData.size)"]
        return HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )
    }

    // MARK: Error responses

    @MainActor
    private func sendHTTP404Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        guard isStartedFor(urlSchemeTask.hash) else { return }
        if let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
        stopFor(urlSchemeTask.hash)
    }
}
