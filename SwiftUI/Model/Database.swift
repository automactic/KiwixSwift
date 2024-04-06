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

import CoreData
import os

final class Database {
    static let shared = Database()
    private var notificationToken: NSObjectProtocol?
    private var token: NSPersistentHistoryToken?
    private var tokenURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("token.data")

    private init() {
        // due to objc++ interop, only the older notification value is working for downloads:
        // https://developer.apple.com/documentation/coredata/nspersistentstoreremotechangenotification?language=objc
        let storeChange: NSNotification.Name = .init(rawValue: "NSPersistentStoreRemoteChangeNotification")
        notificationToken = NotificationCenter.default.addObserver(
            forName: storeChange, object: nil, queue: nil) { _ in
            try? self.mergeChanges()
        }
        token = {
            guard let data = UserDefaults.standard.data(forKey: "PersistentHistoryToken") else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }()
    }

    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    static var viewContext: NSManagedObjectContext {
        Database.shared.container.viewContext
    }

    static func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        Database.shared.container.performBackgroundTask(block)
    }

    static func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async rethrows -> T {
        try await Database.shared.container.performBackgroundTask(block)
    }

    /// A persistent container to set up the Core Data stack.
    lazy var container: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "DataModel")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        if ProcessInfo.processInfo.arguments.contains("testing") {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()

    /// Save image data to zim files.
    func saveImageData(url: URL, completion: @escaping (Data) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, _ in
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let mimeType = response.mimeType,
                  mimeType.contains("image"),
                  let data = data else { return }
            let context = self.container.newBackgroundContext()
            context.perform {
                let predicate = NSPredicate(format: "faviconURL == %@", url as CVarArg)
                let request = ZimFile.fetchRequest(predicate: predicate)
                guard let zimFile = try? context.fetch(request).first else { return }
                zimFile.faviconData = data
                try? context.save()
            }
            completion(data)
        }.resume()
    }

    /// Merge changes performed on batch requests to view context.
    private func mergeChanges() throws {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        context.perform {
            // fetch and merge changes
            let fetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.token)
            guard let result = try? context.execute(fetchRequest) as? NSPersistentHistoryResult else {
                os_log("no persistent history found after token: \(self.token)")
                self.token = nil
                return
            }
            guard let transactions = result.result as? [NSPersistentHistoryTransaction] else {
                os_log("no transactions in persistent history found after token: \(self.token)")
                self.token = nil
                return
            }
            self.container.viewContext.performAndWait {
                transactions.forEach { transaction in
                    self.container.viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                    self.token = transaction.token
                }
            }

            // update token
            guard let token = transactions.last?.token else { return }
            let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: "PersistentHistoryToken")

            // purge history
            let sevenDaysAgo = Date(timeIntervalSinceNow: -3600 * 24 * 7)
            let purgeRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)
            _ = try? context.execute(purgeRequest)
        }
    }
}
