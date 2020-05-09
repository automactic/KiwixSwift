//
//  SearchOperation.swift
//  iOS
//
//  Created by Chris Li on 5/9/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

extension SearchOperation {
    var results: [SearchResult] { get { __results as? [SearchResult] ?? [] } }
}
