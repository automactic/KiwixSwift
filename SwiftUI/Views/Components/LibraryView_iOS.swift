//
//  LibraryView_iOS.swift
//  Kiwix
//
//  Created by Chris Li on 4/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// Tabbed library UI on iOS & iPadOS
struct LibraryView_iOS: View {
    @Binding var url: URL?
    @SceneStorage("library.selectedNavigationItem") private var selected: NavigationItem = .opened
    @State private var isFileImporterPresented = false
    @StateObject private var viewModel = LibraryViewModel()
    
    let navigationItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        TabView(selection: $selected) {
            ForEach(navigationItems) { navigationItem in
                SheetView {
                    switch navigationItem {
                    case .opened:
                        ZimFilesOpened(url: $url)
                    case .categories:
                        categories
                    case .downloads:
                        ZimFilesDownloads(url: $url)
                    case .new:
                        ZimFilesNew(url: $url)
                    default:
                        EmptyView()
                    }
                }
                .tag(navigationItem)
                .tabItem { Label(navigationItem.name, systemImage: navigationItem.icon) }
            }
        }
        .environmentObject(viewModel)
        .onAppear {
            Task {
                try? await viewModel.refresh(isUserInitiated: false)
            }
        }
    }
    
    var categories: some View {
        List(Category.allCases) { category in
            NavigationLink {
                ZimFilesCategory(category: .constant(category), url: $url)
                    .navigationTitle(category.name)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Favicon(category: category).frame(height: 26)
                    Text(category.name)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(NavigationItem.categories.name)
    }
}
