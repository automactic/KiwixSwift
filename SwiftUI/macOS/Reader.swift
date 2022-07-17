//
//  Reader.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Reader: View {
    @SceneStorage("Reader.SidebarDisplayMode") private var sidebarDisplayMode: SidebarDisplayMode = .search
    @StateObject var viewModel = ReaderViewModel()
    @State var url: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing:0) {
                VStack(spacing: 6) {
                    Divider()
                    HStack(spacing: 20) {
                        ForEach(SidebarDisplayMode.allCases) { displayMode in
                            Button {
                                self.sidebarDisplayMode = displayMode
                            } label: {
                                Image(systemName: displayMode.imageName)
                                    .foregroundColor(self.sidebarDisplayMode == displayMode ? .blue : nil)
                            }
                            .buttonStyle(.borderless)
                            .help(displayMode.help)
                        }
                    }
                    Divider()
                }.background(.thinMaterial)
                switch sidebarDisplayMode {
                case .search:
                    Search(url: $url)
                case .bookmarks:
                    Bookmarks(url: $url)
                case .outline:
                    Outline()
                case .library:
                    ZimFilesInLibrary(url: $url)
                }
            }
            .frame(minWidth: 250)
            .toolbar { SidebarButton() }
            Group {
                if url == nil {
                    Welcome(url: $url)
                } else {
                    WebView(url: $url).ignoresSafeArea(edges: .all)
                }
            }
            .frame(minWidth: 400, idealWidth: 1000, minHeight: 500, idealHeight: 750)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    ControlGroup {
                        NavigateBackButton()
                        NavigateForwardButton()
                    }
                }
                ToolbarItemGroup {
                    BookmarkButton(url: url)
                    MainArticleButton(url: $url)
                    RandomArticleButton(url: $url)
                }
            }
        }
        .environmentObject(viewModel)
        .focusedSceneValue(\.canGoBack, viewModel.canGoBack)
        .focusedSceneValue(\.canGoForward, viewModel.canGoForward)
        .focusedSceneValue(\.readerViewModel, viewModel)
        .focusedSceneValue(\.sidebarDisplayMode, $sidebarDisplayMode)
        .focusedSceneValue(\.url, url)
        .navigationTitle(viewModel.articleTitle.isEmpty ? "Reader" : viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileName)
        .onOpenURL { url in
            if url.isFileURL {
                guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                LibraryViewModel.open(url: url)
                self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
            } else if url.scheme == "kiwix" {
                self.url = url
            }
        }
    }
}

private struct ZimFilesInLibrary: View {
    @Binding var url: URL?
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\ZimFile.size, order: .reverse)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented: Bool = false
    @State private var selected: UUID?
    
    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "No opened zim files").ignoresSafeArea(edges: .vertical)
            } else {
                List(zimFiles, id: \.fileID, selection: $selected) { zimFile in
                    ZimFileRow(zimFile)
                }
                .onChange(of: selected) { zimFileID in
                    guard let zimFileID = zimFileID,
                          let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
                    self.url = url
                    selected = nil
                }
            }
        }.safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button {
                        isFileImporterPresented = true
                    } label: { Image(systemName: "plus") }
                    Spacer()
                    Button {
                        guard let url = URL(string: "kiwix-ui://library") else { return }
                        NSWorkspace.shared.open(url)
                    } label: { Image(systemName: "books.vertical") }
                }
                .buttonStyle(.borderless)
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }.background(.thinMaterial)
        }.modifier(FileImporter(isPresented: $isFileImporterPresented))
    }
}
