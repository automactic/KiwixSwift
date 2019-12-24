//
//  SearchResultControllerNew.swift
//  iOS
//
//  Created by Chris Li on 4/18/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class SearchResultsController: UIViewController, SearchQueueEvents, UISearchResultsUpdating {
    private let queue = SearchQueue()
    private let visualView = VisualEffectShadowView()
    let contentController = SearchResultContents()
    private var viewAlwaysVisibleObserver: NSKeyValueObservation?
    
    // MARK: - Constraints
    
    var readableContentWidthConstraint: NSLayoutConstraint? = nil
    var equalWidthConstraint: NSLayoutConstraint? = nil
    var proportionalHeightConstraint: NSLayoutConstraint? = nil
    var bottomConstraint: NSLayoutConstraint? = nil
    
    // MARK: - Database
    
    private let localZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    private let localIncludedInSearchZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@ AND includeInSearch == true", ZimFile.State.local.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    // MARK: - Overrides
    
    override func loadView() {
        view = BackgroundView()
        
        if #available(iOS 13, *) {} else {
            /* Prevent SearchResultsController view from being automatically hidden by the UISearchController */
            viewAlwaysVisibleObserver = view.observe(\.isHidden, options: .new, changeHandler: { (view, change) in
                if change.newValue == true { view.isHidden = false }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = []
        configureChildViewControllers()
        configureConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        queue.eventDelegate = self
        configureVisualView()
        configureContent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        queue.eventDelegate = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        configureVisualView()
        updateConstraintPriorities()
    }
    
    // MARK: - Keyboard Events
    
    @objc func keyboardDidShow(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: NSValue],
            let origin = userInfo[UIResponder.keyboardFrameEndUserInfoKey]?.cgRectValue.origin else {return}
        let point = visualView.contentView.convert(origin, from: nil)
        visualView.bottomInset = visualView.contentView.bounds.height - point.y
        if contentController.view.isHidden { contentController.view.isHidden = false }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        visualView.bottomInset = 0
        if !contentController.mode.canScroll {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.contentController.view.isHidden = true
            }, completion: nil)
        }
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        contentController.view.isHidden = false
    }
    
    // MARK: - View Manipulation
    
    private func configureVisualView() {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            if #available(iOS 13.0, *) {
                visualView.contentView.backgroundColor = .systemBackground
            } else {
                visualView.contentView.backgroundColor = .white
            }
            visualView.roundingCorners = nil
        case .regular:
            visualView.contentView.backgroundColor = .clear
            visualView.roundingCorners = .allCorners
        default:
            break
        }
    }
    
    private func configureChildViewControllers() {
        guard !children.contains(contentController) else {return}
        addChild(contentController)
        contentController.didMove(toParent: self)
    }
    
    private func configureConstraints() {
        guard !view.subviews.contains(visualView) else {return}
        view.subviews.forEach({ $0.removeFromSuperview() })
        
        visualView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualView)
        contentController.view.translatesAutoresizingMaskIntoConstraints = false
        visualView.setContent(view: contentController.view)
        
        visualView.contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        visualView.contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        readableContentWidthConstraint = visualView.contentView.widthAnchor.constraint(equalTo: view.readableContentGuide.widthAnchor, multiplier: 1.0, constant: 90)
        equalWidthConstraint = visualView.contentView.widthAnchor.constraint(equalTo: view.widthAnchor)
        proportionalHeightConstraint = visualView.contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75)
        bottomConstraint = visualView.contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        updateConstraintPriorities()
        
        readableContentWidthConstraint?.isActive = true
        equalWidthConstraint?.isActive = true
        proportionalHeightConstraint?.isActive = true
        bottomConstraint?.isActive = true
    }
    
    private func updateConstraintPriorities() {
        readableContentWidthConstraint?.priority = traitCollection.horizontalSizeClass == .regular ? .defaultHigh : .defaultLow
        equalWidthConstraint?.priority = traitCollection.horizontalSizeClass == .compact ? .defaultHigh : .defaultLow
        proportionalHeightConstraint?.priority = traitCollection.horizontalSizeClass == .regular ? .defaultHigh : .defaultLow
        bottomConstraint?.priority = traitCollection.horizontalSizeClass == .compact ? .defaultHigh : .defaultLow
    }
    
    private func configureContent(mode: SearchResultContents.Mode? = nil) {
        if let mode = mode {
            contentController.mode = mode
            /*
             If `tabController.view` has never been on screen,
             and its content is searching, noResult or onboarding,
             we need to hide `tabController.view` here and unhide it after we adjust `visualView.bottomInset` in `keyboardDidShow`,
             so that `tabController.view` does not visiually jump.
             */
            if viewIfLoaded?.window == nil && !mode.canScroll {
                contentController.view.isHidden = true
            }
        } else {
            if queue.operationCount > 0 {
                // search is in progress
                configureContent(mode: .inProgress)
            } else if contentController.resultsListController.searchText == "" {
                if let localZimFileCount = localZimFiles?.count, localZimFileCount > 0 {
                    configureContent(mode: .noText)
                } else {
                    configureContent(mode: .onboarding)
                }
            } else {
                if contentController.resultsListController.results.count > 0 {
                    configureContent(mode: .results)
                } else {
                    configureContent(mode: .noResult)
                }
            }
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {return}
        
        /* UISearchController will update results using empty string when it is being dismissed.
         We choose not to do so in order to preserve user's previous search text. */
        if searchController.isBeingDismissed && searchText == "" {return}
        
        /* If UISearchController is not being dismissed and the search text is set to empty string,
         that means user is trying to clear the search field. We immediately cancel all search tasks
         and change content back to no text mode. */
        if !searchController.isBeingDismissed && searchText == "" {
            queue.cancelAllOperations()
            configureContent(mode: .noText)
            contentController.resultsListController.update(searchText: "", results: [])
            return
        }
        
        /* If there is no search operation in queue (no pending result updates which makes current cached result up to date)
         and search text is the same as search text of cached result, we don't have to redo the search. */
        if queue.operationCount == 0 && searchText == contentController.resultsListController.searchText {return}

        /* Perform the search! */
        let zimFileIDs: Set<String> = {
            guard let result = localIncludedInSearchZimFiles else { return Set() }
            return Set(result.map({ $0.id }))
        }()
        queue.enqueue(searchText: searchText, zimFileIDs: zimFileIDs)
    }

    // MARK: - SearchQueueEvents
    
    func searchStarted() {
        configureContent(mode: .inProgress)
    }
    
    func searchFinished(searchText: String, results: [SearchResult]) {
        contentController.resultsListController.update(searchText: searchText, results: results)
        configureContent()
    }
    
    // MARK: - Type Definition
    
    private class BackgroundView: UIView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let view = super.hitTest(point, with: event)
            return view === self ? nil : view
        }
    }
}
