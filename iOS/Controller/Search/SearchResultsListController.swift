//
//  SearchResultsListController.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyUserDefaults

class SearchResultsListController: UITableViewController {
    private(set) var searchText: String = ""
    private(set) var results: [SearchResult] = []
    private weak var clearResultTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .onDrag
    }
    
    func update(searchText: String, results: [SearchResult]) {
        self.searchText = searchText
        self.results = results
        tableView.reloadData()
    }
    
    func update(recentSearchText newSearchText: String) {
        var searchTexts = Defaults[.recentSearchTexts]
        if let index = searchTexts.index(of: newSearchText) {
            searchTexts.remove(at: index)
        }
        searchTexts.insert(newSearchText, at: 0)
        if searchTexts.count > 20 {
            searchTexts = Array(searchTexts[..<20])
        }
        Defaults[.recentSearchTexts] = searchTexts
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearResultTimer?.invalidate()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearResultTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { (_) in
            self.update(searchText: "", results: [])
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        let result = results[indexPath.row]
        
        cell.backgroundColor = .clear
        cell.titleLabel.text = result.title
        
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: result.zimFileID)
            cell.thumbImageView.image = UIImage(data: zimFile?.icon ?? Data()) ?? #imageLiteral(resourceName: "GenericZimFile")
            cell.thumbImageView.contentMode = .scaleAspectFit
        } catch {}
        
        if let snippet = result.snippet {
            cell.detailLabel.text = snippet
        } else if let attributedSnippet = result.attributedSnippet {
            cell.detailLabel.attributedText = attributedSnippet
        } else {
            cell.detailLabel.text = nil
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let main = presentingViewController as? MainController else {return}
        update(recentSearchText: searchText)
        main.load(url: results[indexPath.row].url)
        main.searchController.isActive = false
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if results[indexPath.row].snippet != nil || results[indexPath.row].attributedSnippet != nil {
            return traitCollection.horizontalSizeClass == .regular ? 120 : 190
        } else {
            return 44
        }
    }
}
