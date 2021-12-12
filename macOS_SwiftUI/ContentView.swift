//
//  ContentView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import WebKit
import RealmSwift

struct ContentView: View {
    @StateObject var viewModel = SceneViewModel()
    @State var url: URL?
    @ObservedResults(
        ZimFile.self,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) private var onDevice
    
    var body: some View {
        NavigationView {
            Sidebar(url: $url)
                .environmentObject(viewModel)
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            WebView(url: $url, webView: viewModel.webView)
                .ignoresSafeArea(.container, edges: .vertical)
                .frame(idealWidth: 800, minHeight: 300, idealHeight: 350)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { viewModel.webView.goBack() } label: {
                            Image(systemName: "chevron.backward")
                        }.disabled(!viewModel.canGoBack)
                        Button { viewModel.webView.goForward() } label: {
                            Image(systemName: "chevron.forward")
                        }.disabled(!viewModel.canGoForward)
                    }
                    ToolbarItemGroup {
                        Button {
                            viewModel.loadMainPage()
                        } label: { Image(systemName: "house") }.disabled(onDevice.isEmpty)
                        Menu {
                            ForEach(onDevice) { zimFile in
                                Button(zimFile.title) { viewModel.loadRandomPage(zimFileID: zimFile.fileID) }
                            }
                        } label: {
                            Label("Random Page", systemImage: "die.face.5")
                        } primaryAction: {
                            guard let zimFile = onDevice.first else { return }
                            viewModel.loadRandomPage(zimFileID: zimFile.fileID)
                        }.disabled(onDevice.isEmpty)
                    }
                }
        }
        .environmentObject(viewModel)
        .focusedSceneValue(\.sceneViewModel, viewModel)
        .navigationTitle(viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileTitle)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

class SceneViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var articleTitle: String = ""
    @Published var zimFileTitle: String = ""
    
    let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        config.userContentController = {
            let controller = WKUserContentController()
            guard FeatureFlags.wikipediaDarkUserCSS,
                  let path = Bundle.main.path(forResource: "wikipedia_dark", ofType: "css"),
                  let css = try? String(contentsOfFile: path) else { return controller }
            let source = """
                var style = document.createElement('style');
                style.innerHTML = `\(css)`;
                document.head.appendChild(style);
                """
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            controller.addUserScript(script)
            return controller
        }()
        return WKWebView(frame: .zero, configuration: config)
    }()
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?
    private var titleObserver: NSKeyValueObservation?
    
    override init() {
        super.init()
        webView.navigationDelegate = self
        canGoBackObserver = webView.observe(\.canGoBack) { [unowned self] webView, _ in
            self.canGoBack = webView.canGoBack
        }
        canGoForwardObserver = webView.observe(\.canGoForward) { [unowned self] webView, _ in
            self.canGoForward = webView.canGoForward
        }
        titleObserver = webView.observe(\.title) { [unowned self] webView, _ in
            guard let title = webView.title, !title.isEmpty,
                  let zimFileID = webView.url?.host,
                  let zimFile = (try? Realm())?.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
            self.articleTitle = title
            self.zimFileTitle = zimFile.title
        }
    }
    
    func loadMainPage(zimFileID: String? = nil) {
        let zimFileID = zimFileID ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
    
    func loadRandomPage(zimFileID: String? = nil) {
        let zimFileID = zimFileID ?? webView.url?.host ?? ""
        guard let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        webView.load(URLRequest(url: url))
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel, preferences); return }
        if url.isKiwixURL {
            if let redirectedURL = ZimFileService.shared.getRedirectedURL(url: url) {
                decisionHandler(.cancel, preferences)
                print("Redirecting to: \(redirectedURL.path)")
                webView.load(URLRequest(url: redirectedURL))
            } else {
                preferences.preferredContentMode = .desktop
                print("Loading: \(url.path)")
                decisionHandler(.allow, preferences)
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            decisionHandler(.cancel, preferences)
        } else if url.scheme == "geo" {
            decisionHandler(.cancel, preferences)
        } else {
            decisionHandler(.cancel, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(
            "document.querySelectorAll(\"details\").forEach((detail) => {detail.setAttribute(\"open\", true)});",
            completionHandler: nil
        )
    }
}
