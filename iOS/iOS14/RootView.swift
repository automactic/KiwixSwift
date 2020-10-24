//
//  RootView.swift
//  Kiwix
//
//  Created by Chris Li on 10/18/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
enum ContentDisplayMode {
    case home, web
}

@available(iOS 14.0, *)
enum SidebarDisplayMode {
    case hidden, bookmark, recent
}

@available(iOS 14.0, *)
struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var webViewStates: WebViewStates
    @State private var sidebarDisplayMode = SidebarDisplayMode.hidden
    @State private var showSidebar = false
    @State private var showHomeView = true
    
    private let sidebarAnimation = Animation.easeOut(duration: 0.2)
    private let sidebarWidth: CGFloat = 320.0
    
    private let homeView = HomeView()
    private let webView = WebView()
    
    var content: some View {
        ZStack {
            if showHomeView {
                homeView
            } else {
                webView
            }
            if horizontalSizeClass == .regular {
                Color(UIColor.black)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(colorScheme == .dark ? 0.3 : 0.1)
                    .opacity(showSidebar ? 1.0 : 0.0)
                    .onTapGesture { hideSideBar() }
                HStack {
                    ZStack(alignment: .trailing) {
                        SidebarView()
                        Divider()
                    }
                    .frame(width: sidebarWidth)
                    .offset(x: showSidebar ? 0 : -sidebarWidth)
                    Spacer()
                }
            }
        }
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            content.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        SwiftUIBarButton(iconName: "chevron.left", action: chevronLeftButtonTapped)
                        SwiftUIBarButton(iconName: "chevron.right", action: chevronRightButtonTapped)
                        SwiftUIBarButton(iconName: "bookmark") { showSidebar ? hideSideBar() : showBookmark() }
                        SwiftUIBarButton(iconName: "clock.arrow.circlepath") { showSidebar ? hideSideBar() : showRecent() }
                    }.padding(.trailing, 20)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        SwiftUIBarButton(iconName: "die.face.5")
                        SwiftUIBarButton(iconName: "list.bullet")
                        SwiftUIBarButton(iconName: "map")
                        SwiftUIBarButton(iconName: "house", isPushed: self.showHomeView, action: houseButtonTapped)
                    }.padding(.leading, 20)
                }
            }
        } else if horizontalSizeClass == .compact {
            content.toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    SwiftUIBarButton(iconName: "chevron.left", action: chevronLeftButtonTapped)
                    Spacer()
                    SwiftUIBarButton(iconName: "chevron.right", action: chevronRightButtonTapped)
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
                ToolbarItemGroup(placement: .bottomBar) {
                    SwiftUIBarButton(iconName: "bookmark") { showBookmark() }
                    Spacer()
                    SwiftUIBarButton(iconName: "list.bullet")
                    Spacer()
                    SwiftUIBarButton(iconName: "die.face.5")
                }
                ToolbarItem(placement: .bottomBar) { Spacer() }
                ToolbarItem(placement: .bottomBar) {
                    ZStack {
                        Spacer()
                        SwiftUIBarButton(iconName: "house", isPushed: self.showHomeView, action: houseButtonTapped)
                    }
                }
            }
        }
    }
    
    private func chevronLeftButtonTapped() {
        
    }
    
    private func chevronRightButtonTapped() {
        
    }
    
    private func houseButtonTapped() {
        withAnimation {
            self.showHomeView.toggle()
        }
    }
    
    private func showBookmark() {
        if horizontalSizeClass == .regular {
            withAnimation(sidebarAnimation) { showSidebar = true }
        }
    }
    
    private func showRecent() {
        if horizontalSizeClass == .regular {
            withAnimation(sidebarAnimation) { showSidebar = true }
        }
    }
    
    private func hideSideBar() {
        withAnimation(sidebarAnimation) { showSidebar = false }
    }
}

@available(iOS 14.0, *)
struct SwiftUIBarButton: View {
    let iconName: String
    @State var isPushed: Bool = false
    var action: (() -> Void)?
    
    var image: some View {
        Image(systemName: iconName)
            .font(Font.body.weight(.regular))
            .imageScale(.large)
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            ZStack(alignment: .center) {
                if isPushed {
                    Color(.systemBlue).cornerRadius(6)
                    image.foregroundColor(Color(.systemBackground))
                } else {
                    image
                }
            }.frame(width: 32, height: 32)
        }
    }
}

@available(iOS 14.0, *)
class RootController_iOS14: UIHostingController<AnyView>, UISearchControllerDelegate {
    private let searchController: UISearchController
    private let searchResultsController: SearchResultsController
    private let webViewStates = WebViewStates()

    init() {
        self.searchResultsController = SearchResultsController()
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)

        super.init(rootView: AnyView(RootView().environmentObject(webViewStates)))

        // search controller
        searchController.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = searchResultsController
        searchController.automaticallyShowsCancelButton = false
        searchController.showsSearchResultsController = true

        // misc
        definesPresentationContext = true
        navigationItem.hidesBackButton = true
        navigationItem.titleView = searchController.searchBar
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

