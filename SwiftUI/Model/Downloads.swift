//
//  Downloads.swift
//  Kiwix
//
//  Created by Chris Li on 4/30/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import os

class Downloads: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let shared = Downloads()
    
    private let queue = DispatchQueue(label: "downloads")
    private var totalBytesWritten = [UUID: Int64]()
    private var heartbeat: Timer?
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.background")
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        return URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
    }()
    
    // MARK: - Init & Heartbeat
    
    private override init() {
        super.init()
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            guard downloadTasks.count > 0 else { return }
            for task in downloadTasks {
                guard let taskDescription = task.taskDescription,
                      let zimFileID = UUID(uuidString: taskDescription) else {return}
                self.totalBytesWritten[zimFileID] = task.countOfBytesReceived
            }
            self.startHeartbeat()
        }
    }
    
    /// Start heartbeat, which will update database every second
    private func startHeartbeat() {
        DispatchQueue.main.async {
            guard self.heartbeat == nil else { return }
            self.heartbeat = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Database.shared.container.performBackgroundTask { context in
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    for (zimFileID, downloadedBytes) in self.totalBytesWritten {
                        let predicate = NSPredicate(format: "fileID == %@", zimFileID as CVarArg)
                        let request = DownloadTask.fetchRequest(predicate: predicate)
                        guard let downloadTask = try? context.fetch(request).first else { return }
                        downloadTask.downloadedBytes = downloadedBytes
                    }
                    try? context.save()
                }
            }
            os_log("Heartbeat started.", log: Log.DownloadService, type: .info)
        }
    }
    
    /// Stop heartbeat, which stops periodical database update
    private func stopHeartbeat() {
        DispatchQueue.main.async {
            guard self.heartbeat != nil else { return }
            self.heartbeat?.invalidate()
            self.heartbeat = nil
            os_log("Heartbeat stopped.", log: Log.DownloadService, type: .info)
        }
    }
    
    // MARK: - Download Actions
    
    /// Start a zim file download task
    /// - Parameters:
    ///   - zimFile: the zim file to download
    ///   - allowsCellularAccess: if using cellular data is allowed
    func start(zimFileID: UUID, allowsCellularAccess: Bool) {
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let fetchRequest = ZimFile.fetchRequest(fileID: zimFileID)
            guard let zimFile = try? context.fetch(fetchRequest).first,
                  var url = zimFile.downloadURL else { return }
            let downloadTask = DownloadTask(context: context)
            downloadTask.created = Date()
            downloadTask.fileID = zimFileID
            downloadTask.totalBytes = zimFile.size
            downloadTask.zimFile = zimFile
            try? context.save()
            
            if url.lastPathComponent.hasSuffix(".meta4") {
                url = url.deletingPathExtension()
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.allowsCellularAccess = allowsCellularAccess
            let task = self.session.downloadTask(with: urlRequest)
            task.taskDescription = zimFileID.uuidString
            task.resume()
        }
        startHeartbeat()
    }
    
    /// Cancel a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func cancel(zimFileID: UUID) {
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            if let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first {
                task.cancel()
            }
            self.deleteDownloadTask(zimFileID: zimFileID)
        }
    }
    
    /// Pause a zim file download task
    /// - Parameter zimFileID: identifier of the zim file
    func pause(zimFileID: UUID) {
        session.getTasksWithCompletionHandler { _, _, downloadTasks in
            guard let task = downloadTasks.filter({ $0.taskDescription == zimFileID.uuidString }).first else { return }
            task.cancel { resumeData in
                Database.shared.container.performBackgroundTask { context in
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    let request = DownloadTask.fetchRequest(fileID: zimFileID)
                    guard let downloadTask = try? context.fetch(request).first else { return }
                    downloadTask.resumeData = resumeData
                    try? context.save()
                }
            }
        }
    }
    
    /// Resume a zim file download task and start heartbeat
    /// - Parameter zimFileID: identifier of the zim file
    func resume(zimFileID: UUID) {
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            guard let downloadTask = try? context.fetch(request).first,
                  let resumeData = downloadTask.resumeData else { return }
            
            let task = self.session.downloadTask(withResumeData: resumeData)
            task.taskDescription = zimFileID.uuidString
            task.resume()
            
            downloadTask.error = nil
            downloadTask.resumeData = nil
            try? context.save()
            
            self.startHeartbeat()
        }
    }
    
    // MARK: - Database
    
    private func deleteDownloadTask(zimFileID: UUID) {
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            do {
                let request = DownloadTask.fetchRequest(fileID: zimFileID)
                guard let downloadTask = try context.fetch(request).first else { return }
                context.delete(downloadTask)
                try context.save()
            } catch {
                os_log(
                    "Error deleting download task. Error: %s",
                    log: Log.DownloadService,
                    type: .error,
                    error.localizedDescription
                )
            }
        }
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskDescription = task.taskDescription,
              let zimFileID = UUID(uuidString: taskDescription) else { return }
        totalBytesWritten[zimFileID] = nil
        if totalBytesWritten.count == 0 {
            stopHeartbeat()
        }
        
        // download finished successfully if there's no error
        guard let error = error as NSError? else {
            self.deleteDownloadTask(zimFileID: zimFileID)
            os_log(
                "Download finished successfully. File ID: %s.",
                log: Log.DownloadService,
                type: .info,
                zimFileID.uuidString
            )
            return
        }
        
        // save the error description and resume data if possible
        guard error.code != URLError.cancelled.rawValue else { return }
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let request = DownloadTask.fetchRequest(fileID: zimFileID)
            guard let downloadTask = try? context.fetch(request).first else { return }
            downloadTask.error = error.localizedDescription
            if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                downloadTask.resumeData = resumeData
            }
            try? context.save()
        }
        os_log(
            "Download errored. File ID: %s. Error",
            log: Log.DownloadService,
            type: .error,
            zimFileID.uuidString,
            error.localizedDescription
        )
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let taskDescription = downloadTask.taskDescription,
              let zimFileID = UUID(uuidString: taskDescription) else { return }
        self.totalBytesWritten[zimFileID] = totalBytesWritten
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // determine which directory should the file be moved to
        #if os(macOS)
        let searchPath = FileManager.SearchPathDirectory.downloadsDirectory
        #elseif os(iOS)
        let searchPath = FileManager.SearchPathDirectory.documentDirectory
        #endif
        
        // move file
        guard let directory = FileManager.default.urls(for: searchPath, in: .userDomainMask).first,
            let zimFileID = downloadTask.taskDescription else {return}
        let fileName = downloadTask.response?.suggestedFilename
            ?? downloadTask.originalRequest?.url?.lastPathComponent
            ?? zimFileID + ".zim"
        let destination = directory.appendingPathComponent(fileName)
        try? FileManager.default.moveItem(at: location, to: destination)
        
        // open the file
        LibraryViewModel.open(url: destination)
    }
}
