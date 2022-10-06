//
//  LibraryOperations.swift
//  Kiwix
//
//  Created by Chris Li on 9/12/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif
import CoreData
import os

import Defaults

struct LibraryOperations {
    private init() {}
    
    static let backgroundTaskIdentifier = "org.kiwix.library_refresh"
    
    // MARK: - Open
    
    /// Open a zim file with url
    /// - Parameter url: url of the zim file
    static func open(url: URL) {
        guard let metadata = ZimFileService.getMetaData(url: url),
              let fileURLBookmark = ZimFileService.getBookmarkData(url: url) else { return }
        // open the file
        do {
            try ZimFileService.shared.open(bookmark: fileURLBookmark)
        } catch {
            return
        }
        
        // upsert zim file in the database
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let predicate = NSPredicate(format: "fileID == %@", metadata.fileID as CVarArg)
            let fetchRequest = ZimFile.fetchRequest(predicate: predicate)
            guard let zimFile = try? context.fetch(fetchRequest).first ?? ZimFile(context: context) else { return }
            LibraryOperations.configureZimFile(zimFile, metadata: metadata)
            zimFile.fileURLBookmark = fileURLBookmark
            zimFile.isMissing = false
            if context.hasChanges { try? context.save() }
        }
    }
    
    /// Reopen zim files from url bookmark data.
    static func reopen() {
        var successCount = 0
        let context = Database.shared.container.viewContext
        let request = ZimFile.fetchRequest(predicate: ZimFile.withFileURLBookmarkPredicate)
        
        guard let zimFiles = try? context.fetch(request) else { return }
        zimFiles.forEach { zimFile in
            guard let data = zimFile.fileURLBookmark else { return }
            do {
                if let data = try ZimFileService.shared.open(bookmark: data) {
                    zimFile.fileURLBookmark = data
                }
                zimFile.isMissing = false
                successCount += 1
            } catch ZimFileOpenError.missing {
                zimFile.isMissing = true
            } catch {
                zimFile.fileURLBookmark = nil
                zimFile.isMissing = false
            }
        }
        if context.hasChanges {
            try? context.save()
        }
        
        os_log("Reopened %d out of %d zim files", log: Log.LibraryOperations, type: .info, successCount, zimFiles.count)
    }
    
    /// Scan a directory and open available zim files inside it
    /// - Parameter url: directory to scan
    static func scanDirectory(_ url: URL) {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        ).filter({ $0.pathExtension == "zim"}) else { return }
        os_log("Discovered %d probable zim files.", log: Log.LibraryOperations, type: .info, fileURLs.count)
        for fileURL in fileURLs {
            LibraryOperations.open(url: fileURL)
        }
    }
    
    // MARK: - Configure
    
    /// Configure a zim file object based on its metadata.
    static func configureZimFile(_ zimFile: ZimFile, metadata: ZimFileMetaData) {
        zimFile.articleCount = metadata.articleCount.int64Value
        zimFile.category = metadata.category
        zimFile.created = metadata.creationDate
        zimFile.fileDescription = metadata.fileDescription
        zimFile.fileID = metadata.fileID
        zimFile.flavor = metadata.flavor
        zimFile.hasDetails = metadata.hasDetails
        zimFile.hasPictures = metadata.hasPictures
        zimFile.hasVideos = metadata.hasVideos
        zimFile.languageCode = metadata.languageCode
        zimFile.mediaCount = metadata.mediaCount.int64Value
        zimFile.name = metadata.title
        zimFile.persistentID = metadata.groupIdentifier
        zimFile.requiresServiceWorkers = metadata.requiresServiceWorkers
        zimFile.size = metadata.size.int64Value
        
        // Only overwrite favicon data and url if there is a new value
        if let url = metadata.downloadURL { zimFile.downloadURL = url }
        if let url = metadata.faviconURL { zimFile.faviconURL = url }
    }
    
    //MARK: - Deletion
    
    /// Unlink a zim file from library, and delete the file.
    /// - Parameter zimFile: the zim file to delete
    static func delete(zimFileID: UUID) {
        LibraryOperations.unlink(zimFileID: zimFileID)
    }
    
    /// Unlink a zim file from library, but don't delete the file.
    /// - Parameter zimFile: the zim file to unlink
    static func unlink(zimFileID: UUID) {
        ZimFileService.shared.close(fileID: zimFileID)
        
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            guard let zimFile = try? ZimFile.fetchRequest(fileID: zimFileID).execute().first else { return }
            if zimFile.downloadURL == nil {
                context.delete(zimFile)
            } else {
                zimFile.fileURLBookmark = nil
                zimFile.isMissing = false
            }
            if context.hasChanges { try? context.save() }
        }
    }
    
    // MARK: - Backup
    
    /// Apply iCloud backup setting on zim files in document directory.
    /// - Parameter isEnabled: if file should be included in backup
    static func applyFileBackupSetting(isEnabled: Bool? = nil) {
        do {
            let directory = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
            )
            let urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isExcludedFromBackupKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
            ).filter({ $0.pathExtension.contains("zim") })
            let backupDocumentDirectory = isEnabled ?? Defaults[.backupDocumentDirectory]
            try urls.forEach { url in
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = !backupDocumentDirectory
                var url = url
                try url.setResourceValues(resourceValues)
            }
            os_log(
                "Applying zim file backup setting (%s) on %u zim file(s).",
                log: Log.LibraryOperations,
                type: .info,
                backupDocumentDirectory ? "backing up" : "not backing up",
                urls.count
            )
        } catch {}
    }
    
#if os(iOS)
    // MARK: - Background Refresh

    /// Apply library background refresh setting.
    /// - Parameter isEnabled: if library should be refreshed on background
    static func applyLibraryAutoRefreshSetting(isEnabled: Bool? = nil) {
        if isEnabled ?? Defaults[.libraryAutoRefresh] {
            let request = BGAppRefreshTaskRequest(identifier: LibraryOperations.backgroundTaskIdentifier)
            if let lastRefreshData = Defaults[.libraryLastRefresh] {
                request.earliestBeginDate = Date(timeInterval: 3600 * 24, since: lastRefreshData)
            }
            try? BGTaskScheduler.shared.submit(request)
            os_log("Enabling background library refresh.", log: Log.LibraryOperations, type: .info)
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: LibraryOperations.backgroundTaskIdentifier)
            os_log("Disabling background library refresh.", log: Log.LibraryOperations, type: .info)
        }
    }
    
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: LibraryOperations.backgroundTaskIdentifier, using: nil
        ) { task in
            let operation = LibraryRefreshOperation()
            operation.completionBlock = {
                task.setTaskCompleted(success: true)
            }
            OperationQueue().addOperation(operation)
        }
    }
#endif
}
