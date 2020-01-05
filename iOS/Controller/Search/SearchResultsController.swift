//
//  SearchResultControllerNew.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 4/18/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class SearchResultsController: UIViewController, UISearchResultsUpdating {
    private var mode: Mode = .filter { didSet { configureStackView() } }
    private let queue = SearchQueue()
    private var viewAlwaysVisibleObserver: NSKeyValueObservation?
    
    private let stackView = UIStackView()
    private let informationView = InfoStackView()
    private let dividerView = DividerView()
    private let filterController = SearchFilterController()
    private let resultsListController = SearchResultsListController()
    
    private var filterControllerWidthConstraint: NSLayoutConstraint?
    private var filterControllerProportionalWidthConstraint: NSLayoutConstraint?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        stackView.axis = .horizontal
        stackView.alignment = .fill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides

    override func loadView() {
        view = UIView()
        view.backgroundColor = .groupTableViewBackground

        if #available(iOS 13, *) {} else {
            /* Prevent SearchResultsController view from being automatically hidden by UISearchController */
            viewAlwaysVisibleObserver = view.observe(\.isHidden, options: .new, changeHandler: { (view, change) in
                if change.newValue == true { view.isHidden = false }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // filter controller width constraints for horizontal regular
        filterControllerWidthConstraint = filterController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 320)
        filterControllerProportionalWidthConstraint = filterController.view.widthAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.3)
        filterControllerProportionalWidthConstraint?.priority = .init(rawValue: 749)
        
        // stack view layout
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
        
        // add child controllers
        addChild(filterController)
        addChild(resultsListController)
        filterController.didMove(toParent: self)
        resultsListController.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        informationView.alpha = 0.0
        configureStackView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        informationView.alpha = 0.0
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection != previousTraitCollection else {return}
        configureStackView()
    }
    
    // MARK: View configuration
    
    private func configureStackView() {
        stackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        if traitCollection.horizontalSizeClass == .regular {
            stackView.addArrangedSubview(filterController.view)
            stackView.addArrangedSubview(dividerView)
            filterControllerWidthConstraint?.isActive = true
            filterControllerProportionalWidthConstraint?.isActive = true
        } else if traitCollection.horizontalSizeClass == .compact {
            filterControllerWidthConstraint?.isActive = false
            filterControllerProportionalWidthConstraint?.isActive = false
        }
        
        informationView.configure(mode: mode)
        switch mode {
        case .filter:
            if traitCollection.horizontalSizeClass == .regular {
                stackView.addArrangedSubview(informationView)
            } else if traitCollection.horizontalSizeClass == .compact {
                stackView.addArrangedSubview(filterController.view)
            }
        case .results:
            stackView.addArrangedSubview(resultsListController.view)
        case .inProgress, .noResults:
            stackView.addArrangedSubview(informationView)
        }
    }
    
    // MARK: Keyboard Events
    
    private func updateAdditionalSafeAreaInsets(notification: Notification, animated: Bool) {
        guard let userInfo = notification.userInfo,
            let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {return}
        let keyboardEndFrameInView = view.convert(keyboardEndFrame, from: nil)
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
        let intersection = safeAreaFrame.intersection(keyboardEndFrameInView)
        
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
        let options = UIView.AnimationOptions(rawValue: animationCurveRawValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue)
        let updates = {
            self.additionalSafeAreaInsets.bottom = intersection.height
            self.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: duration, delay: 0.0, options: options,
                           animations: updates, completion: nil)
        } else {
            updates()
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        updateAdditionalSafeAreaInsets(notification: notification, animated: true)
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        updateAdditionalSafeAreaInsets(notification: notification, animated: false)
        if informationView.alpha == 0.0 { informationView.alpha = 1.0 }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        updateAdditionalSafeAreaInsets(notification: notification, animated: true)
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {return}
        
        queue.cancelAllOperations()
        if searchText.count == 0 {
            mode = .filter
        } else {
            if mode == .results, searchText == resultsListController.searchText {
                return
            }
            informationView.activityIndicator.startAnimating()
            mode = .inProgress
            
            let operation = SearchProcedure(term: searchText, ids: Set())
            operation.completionBlock = { [weak self] in
                guard !operation.isCancelled else {return}
                DispatchQueue.main.sync {
                    self?.resultsListController.update(searchText: searchText, results: operation.sortedResults)
                    self?.informationView.activityIndicator.stopAnimating()
                    self?.mode = operation.sortedResults.count > 0 ? .results : .noResults
                }
            }
            queue.addOperation(operation)
        }
    }
}

// MARK: - Class Definitions

fileprivate enum Mode {
    case filter, inProgress, noResults, results
}

fileprivate class InfoStackView: UIStackView {
    let activityIndicator = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        alignment = .center
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(mode: Mode) {
        arrangedSubviews.forEach({ $0.removeFromSuperview() })
        switch mode {
        case .filter:
            addArrangedSubview(TitleLabel("Start a search"))
        case .inProgress:
            activityIndicator.startAnimating()
            addArrangedSubview(activityIndicator)
        case .noResults:
            addArrangedSubview(TitleLabel("No Result"))
        default:
            break
        }
    }
    
    class TitleLabel: UILabel {
        convenience init(_ text: String) {
            self.init()
            self.text = text
        }
    }
}

fileprivate class DividerView: UIView {
    init() {
        super.init(frame: .zero)
        if #available(iOS 13.0, *) {
            backgroundColor = .separator
        } else {
            backgroundColor = .gray
        }
        widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
