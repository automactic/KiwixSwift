//
//  WebView.swift
//  Kiwix
//
//  Created by Chris Li on 11/5/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI
import WebKit

import Defaults

#if os(macOS)
struct WebView: NSViewRepresentable {
    @EnvironmentObject private var viewModel: BrowserViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        viewModel.webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) { }
}
#elseif os(iOS)
struct WebView: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModel: BrowserViewModel
        
    func makeUIViewController(context: Context) -> WebViewController {
        WebViewController(tabID: viewModel.tabID, webView: viewModel.webView)
    }
    
    func updateUIViewController(_ controller: WebViewController, context: Context) { }
    
    static func dismantleUIViewController(_ controller: WebViewController, coordinator: ()) {
        guard let interactionState = controller.webView.interactionState as? Data else { return }
        Database.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            guard let tab = try? context.fetch(Tab.fetchRequest(id: controller.tabID)).first else { return }
            tab.interactionState = interactionState
            try? context.save()
        }
    }
}

class WebViewController: UIViewController {
    let tabID: UUID
    let webView: WKWebView
    private var zoomScale: CGFloat = 1
    
    init(tabID: UUID, webView: WKWebView) {
        self.tabID = tabID
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidEnterBackground),
            name: UIScene.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupWebView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.setValue(view.safeAreaInsets, forKey: "_obscuredInsets")
    }
    
    
    /// Store page zoom scale when scene enters background
    /// HACK: when scene enters background, the system resizes the scene and take various screenshots (for app switcher), during which
    /// the webview becomes zoomed in. To mitigate, store and reapply webview's zoom scale when scene enters backgroud / foreground.
    @objc private func sceneDidEnterBackground() {
        zoomScale = webView.scrollView.zoomScale
    }
    
    /// Reapply stored zoom scale when scene enters foreground
    @objc private func sceneWillEnterForeground() {
        self.webView.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.webView.scrollView.setZoomScale(self.zoomScale, animated: false)
            UIView.animate(withDuration: 0.1) {
                self.webView.alpha = 1
            }
        }
    }
    
    /// Install web view
    private func setupWebView() {
        guard !view.subviews.contains(webView) else { return }
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        /*
         HACK: Make sure the webview content does not jump after state restoration
         It appears the webview's state restoration does not properly take into account of the content inset.
         To mitigate, first pin the webview's top against safe area top anchor, let the webview restore state,
         then pin the webview's top against view's top anchor, so that content does not appears to move up.
         */
        
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: webView.leftAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: webView.rightAnchor)
        ])
        
        let topSafeAreaConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: webView.topAnchor)
        topSafeAreaConstraint.isActive = true
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard self.webView.superview == self.view else { return }
            topSafeAreaConstraint.isActive = false
            let topConstraint = self.view.topAnchor.constraint(equalTo: self.webView.topAnchor)
            topConstraint.isActive = true
        }
    }
}
#endif

extension WKWebView {
    func applyTextSizeAdjustment() {
        #if os(iOS)
        guard Defaults[.webViewPageZoom] != 1 else { return }
        let template = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%.0f%%'"
        let javascript = String(format: template, Defaults[.webViewPageZoom] * 100)
        evaluateJavaScript(javascript, completionHandler: nil)
        #endif
    }
}

class WebViewConfiguration: WKWebViewConfiguration {
    override init() {
        super.init()
        setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        userContentController = {
            let controller = WKUserContentController()
            if FeatureFlags.wikipediaDarkUserCSS,
               let path = Bundle.main.path(forResource: "wikipedia_dark", ofType: "css"),
               let css = try? String(contentsOfFile: path) {
                let source = """
                    var style = document.createElement('style');
                    style.innerHTML = `\(css)`;
                    document.head.appendChild(style);
                    """
                let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                controller.addUserScript(script)
            }
            if let url = Bundle.main.url(forResource: "injection", withExtension: "js"),
               let javascript = try? String(contentsOf: url) {
                let script = WKUserScript(source: javascript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                controller.addUserScript(script)
            }
            return controller
        }()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
