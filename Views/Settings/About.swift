//
//  About.swift
//  Kiwix
//
//  Created by Chris Li on 6/10/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

import CoreKiwix

struct About: View {
    @State private var dependencies = [Dependency]()
    @State private var externalLinkURL: URL?
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            SettingSection(name: "settings.about.title".localized) {
                about
                ourWebsite
            }
            SettingSection(name: "settings.about.release".localized) {
                release
                HStack {
                    source
                    license
                }
            }
            SettingSection(name: "settings.about.dependencies".localized, alignment: .top) {
                Table(dependencies) {
                    TableColumn("settings.about.dependencies.name".localized, value: \.name)
                    TableColumn("settings.about.dependencies.license".localized) { dependency in
                        Text(dependency.license ?? "")
                    }
                    TableColumn("settings.about.dependencies.version".localized, value: \.version)
                }.tableStyle(.bordered(alternatesRowBackgrounds: true))
            }
        }
        .padding()
        .tabItem { Label("settings.about.title".localized, systemImage: "info.circle") }
        .task { await getDependencies() }
        .onChange(of: externalLinkURL) { url in
            guard let url = url else { return }
            NSWorkspace.shared.open(url)
        }
        #elseif os(iOS)
        List {
            Section {
                about
                ourWebsite
            }
            Section("settings.about.release".localized) {
                release
                appVersion
                buildNumber
                source
                license
            }
            Section("settings.about.dependencies".localized) {
                ForEach(dependencies) { dependency in
                    HStack {
                        Text(dependency.name)
                        Spacer()
                        if let license = dependency.license {
                            Text("\(license) (\(dependency.version))").foregroundColor(.secondary)
                        } else {
                            Text(dependency.version).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("settings.about.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $externalLinkURL) { SafariView(url: $0) }
        .task { await getDependencies() }
        #endif
    }
    
    private var about: some View {
        Text(Brand.aboutText)
    }
    
    private var release: some View {
        Text("settings.about.license-description".localized)
    }
    
    private var appVersion: some View {
        Attribute(title: "settings.about.appverion.title".localized,
                  detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
    }
    
    private var buildNumber: some View {
        Attribute(title: "settings.about.build.title".localized, 
                  detail: Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
    }
    
    private var ourWebsite: some View {
        Button("settings.about.our_website.button".localized) {
            externalLinkURL = URL(string: "https://\(Brand.aboutWebsite)")
        }
    }
    
    private var source: some View {
        Button("settings.about.source.title".localized) {
            externalLinkURL = URL(string: "https://github.com/kiwix/apple")
        }
    }
    
    private var license: some View {
        Button("settings.about.button.license".localized) {
            externalLinkURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
        }
    }
    
    private func getDependencies() async {
        dependencies = kiwix.getVersions().map { datum in
            Dependency(name: String(datum.first), version: String(datum.second))
        }
    }
}

private struct Dependency: Identifiable {
    var id: String { name }
    
    let name: String
    let version: String
    
    var license: String? {
        switch name {
        case "libkiwix":
            "GPLv3"
        case "libzim":
            "GPLv2"
        case "libxapian":
            "GPLv2"
        case "libicu":
            "ICU"
        default:
            nil
        }
    }
}

#Preview {
    #if os(macOS)
    TabView { About() }
    #elseif os(iOS)
    NavigationView { About() }
    #endif
}
