//
//  SearchFilterView.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/16/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

import RealmSwift

/// Controls which zim files are included in search.
struct SearchFilterView: View {
    @ObservedResults(
        ZimFile.self,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) private var zimFiles
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("Include in Search").fontWeight(.medium)
                Spacer()
                if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
                    Button { selectNone() } label: {
                        Text("None").font(.caption).fontWeight(.medium)
                    }
                } else {
                    Button { selectAll() } label: {
                        Text("All").font(.caption).fontWeight(.medium)
                    }
                }
            }.padding(.vertical, 5).padding(.leading, 16).padding(.trailing, 10).background(.regularMaterial)
            Divider()
            List {
                ForEach(zimFiles, id: \.fileID) { zimFile in
                    Toggle(zimFile.title, isOn: zimFile.bind(\.includedInSearch))
                }
            }
        }.frame(height: 180)
    }
    
    private func selectAll() {
        let database = try? Realm()
        try? database?.write {
            let zimFiles = database?.objects(ZimFile.self).where { ($0.stateRaw == ZimFile.State.onDevice.rawValue) }
            zimFiles?.forEach { $0.includedInSearch = true }
        }
    }
    
    private func selectNone() {
        let database = try? Realm()
        try? database?.write {
            let zimFiles = database?.objects(ZimFile.self).where { ($0.stateRaw == ZimFile.State.onDevice.rawValue) }
            zimFiles?.forEach { $0.includedInSearch = false }
        }
    }
}
