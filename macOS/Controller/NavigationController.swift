//
//  SearchController.swift
//  macOS
//
//  Created by Chris Li on 10/13/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import RealmSwift

class ArticleNavigationController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var localOutlineView: NSOutlineView!
    
    private var localZimFilesChangeToken: NotificationToken?
    
    // MARK: - Database
    
    private let localZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localZimFilesChangeToken = localZimFiles?.observe({ (change) in
            if case .update = change {
                self.localOutlineView.reloadData()
            }
        })
    }
    
    // MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? (localZimFiles?.count ?? 0) : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return localZimFiles?[index] ?? Object()
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    // MARK: - NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? ZimFile else {return nil}
        let identifier = NSUserInterfaceItemIdentifier("ZimFileCell")
        let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! ZimFileTableCellView
        view.titleTextField.stringValue = item.title
        view.subtitleTextField.stringValue = "\(item.creationDateDescription), \(item.fileSizeDescription)"
        view.imageView?.image = NSImage(data: item.icon)
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView,
            let windowController = view.window?.windowController as? WindowController else {return}
        guard let zimFile = outlineView.item(atRow: outlineView.selectedRow) as? ZimFile,
            let url = ZimMultiReader.shared.getMainPageURL(zimFileID: zimFile.id) else {return}
        windowController.contentTabController?.setMode(.reader)
        windowController.webViewController?.load(url: url)
    }
}

class ZimFileTableCellView: NSTableCellView {
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var subtitleTextField: NSTextField!
}
