//
//  NavigationButtons.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct NavigationButtons: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var browser: BrowserViewModel
    
    var body: some View {
        if horizontalSizeClass == .regular {
            goBackButton
            goForwardButton
        } else {
            goBackButton
            Spacer()
            goForwardButton
        }
    }
    
    var goBackButton: some View {
        Button {
            browser.webView.goBack()
            dismissSearch()
        } label: {
            Label("Go Back".localized, systemImage: "chevron.left")
        }.disabled(!browser.canGoBack)
    }
    
    var goForwardButton: some View {
        Button {
            browser.webView.goForward()
            dismissSearch()
        } label: {
            Label("Go Forward".localized, systemImage: "chevron.right")
        }.disabled(!browser.canGoForward)
    }
}
