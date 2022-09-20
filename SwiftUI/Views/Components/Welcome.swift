//
//  Welcome.swift
//  Kiwix
//
//  Created by Chris Li on 6/4/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Welcome: View {
    @Binding var url: URL?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bookmark.created, ascending: false)],
        animation: .easeInOut
    ) private var bookmarks: FetchedResults<Bookmark>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var selectedZimFile: ZimFile?
    
    var body: some View {
        if zimFiles.isEmpty {
            Onboarding()
        } else {
            ScrollView {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    Section {
                        ForEach(zimFiles) { zimFile in
                            Button {
                                url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID)
                            } label: {
                                ZimFileCell(zimFile, prominent: .name)
                            }
                            .buttonStyle(.plain)
                            .modifier(ZimFileContextMenu(selected: $selectedZimFile, url: $url, zimFile: zimFile))
                        }
                    } header: {
                        Text("Main Page").font(.title3).fontWeight(.semibold)
                    }
                    if !bookmarks.isEmpty {
                        Section {
                            ForEach(bookmarks) { bookmark in
                                Button { url = bookmark.articleURL } label: {
                                    ArticleCell(bookmark: bookmark).frame(height: bookmarkItemHeight)
                                }
                                .buttonStyle(.plain)
                                .modifier(BookmarkContextMenu(url: $url, bookmark: bookmark))
                            }
                        } header: {
                            Text("Bookmarks").font(.title3).fontWeight(.semibold)
                        }
                    }
                }.padding()
            }
            #if os(iOS)
            .sheet(item: $selectedZimFile) { zimFile in
                SheetView {
                    ZimFileDetail(url: $url, zimFile: zimFile)
                }
            }
            #endif
        }
    }
    
    private var bookmarkItemHeight: CGFloat? {
        #if os(macOS)
        82
        #elseif os(iOS)
        horizontalSizeClass == .regular ? 110: nil
        #endif
    }
}

private struct Onboarding: View {
    @EnvironmentObject private var viewModel: ViewModel
    @StateObject private var libraryViewModel = LibraryViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Image("Kiwix_logo_v3")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .padding(2)
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.white))
                Text("KIWIX").font(.largeTitle).fontWeight(.bold)
            }
            Divider()
            HStack {
                OnboardingViewButton {
                    viewModel.activeSheet = .library
                } content: {
                    Text("Open File")
                }
                OnboardingViewButton {
                    libraryViewModel.startRefresh(isUserInitiated: true)
                } content: {
                    if libraryViewModel.isRefreshing {
                        HStack(spacing: 6) {
                            ProgressView()
                            Text("Fetching...")
                        }
                    } else {
                        Text("Fetch Catalog")
                    }
                }.disabled(libraryViewModel.isRefreshing)
            }
        }
        .padding()
        .frame(maxWidth: 600)
    }
}

private struct OnboardingViewButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Spacer()
                content
                Spacer()
            }.padding(6)
        }
        .font(.subheadline)
        .modify { view in
            if #available(iOS 15.0, *) {
                view.buttonStyle(.bordered)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Welcome(url: .constant(nil)).preferredColorScheme(.light).padding()
        Welcome(url: .constant(nil)).preferredColorScheme(.dark).padding()
    }
}
