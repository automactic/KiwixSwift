//
//  LibraryViewController.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
class LibraryViewController: UISplitViewController, UISplitViewControllerDelegate {
    let primaryController = UIHostingController(rootView: LibraryPrimaryView())
    
    let doneButton = UIBarButtonItem(systemItem: .done)
    let addButton = UIBarButtonItem(systemItem: .add)
    
    init() {
        super.init(nibName: nil, bundle: nil)
        delegate = self
        preferredDisplayMode = .allVisible
        presentsWithGesture = false
        
        doneButton.primaryAction = UIAction(handler: { [unowned self] _ in self.dismiss(animated: true) })
        addButton.primaryAction = UIAction(handler: { [unowned self] _ in self.add() })
        
        primaryController.navigationItem.title = "Library"
        primaryController.navigationItem.largeTitleDisplayMode = .always
        primaryController.navigationItem.leftBarButtonItem = doneButton
        primaryController.navigationItem.rightBarButtonItems = [addButton]
        primaryController.rootView.categorySelected = { [unowned self] category in self.showCategory(category) }
        let primaryNavigationController = UINavigationController(rootViewController: primaryController)
        primaryNavigationController.navigationBar.prefersLargeTitles = true
        viewControllers = [primaryNavigationController]

        showCategory(.wikipedia)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        true
    }
    
    private func add() {
        let controller = UIDocumentPickerViewController(documentTypes: ["org.openzim.zim"], in: .open)
//        controller.delegate = self
        present(controller, animated: true)
    }
    
    func showCategory(_ category: ZimFile.Category) {
        let languageFilterButtonItem = UIBarButtonItem(
            title: "Show Language Filter",
            image: UIImage(systemName: "globe"),
            primaryAction: UIAction(handler: { action in
                let controller = UIHostingController(rootView: LibraryLanguageFilterView())
                controller.rootView.doneButtonTapped = { [weak controller] in
                    controller?.dismiss(animated: true)
                }
                let navigation = UINavigationController(rootViewController: controller)
                navigation.modalPresentationStyle = .popover
                navigation.popoverPresentationController?.barButtonItem = action.sender as? UIBarButtonItem
                self.present(navigation, animated: true, completion: nil)
            })
        )
        let controller = UIHostingController(rootView: LibraryCategoryView(category: category))
        controller.title = category.description
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.navigationItem.rightBarButtonItem = languageFilterButtonItem
        controller.rootView.zimFileTapped = { [weak controller] fileID, title in
            let detailController = UIHostingController(rootView: ZimFileDetailView(fileID: fileID))
            detailController.title = title
            controller?.navigationController?.pushViewController(detailController, animated: true)
        }
        showDetailViewController(UINavigationController(rootViewController: controller), sender: nil)
    }
}
