//
//  Log.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import os

private let subsystem = "org.kiwix.kiwix"

struct Log {
    static let OPDS = OSLog(subsystem: subsystem, category: "OPDS")
}
