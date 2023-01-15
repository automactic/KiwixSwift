//
//  OPDSParser.swift
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2023 Chris Li. All rights reserved.
//

public extension OPDSParser {
    var zimFileIDs: Set<UUID> {
        __getZimFileIDs() as? Set<UUID> ?? Set<UUID>()
    }
    
    func parse(data: Data) throws {
        if !self.__parseData(data) {
            throw LibraryRefreshError.parse
        }
    }
    
    func getMetaData(id: UUID) -> ZimFileMetaData? {
        return __getZimFileMetaData(id)
    }
}
