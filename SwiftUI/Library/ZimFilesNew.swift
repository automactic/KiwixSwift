//
//  ZimFilesNew.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

/// Show zim files that are created in the last two weeks.
@available(iOS 15.0, macOS 12.0, *)
struct ZimFilesNew: View {
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\ZimFile.created, order: .reverse),
            SortDescriptor(\ZimFile.name, order: .forward),
            SortDescriptor(\ZimFile.size, order: .reverse)
        ],
        predicate: ZimFilesNew.buildPredicate(searchText: ""),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var selected: ZimFile?
    @State private var searchText = ""
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(zimFiles) { zimFile in
                        Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .title) }
                            .buttonStyle(.plain)
                            .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                            .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                    }
                }.modifier(LibraryGridPadding(width: proxy.size.width))
            }
        }
        .navigationTitle(LibraryTopic.new.name)
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .searchable(text: $searchText)
        .onChange(of: searchText) { searchText in
            zimFiles.nsPredicate = ZimFilesNew.buildPredicate(searchText: searchText)
        }
    }
    
    private static func buildPredicate(searchText: String) -> NSPredicate {
        var predicates = [NSPredicate(format: "languageCode == %@", "en")]
        if let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) {
            predicates.append(NSPredicate(format: "created > %@", twoWeeksAgo as CVarArg))
        }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
