//
//  Entities.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Combine
import CoreData

class Bookmark: NSManagedObject, Identifiable {
    var id: URL { articleURL }
    
    @NSManaged var articleURL: URL
    @NSManaged var thumbImageURL: URL?
    @NSManaged var title: String
    @NSManaged var snippet: String?
    @NSManaged var created: Date
    
    @NSManaged var zimFile: ZimFile?
    
    class func fetchRequest(
        predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []
    ) -> NSFetchRequest<Bookmark> {
        let request = super.fetchRequest() as! NSFetchRequest<Bookmark>
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
}

class DownloadTask: NSManagedObject, Identifiable {
    var id: UUID { fileID }

    @NSManaged var created: Date
    @NSManaged var downloadedBytes: Int64
    @NSManaged var error: String?
    @NSManaged var fileID: UUID
    @NSManaged var resumeData: Data?
    @NSManaged var totalBytes: Int64
    
    @NSManaged var zimFile: ZimFile?
    
    class func fetchRequest(predicate: NSPredicate? = nil) -> NSFetchRequest<DownloadTask> {
        let request = super.fetchRequest() as! NSFetchRequest<DownloadTask>
        request.predicate = predicate
        return request
    }
    
    class func fetchRequest(fileID: UUID) -> NSFetchRequest<DownloadTask> {
        let request = super.fetchRequest() as! NSFetchRequest<DownloadTask>
        request.predicate = NSPredicate(format: "fileID == %@", fileID as CVarArg)
        return request
    }
}

struct Language: Identifiable, Comparable {
    var id: String { code }
    let code: String
    let name: String
    let count: Int
    
    init?(code: String, count: Int) {
        guard let name = Locale.current.localizedString(forLanguageCode: code) else { return nil }
        self.code = code
        self.name = name
        self.count = count
    }
    
    static func < (lhs: Language, rhs: Language) -> Bool {
        switch lhs.name.caseInsensitiveCompare(rhs.name) {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return lhs.count > rhs.count
        }
    }
}

class OutlineItem: ObservableObject, Identifiable {
    let id: String
    let index: Int
    let text: String
    let level: Int
    private(set) var children: [OutlineItem]?
    
    @Published var isExpanded = true
    
    init(id: String, index: Int, text: String, level: Int) {
        self.id = id
        self.index = index
        self.text = text
        self.level = level
    }
    
    convenience init(index: Int, text: String, level: Int) {
        self.init(id: String(index), index: index, text: text, level: level)
    }
    
    func addChild(_ item: OutlineItem) {
        if children != nil {
            children?.append(item)
        } else {
            children = [item]
        }
    }
    
    @discardableResult
    func removeAllChildren() -> [OutlineItem] {
        defer { children = nil }
        return children ?? []
    }
}

class Tab: NSManagedObject, Identifiable {
    @NSManaged var created: Date
    @NSManaged var interactionState: Data?
    @NSManaged var lastOpened: Date
    @NSManaged var title: String?
    
    @NSManaged var zimFile: ZimFile?
    
    class func fetchRequest(
        predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []
    ) -> NSFetchRequest<Tab> {
        let request = super.fetchRequest() as! NSFetchRequest<Tab>
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    class func fetchRequest(id: UUID) -> NSFetchRequest<Tab> {
        let request = super.fetchRequest() as! NSFetchRequest<Tab>
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return request
    }
}

struct URLContent {
    let data: Data
    let mime: String
    let start: UInt
    let end: UInt
    let size: UInt
}

class ZimFile: NSManagedObject, Identifiable {
    var id: UUID { fileID }
    
    @NSManaged var articleCount: Int64
    @NSManaged var category: String
    @NSManaged var created: Date
    @NSManaged var downloadURL: URL?
    @NSManaged var faviconData: Data?
    @NSManaged var faviconURL: URL?
    @NSManaged var fileDescription: String
    @NSManaged var fileID: UUID
    @NSManaged var fileURLBookmark: Data?
    @NSManaged var flavor: String?
    @NSManaged var hasDetails: Bool
    @NSManaged var hasPictures: Bool
    @NSManaged var hasVideos: Bool
    @NSManaged var includedInSearch: Bool
    @NSManaged var isMissing: Bool
    @NSManaged var languageCode: String
    @NSManaged var mediaCount: Int64
    @NSManaged var name: String
    @NSManaged var persistentID: String
    @NSManaged var requiresServiceWorkers: Bool
    @NSManaged var size: Int64
    
    @NSManaged var bookmarks: Set<Bookmark>
    @NSManaged var downloadTask: DownloadTask?
    @NSManaged var tabs: Set<Tab>
    
    static var openedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "fileURLBookmark != nil"),
        NSPredicate(format: "isMissing == false")
    ])
    static var withFileURLBookmarkPredicate = NSPredicate(format: "fileURLBookmark != nil")
    
    class func fetchRequest(
        predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []
    ) -> NSFetchRequest<ZimFile> {
        let request = super.fetchRequest() as! NSFetchRequest<ZimFile>
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    class func fetchRequest(fileID: UUID) -> NSFetchRequest<ZimFile> {
        let request = super.fetchRequest() as! NSFetchRequest<ZimFile>
        request.predicate = NSPredicate(format: "fileID == %@", fileID as CVarArg)
        return request
    }
}
