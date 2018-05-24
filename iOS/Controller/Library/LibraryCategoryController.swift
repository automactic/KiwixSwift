//
//  LibraryCategoryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyUserDefaults

class LibraryCategoryController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView()
    private let category: ZimFile.Category
    
    private var languageCodes = [String]()
    private let zimFiles: Results<ZimFile>?
    private var changeToken: NotificationToken?
    
    // MARK: - Override
    
    init(category: ZimFile.Category) {
        self.category = category
        
        let database = try? Realm(configuration: Realm.defaultConfig)
        self.zimFiles = database?.objects(ZimFile.self).filter("categoryRaw = %@", category.rawValue)
        
        super.init(nibName: nil, bundle: nil)
        title = category.description
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: tableView.separatorInset.left + 42, bottom: 0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Globe"), style: .plain, target: self, action: #selector(languageFilterBottonTapped(sender:)))
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        configureLanguageCodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureChangeToken()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
        if !Defaults[.libraryHasShownLanguageFilterAlert] {
            showAdditionalLanguageAlert()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        changeToken = nil
    }
    
    // MARK: -
    
    private func configureLanguageCodes() {
        let visibleLanguageCodes = Defaults[.libraryFilterLanguageCodes]
        languageCodes = zimFiles?.distinct(by: ["languageCode"]).map({ $0.languageCode }) ?? []
        if visibleLanguageCodes.count > 0 {languageCodes = languageCodes.filter({ visibleLanguageCodes.contains($0) })}
        languageCodes = languageCodes.filter({ (self.zimFiles?.filter("languageCode == %@", $0).count ?? 0) > 0 })
            .sorted(by: { (code0, code1) -> Bool in
                guard let name0 = Locale.current.localizedString(forLanguageCode: code0),
                    let name1 = Locale.current.localizedString(forLanguageCode: code1) else {return code0 < code1}
                return name0 < name1
            })
    }
    
    private func configureChangeToken() {
        changeToken = zimFiles?.observe({ (changes) in
            switch changes {
            case .initial, .update:
                self.tableView.reloadData()
            default:
                break
            }
        })        
    }
    
    private func showAdditionalLanguageAlert() {
        let alert = UIAlertController(title: NSLocalizedString("More Languages", comment: "Library: Additional Language Alert"),
                                      message: NSLocalizedString("Contents in other languages are also available. Visit language filter at the top of the screen to enable them.",
                                                                 comment: "Library: Additional Language Alert"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        Defaults[.libraryHasShownLanguageFilterAlert] = true
    }
    
    @objc func languageFilterBottonTapped(sender: UIBarButtonItem) {
        let controller = LibraryLanguageController()
        controller.dismissCallback = {[unowned self] in
            self.configureLanguageCodes()
            self.configureChangeToken()
        }
        changeToken = nil
        
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.barButtonItem = sender
        present(navigation, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource & Delagates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return languageCodes.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let zimFiles = zimFiles?.filter("languageCode == %@", languageCodes[section]) else {return 0}
        return zimFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        configure(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func configure(cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
        guard let zimFiles = zimFiles?.filter("languageCode == %@", languageCodes[indexPath.section]).sorted(byKeyPath: "title", ascending: true) else {return}
        let zimFile = zimFiles[indexPath.row]
        cell.titleLabel.text = zimFile.title
        cell.detailLabel.text = [zimFile.fileSizeDescription, zimFile.creationDateDescription, zimFile.articleCountDescription].joined(separator: ", ")
        cell.thumbImageView.image = UIImage(data: zimFile.icon) ?? #imageLiteral(resourceName: "GenericZimFile")
        cell.thumbImageView.contentMode = .scaleAspectFit
        cell.accessoryType = .disclosureIndicator
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Locale.current.localizedString(forLanguageCode: languageCodes[section])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let zimFiles = zimFiles?.filter("languageCode == %@", languageCodes[indexPath.section]).sorted(byKeyPath: "title", ascending: true) else {return}
        let zimFile = zimFiles[indexPath.row]
        let controller = LibraryZimFileDetailController(zimFile: zimFile)
        navigationController?.pushViewController(controller, animated: true)
    }
}

