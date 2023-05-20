//
//  KiwixURLSchemeHandler.swift
//  Kiwix
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import os
import WebKit

class KiwixURLSchemeHandler: NSObject, WKURLSchemeHandler {
    private var urls = Set<URL>()
    private var queue = DispatchQueue(label: "org.kiwix.webContent", qos: .userInitiated)
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = urlSchemeTask.request.url, url.isKiwixURL else {
                urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
                return
            }
            
            objCTryBlock {
                if let range = urlSchemeTask.request.allHTTPHeaderFields?["Range"] as? String {
                    let parts = range.components(separatedBy: ["=", "-"])
                    guard parts.count >= 2, let start = UInt(parts[1]) else {
                        self.sendHTTP400Response(urlSchemeTask, url: url)
                        return
                    }
                    let end = parts.count == 3 ? UInt(parts[2]) ?? 0 : 0
                    guard let content = ZimFileService.shared.getURLContent(
                        url: url, start: start, end: end
                    ) else {
                        self.sendHTTP404Response(urlSchemeTask, url: url)
                        return
                    }
                    self.sendHTTP206Response(urlSchemeTask, url: url, content: content)
                } else {
                    guard let content = ZimFileService.shared.getURLContent(url: url) else {
                        self.sendHTTP404Response(urlSchemeTask, url: url)
                        return
                    }
                    self.sendHTTP200Response(urlSchemeTask, url: url, content: content)
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) { }
    
    private func sendHTTP200Response(_ urlSchemeTask: WKURLSchemeTask, url: URL, content: URLContent) {
        let headers = ["Content-Type": content.mime, "Content-Length": "\(content.size)"]
        if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
    
    private func sendHTTP206Response(_ urlSchemeTask: WKURLSchemeTask, url: URL, content: URLContent) {
        let headers = [
            "Content-Type": content.mime,
            "Content-Length": "\(content.data.count)",
            "Content-Range": "bytes \(content.start)-\(content.end)/\(content.size)"
        ]
        if let response = HTTPURLResponse(url: url, statusCode: 206, httpVersion: "HTTP/1.1", headerFields: headers) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(content.data)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
    
    private func sendHTTP400Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        os_log(
            "Resource not found for url: %s.",
            log: Log.URLSchemeHandler,
            type: .info,
            url.absoluteString
        )
        if let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
    
    private func sendHTTP404Response(_ urlSchemeTask: WKURLSchemeTask, url: URL) {
        if let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil) {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didFinish()
        } else {
            urlSchemeTask.didFailWithError(URLError(.badServerResponse, userInfo: ["url": url]))
        }
    }
}
