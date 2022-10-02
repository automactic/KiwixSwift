//
//  SettingsContent.swift
//  Kiwix
//
//  Created by Chris Li on 10/1/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SettingsContent: View {
    var body: some View {
        #if os(macOS)
        TabView {
            ReadingSettings()
            LibrarySettings()
            About()
        }.frame(width: 550, height: 400)
        #elseif os(iOS)
        Form {
            ReadingSettings()
            LibrarySettings()
            Section {
                Button("Feedback") { UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!) }
                Button("Rate the App") {
                    let url = URL(string:"itms-apps://itunes.apple.com/us/app/kiwix/id997079563?action=write-review")!
                    UIApplication.shared.open(url)
                }
                NavigationLink("About") { About() }
            } header: {
                Text("Misc")
            }
        }.navigationTitle("Settings")
        #endif
    }
}

struct SettingSection<Content: View>: View {
    let name: String
    let alignment: VerticalAlignment
    var content: () -> Content
    
    init(
        name: String,
        alignment: VerticalAlignment = .firstTextBaseline,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.name = name
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: alignment) {
            Text("\(name):").frame(width: 100, alignment: .trailing)
            VStack(alignment: .leading, spacing: 16, content: content)
            Spacer()
        }
    }
}
