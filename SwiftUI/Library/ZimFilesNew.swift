//
//  ZimFilesNew.swift
//  Kiwix
//
//  Created by Chris Li on 4/24/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

/// Show zim files that are created in the last month.
struct ZimFilesNew: View {
    @Default(.libraryLanguageCodes) private var languageCodes
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ZimFile.created, ascending: false),
            NSSortDescriptor(keyPath: \ZimFile.name, ascending: true),
            NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)
        ],
        predicate: ZimFilesNew.buildPredicate(searchText: ""),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var selected: ZimFile?
    @State private var searchText = ""
    
    var body: some View {
        Group {
            if zimFiles.isEmpty {
                Message(text: "No new zim file")
            } else {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(zimFiles) { zimFile in
                        Button { selected = zimFile } label: { ZimFileCell(zimFile, prominent: .name) }
                            .buttonStyle(.plain)
                            .modifier(ZimFileContextMenu(selected: $selected, zimFile: zimFile))
                            .modifier(ZimFileSelection(selected: $selected, zimFile: zimFile))
                    }
                }.modifier(GridCommon())
            }
        }
        .navigationTitle(LibraryTopic.new.name)
        .modifier(ZimFileDetailPanel(zimFile: selected))
        .modifier(Searchable(searchText: $searchText))
        .onChange(of: languageCodes) { _ in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFilesNew.buildPredicate(searchText: searchText)
            }
        }
        .onChange(of: searchText) { searchText in
            if #available(iOS 15.0, *) {
                zimFiles.nsPredicate = ZimFilesNew.buildPredicate(searchText: searchText)
            }
        }
    }
    
    private static func buildPredicate(searchText: String) -> NSPredicate {
        var predicates = [
            NSPredicate(format: "languageCode IN %@", Defaults[.libraryLanguageCodes]),
            NSPredicate(format: "requiresServiceWorkers == false")
        ]
        if let aMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
            predicates.append(NSPredicate(format: "created > %@", aMonthAgo as CVarArg))
        }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
