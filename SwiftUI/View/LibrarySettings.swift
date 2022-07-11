//
//  LibrarySettings.swift
//  Kiwix
//
//  Created by Chris Li on 6/11/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif
import SwiftUI

import CoreData
import Defaults

struct LibrarySettings: View {
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.libraryAutoRefresh) private var autoRefresh
    @Default(.libraryLastRefresh) private var lastRefresh
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 16) {
            SettingSection(name: "Catalog") {
                HStack(spacing: 6) {
                    Button("Refresh Now") {
                        Task { try? await viewModel.refresh(isUserInitiated: true) }
                    }.disabled(viewModel.isRefreshing)
                    if viewModel.isRefreshing {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    Text("Last refresh:").foregroundColor(.secondary)
                    lastRefreshTime.foregroundColor(.secondary)
                }
                VStack(alignment: .leading) {
                    Toggle("Auto refresh", isOn: $autoRefresh)
                    Text("When enabled, the library catalog will be refreshed automatically when outdated.")
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: "Languages") {
                LanguageSelector()
            }
        }
        .padding()
        .tabItem { Label("Library", systemImage: "folder.badge.gearshape") }
        #elseif os(iOS)
        Section {
            HStack {
                Text("Last refresh")
                Spacer()
                lastRefreshTime.foregroundColor(.secondary)
            }
            if viewModel.isRefreshing {
                HStack {
                    Text("Refreshing...").foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button("Refresh Now") {
                    Task { try? await viewModel.refresh(isUserInitiated: true) }
                }
            }
            Toggle("Auto refresh", isOn: $autoRefresh)
        } header: {
            Text("Catalog")
        } footer: {
            Text("When enabled, the library catalog will be refreshed automatically when outdated.")
        }
        .onChange(of: autoRefresh) { isEnable in
            if isEnable {
                let request = BGAppRefreshTaskRequest(identifier: LibraryViewModel.backgroundTaskIdentifier)
                try? BGTaskScheduler.shared.submit(request)
            } else {
                BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: LibraryViewModel.backgroundTaskIdentifier)
            }
        }
        .onChange(of: backupDocumentDirectory) { _ in Kiwix.applyZimFileBackupSetting() }
        #endif
    }
    
    @ViewBuilder
    var lastRefreshTime: some View {
        if let lastRefresh = lastRefresh {
            if Date().timeIntervalSince(lastRefresh) < 120 {
                Text("Just Now")
            } else {
                Text(RelativeDateTimeFormatter().localizedString(for: lastRefresh, relativeTo: Date()))
            }
        } else {
            Text("Never")
        }
    }
}

struct LibrarySettings_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.light)
        TabView { LibrarySettings() }.frame(width: 480).preferredColorScheme(.dark)
        #elseif os(iOS)
        NavigationView { LibrarySettings() }
        NavigationView { LanguageSelector() }
        #endif
    }
}
