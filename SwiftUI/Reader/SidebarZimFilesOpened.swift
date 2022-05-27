//
//  SidebarZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/27/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SidebarZimFilesOpened: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\ZimFile.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil"),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var selected: ZimFile?
    
    var body: some View {
        List(zimFiles, id: \.self, selection: $selected) { zimFile in
            ZimFileRow(zimFile)
        }
    }
}
