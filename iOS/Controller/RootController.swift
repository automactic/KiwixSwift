//
//  RootController.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 11/24/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class RootController: UISplitViewController, UISplitViewControllerDelegate, UIGestureRecognizerDelegate,
                      OutlineControllerDelegate, WebViewControllerDelegate {
    
    // MARK: Controllers
    
    let sideBarController = UITabBarController()
    let favoriteController = BookmarkController()
    let outlineController = OutlineController()
    let contentController = ContentController()
    let webViewController = WebViewController()
    
    // MARK: Buttons
    
    let sideBarButton = BarButton(imageName: "sidebar.left")
    let chevronLeftButton = BarButton(imageName: "chevron.left")
    let chevronRightButton = BarButton(imageName: "chevron.right")
    let outlineButton = BarButton(imageName: "list.bullet")
    let settingButton = BarButton(imageName: "gear")
    
    // MARK: Other Properties
    
    private var sideBarDisplayModeObserver: DefaultsObservation?
    private var masterIsVisible: Bool {
        get {
            return displayMode == .allVisible || displayMode == .primaryOverlay
        }
    }
    
    // MARK: - Init & Override

    init() {
        super.init(nibName: nil, bundle: nil)

        sideBarController.viewControllers = [
            UINavigationController(rootViewController: favoriteController),
            UINavigationController(rootViewController: outlineController),
        ]
        viewControllers = [sideBarController, UINavigationController(rootViewController: contentController)]
        delegate = self
        if #available(iOS 13.0, *) {
            primaryBackgroundStyle = .sidebar
            preferredDisplayMode = .primaryHidden
        }

        webViewController.delegate = self
        favoriteController.delegate = contentController
        outlineController.delegate = self
        contentController.configureToolbar(isGrouped: !isCollapsed)
        
        sideBarButton.addTarget(self, action: #selector(toggleSideBar), for: .touchUpInside)
        chevronLeftButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        chevronRightButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        outlineButton.addTarget(self, action: #selector(openOutline), for: .touchUpInside)
        settingButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.gestureRecognizers?.first?.delegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            sideBarDisplayModeObserver = Defaults.observe(.sideBarDisplayMode) { change in
                guard self.masterIsVisible else { return }
                self.preferredDisplayMode = self.getPrimaryVisibleDisplayMode()
            }
        }
    }

    override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
        if viewControllers.count > 1,
            childViewController == viewControllers.last,
            displayMode == .allVisible {
            return UITraitCollection(horizontalSizeClass: .compact)
        } else {
            return super.overrideTraitCollection(forChild: childViewController)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        /*
         Hack: this function is called when user click the home button with wrong splitViewController.displayMode.
         To mitigate, check if the app is in background before do any UI adjustments.
         */
        guard UIApplication.shared.applicationState != .background else { return }
        if masterIsVisible && UIDevice.current.userInterfaceIdiom == .pad {
            preferredDisplayMode = getPrimaryVisibleDisplayMode(size: size)
        }
    }
    
    // MARK: - Utilities

    private func getPrimaryVisibleDisplayMode(size: CGSize? = nil) -> UISplitViewController.DisplayMode {
        switch Defaults[.sideBarDisplayMode] {
        case .automatic:
            let size = size ?? view.frame.size
            return size.width > size.height ? .allVisible : .primaryOverlay
        case .overlay:
            return .primaryOverlay
        case .sideBySide:
            return .allVisible
        }
    }

    // MARK: - UISplitViewControllerDelegate

    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return sideBarController
    }

    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        contentController.configureToolbar(isGrouped: false)
        contentController.dismissPopoverController()
        let navigationController = UINavigationController(rootViewController: contentController)
        navigationController.isToolbarHidden = contentController.searchController.isActive
        return navigationController
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        contentController.configureToolbar(isGrouped: true)
        contentController.dismissPopoverController()
        let navigationController = UINavigationController(rootViewController: contentController)
        navigationController.isToolbarHidden = contentController.searchController.isActive
        return navigationController
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // prevent the master controller from being displayed vie gesture when search is active
        guard !contentController.searchController.isActive else { return false }
        
        /*
         HACK: prevent UISplitViewController's build in gesture to work when the pan gesture's starting point
         is within 30 point of the left edge, so that the screen edge gesture in WKWebview can work.
        */
        return gestureRecognizer.location(in: view).x > 30
    }
    
    // MARK: - OutlineControllerDelegate
    
    func didTapOutlineItem(item: OutlineItem) {
        if contentController.searchController.isActive { contentController.searchController.isActive = false }
        webViewController.scrollToOutlineItem(index: item.index)
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewDidTapOnGeoLocation(controller: WebViewController, url: URL) {
        
    }
    
    func webViewDidFinishNavigation(controller: WebViewController) {
        
    }

    // MARK: - Actions
    
    @objc func toggleSideBar() {
        UIView.animate(withDuration: 0.2) {
            self.preferredDisplayMode = self.masterIsVisible ? .primaryHidden : self.getPrimaryVisibleDisplayMode()
        }
    }
    
    @objc func goBack() {
        webViewController.goBack()
    }
    
    @objc func goForward() {
        webViewController.goForward()
    }
    
    @objc func openOutline() {
        let outlineController = OutlineController()
        let navigationController = UINavigationController(rootViewController: outlineController)
        outlineController.delegate = self
        splitViewController?.present(navigationController, animated: true)
    }
    
    @objc func openSettings() {
        present(SettingNavigationController(), animated: true)
    }

    func openKiwixURL(_ url: URL) {
        guard url.isKiwixURL else {return}
        contentController.setChildControllerIfNeeded(webViewController)
        webViewController.load(url: url)
    }

    func openFileURL(_ url: URL, canOpenInPlace: Bool) {
        guard url.isFileURL else {return}
        dismiss(animated: false)
        if ZimMultiReader.getMetaData(url: url) != nil {
            let fileImportController = FileImportController(fileURL: url, canOpenInPlace: canOpenInPlace)
            present(fileImportController, animated: true)
        } else {
            present(FileImportAlertController(fileName: url.lastPathComponent), animated: true)
        }
    }

    func openShortcut(_ shortcut: Shortcut) {
        dismiss(animated: false)
        switch shortcut {
        case .search:
            contentController.searchController.isActive = true
        case .bookmark:
            contentController.openBookmark()
        }
    }
}

// MARK: - Buttons

private extension UIControl.State {
    static let bookmarked = UIControl.State(rawValue: 1 << 16)
}

private class ButtonGroupView: UIStackView {
    convenience init(buttons: [UIButton], spacing: CGFloat? = nil) {
        self.init(arrangedSubviews: buttons)
        distribution = .equalCentering
        if let spacing = spacing {
            self.spacing = spacing
        }
    }
}

class BarButton: UIButton {
    convenience init(imageName: String) {
        self.init(type: .system)
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(scale: .large)
            setImage(UIImage(systemName: imageName, withConfiguration: configuration), for: .normal)
        } else {
            setImage(UIImage(named: imageName), for: .normal)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 44)
    }
}

private class BookmarkButton: BarButton {
    var isBookmarked: Bool = false { didSet { setNeedsLayout() } }
    override var state: UIControl.State{ get { isBookmarked ? [.bookmarked, super.state] : super.state } }
    
    convenience init(imageName: String, bookmarkedImageName: String) {
        if #available(iOS 13.0, *) {
            self.init(imageName: imageName)
            let configuration = UIImage.SymbolConfiguration(scale: .large)
            let bookmarkedImage = UIImage(systemName: bookmarkedImageName, withConfiguration: configuration)?
                .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            setImage(bookmarkedImage, for: .bookmarked)
            setImage(bookmarkedImage, for: [.bookmarked, .highlighted])
        } else {
            self.init(type: .system)
            setImage(UIImage(named: imageName), for: .normal)
            let bookmarkedImage = UIImage(named: bookmarkedImageName)
            setImage(bookmarkedImage, for: .bookmarked)
            setImage(bookmarkedImage, for: [.bookmarked, .highlighted])
        }
    }
}
