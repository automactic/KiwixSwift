//
//  Settings.swift
//  Kiwix
//
//  Created by Chris Li on 6/20/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import Defaults

extension Defaults.Keys {
    // reading
    static let externalLinkLoadingPolicy = Key<ExternalLinkLoadingPolicy>(
        "externalLinkLoadingPolicy", default: .alwaysAsk
    )
    
    // UI
    static let sideBarDisplayMode = Key<SideBarDisplayMode>("sideBarDisplayMode", default: .automatic)
    
    // search
    static let recentSearchTexts = Key<[String]>("recentSearchTexts", default: [])
    static let searchResultSnippetMode = Key<SearchResultSnippetMode>(
        "searchResultSnippetMode", default: .firstParagraph
    )
    
    // library
    static let libraryFilterLanguageCodes = Key<[String]>("libraryFilterLanguageCodes", default: [])
    static let libraryShownLanguageFilterAlert = Key<Bool>("libraryHasShownLanguageFilterAlert", default: false)
    static let libraryLanguageSortingMode = Key<LibraryLanguageFilterSortingMode>(
        "libraryLanguageSortingMode", default: LibraryLanguageFilterSortingMode.alphabetically
    )
    static let libraryAutoRefresh = Key<Bool>("libraryAutoRefresh", default: true)
    static let libraryLastRefreshTime = Key<Date?>("libraryLastRefreshTime")
    static let backupDocumentDirectory = Key<Bool>("backupDocumentDirectory", default: false)
}

extension Defaults {
    static subscript(key: Key<[String]>) -> [String] {
        get { (key.suite.array(forKey: key.name) as? [String]) ?? key.defaultValue }
        set { key.suite.set(newValue, forKey: key.name) }
    }
    
    static subscript(key: Key<ExternalLinkLoadingPolicy>) -> ExternalLinkLoadingPolicy {
        get { ExternalLinkLoadingPolicy(rawValue: key.suite.integer(forKey: key.name)) ?? key.defaultValue }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
    
    static subscript(key: Key<SideBarDisplayMode>) -> SideBarDisplayMode {
        get { SideBarDisplayMode(rawValue: key.suite.string(forKey: key.name) ?? "") ?? key.defaultValue }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
    
    static subscript(key: Key<SearchResultSnippetMode>) -> SearchResultSnippetMode {
        get {
            if let mode = SearchResultSnippetMode(rawValue: key.suite.string(forKey: key.name) ?? "") {
                return mode
            } else if key.suite.bool(forKey: "searchResultExcludeSnippet") {
                return .disabled
            } else {
                return .firstParagraph
            }
        }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
    
    static subscript(key: Key<LibraryLanguageFilterSortingMode>) -> LibraryLanguageFilterSortingMode {
        get { LibraryLanguageFilterSortingMode(rawValue: key.suite.string(forKey: key.name) ?? "") ?? key.defaultValue }
        set { key.suite.set(newValue.rawValue, forKey: key.name) }
    }
}

extension UserDefaults {
    @objc var recentSearchTexts: [String] {
        get { return stringArray(forKey: "recentSearchTexts") ?? [] }
    }
    @objc dynamic var webViewTextSizeAdjustFactor: Double {
        get { value(forKey: "webViewZoomScale") == nil ? 1 : double(forKey: "webViewZoomScale") }
        set { set(newValue, forKey: "webViewZoomScale") }
    }
}
