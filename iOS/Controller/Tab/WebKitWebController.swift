//
//  WebKitTabController.swift
//  WikiMed
//
//  Created by Chris Li on 9/11/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import SafariServices


@available(iOS 11.0, *)
class WebKitWebController: UIViewController, WKUIDelegate, WKNavigationDelegate, WebViewController {
    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(KiwixURLSchemeHandler(), forURLScheme: "kiwix")
        return WKWebView(frame: .zero, configuration: config)
    }()
    weak var delegate: WebViewControllerDelegate?
    
    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 70, 0)
    }
    
    var canGoBack: Bool {
        get {return webView.canGoBack}
    }
    
    var canGoForward: Bool {
        get {return webView.canGoForward}
    }
    
    var currentURL: URL? {
        get {return webView.url}
    }
    
    // MARK: - Configure
    
    private func configureWebView() {
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsLinkPreview = true
        webView.allowsBackForwardNavigationGestures = true
    }
    
    // MARK: - loading
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Capabilities
    
    func extractTableOfContents(completion: @escaping ((URL?, [TableOfContentItem]) -> Void)) {
        let javascript = "tableOfContents.getHeadingObjects()"
        webView.evaluateJavaScript(javascript, completionHandler: { (results, error) in
            guard let elements = results as? [[String: Any]] else {completion(self.currentURL, []); return}
            let items = elements.flatMap({ TableOfContentItem(rawValue: $0) })
            completion(self.currentURL, items)
        })
    }
    
    func scrollToTableOfContentItem(index: Int) {
        let javascript = "tableOfContents.scrollToView(\(index))"
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {return decisionHandler(.cancel)}
        if url.isKiwixURL {
            decisionHandler(.allow)
        } else {
            let controller = SFSafariViewController(url: url)
            present(controller, animated: true, completion: nil)
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = Bundle.main.url(forResource: "Inject", withExtension: "js"),
            let javascript = try? String(contentsOf: url) {
            webView.evaluateJavaScript(javascript, completionHandler: { (_, error) in
                self.delegate?.webViewDidFinishLoading(controller: self)
            })
        } else {
            delegate?.webViewDidFinishLoading(controller: self)
        }
    }
}


