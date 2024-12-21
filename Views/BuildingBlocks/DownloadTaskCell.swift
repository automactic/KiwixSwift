/*
65;6800;1c * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

import CoreData
import SwiftUI
import Combine
import ActivityKit

struct DownloadTaskCell: View {
    @State private var isHovering: Bool = false
    @State private var downloadState = DownloadState(downloaded: 0, total: 1, resumeData: nil)

    let downloadZimFile: ZimFile
    init(_ downloadZimFile: ZimFile) {
        self.downloadZimFile = downloadZimFile
    }

    var body: some View {
        let progress: Progress = {
            let prog = Progress(totalUnitCount: downloadState.total)
            prog.completedUnitCount = downloadState.downloaded
            prog.kind = .file
            prog.fileTotalCount = 1
            prog.fileOperationKind = .downloading
            return prog
        }()
        VStack(spacing: 8) {
            HStack {
                Text(downloadZimFile.name).fontWeight(.semibold).foregroundColor(.primary).lineLimit(1)
                Spacer()
                Favicon(
                    category: Category(rawValue: downloadZimFile.category) ?? .other,
                    imageData: downloadZimFile.faviconData,
                    imageURL: downloadZimFile.faviconURL
                ).frame(height: 20)
            }
            VStack(alignment: .leading, spacing: 4) {
                if downloadZimFile.downloadTask?.error != nil {
                    Text("download_task_cell.status.failed".localized)
                } else if downloadState.resumeData == nil {
                    Text("download_task_cell.status.downloading".localized)
                } else {
                    Text("download_task_cell.status.paused".localized)
                }
                ProgressView(
                    value: Float(downloadState.downloaded),
                    total: Float(downloadState.total)
                )
                Text(progress.localizedAdditionalDescription).animation(.none, value: progress)
            }.font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .modifier(CellBackground(isHovering: isHovering))
        .onHover { self.isHovering = $0 }
        .onReceive(DownloadService.shared.progress.publisher) { states in
            if let state = states[downloadZimFile.fileID] {
                self.downloadState = state
            }
        }
        .onAppear {
            // Start Live Activity
            let attributes = DownloadActivityAttributes(fileID: downloadZimFile.fileID, fileName: downloadZimFile.name)
            let initialContentState = DownloadActivityAttributes.ContentState(progress: 0.0, speed: 0.0)
            do {
                _ = try Activity<DownloadActivityAttributes>.request(
                    attributes: attributes,
                    contentState: initialContentState,
                    pushType: nil
                )
            } catch {
                print("Error starting Live Activity: \(error)")
            }
        }
    }
}

struct DownloadTaskCell_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 100
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.fileID = UUID()
        zimFile.flavor = "mini"
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        zimFile.downloadTask = downloadTask
        return zimFile
    }()
    static let downloadTask: DownloadTask = {
        let downloadTask = DownloadTask(context: context)
        downloadTask.zimFile = zimFile
        return downloadTask
    }()

    static var previews: some View {
        DownloadTaskCell(zimFile)
            .preferredColorScheme(.light)
            .padding()
            .frame(width: 300, height: 125)
            .previewLayout(.sizeThatFits)
        DownloadTaskCell(zimFile)
            .preferredColorScheme(.dark)
            .padding()
            .frame(width: 300, height: 125)
            .previewLayout(.sizeThatFits)
    }
}
