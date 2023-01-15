//
//  Tests.swift
//  Tests
//
//  Created by Chris Li on 1/15/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import XCTest
import Kiwix

final class OPDSParserTests: XCTestCase {
    let parser = OPDSParser()
    
    /// Test OPDSParser.parse throws error when OPDS data is invalid.
    func testInvalidOPDSData() {
        XCTExpectFailure("Requires work in dependency to resolve the issue.")
        let content = "Invalid OPDS Data"
        XCTAssertThrowsError(
            try self.parser.parse(data: content.data(using: .utf8)!)
        )
    }
    
    /// Test OPDSParser.getMetaData returns nil when no metadata available with the given ID.
    func testMetadataNotFound() {
        let zimFileID = UUID(uuidString: "1ec90eab-5724-492b-9529-893959520de4")!
        XCTAssertNil(self.parser.getMetaData(id: zimFileID))
    }
    
    /// Test OPDSParser can parse and extract zim file metadata.
    func test() throws {
        let content = """
        <feed xmlns="http://www.w3.org/2005/Atom"
              xmlns:dc="http://purl.org/dc/terms/"
              xmlns:opds="http://opds-spec.org/2010/catalog">
          <entry>
            <id>urn:uuid:1ec90eab-5724-492b-9529-893959520de4</id>
            <title>Best of Wikipedia</title>
            <updated>2023-01-07T00:00:00Z</updated>
            <summary>A selection of the best 50,000 Wikipedia articles</summary>
            <language>eng</language>
            <name>wikipedia_en_top</name>
            <flavour>maxi</flavour>
            <category>wikipedia</category>
            <tags>wikipedia;_category:wikipedia;_pictures:yes;_videos:no;_details:yes;_ftindex:yes</tags>
            <articleCount>50001</articleCount>
            <mediaCount>566835</mediaCount>
            <link rel="http://opds-spec.org/image/thumbnail"
                  href="/catalog/v2/illustration/1ec90eab-5724-492b-9529-893959520de4/"
                  type="image/png;width=48;height=48;scale=1"/>
            <link type="text/html" href="/content/wikipedia_en_top_maxi_2023-01"/>
            <author><name>Wikipedia</name></author>
            <publisher><name>Kiwix</name></publisher>
            <dc:issued>2023-01-07T00:00:00Z</dc:issued>
            <link rel="http://opds-spec.org/acquisition/open-access" type="application/x-zim"
              href="https://download.kiwix.org/zim/wikipedia/wikipedia_en_top_maxi_2023-01.zim.meta4" length="6515656704"/>
          </entry>
        </feed>
        """
        
        // Parse data
        let parser = OPDSParser()
        XCTAssertNoThrow(try parser.parse(data: content.data(using: .utf8)!))
        
        // check one zim file is populated
        let zimFileID = UUID(uuidString: "1ec90eab-5724-492b-9529-893959520de4")!
        XCTAssertEqual(parser.zimFileIDs, Set([zimFileID]))
        
        // check zim file metadata
        let metadata = try XCTUnwrap(parser.getMetaData(id: zimFileID))
        XCTAssertEqual(metadata.fileID, zimFileID)
        XCTAssertEqual(metadata.groupIdentifier, "wikipedia_en_top")
        XCTAssertEqual(metadata.title, "Best of Wikipedia")
        XCTAssertEqual(metadata.fileDescription, "A selection of the best 50,000 Wikipedia articles")
        XCTAssertEqual(metadata.languageCode, "en")
        XCTAssertEqual(metadata.category, "wikipedia")
        XCTAssertEqual(metadata.creationDate, try! Date("2023-01-07T00:00:00Z", strategy: .iso8601))
        XCTAssertEqual(metadata.size, 6515656704)
        XCTAssertEqual(metadata.articleCount, 50001)
        XCTAssertEqual(metadata.mediaCount, 566835)
        XCTAssertEqual(metadata.creator, "Wikipedia")
        XCTAssertEqual(metadata.publisher, "Kiwix")
        XCTAssertEqual(metadata.hasDetails, true)
        XCTAssertEqual(metadata.hasPictures, true)
        XCTAssertEqual(metadata.hasVideos, false)
        XCTAssertEqual(metadata.requiresServiceWorkers, false)
        
        XCTAssertEqual(
            metadata.downloadURL,
            URL(string: "https://download.kiwix.org/zim/wikipedia/wikipedia_en_top_maxi_2023-01.zim.meta4")
        )
        XCTAssertEqual(
            metadata.faviconURL,
            URL(string: "https://library.kiwix.org/catalog/v2/illustration/1ec90eab-5724-492b-9529-893959520de4/")
        )
        XCTAssertEqual(metadata.flavor, "maxi")
    }
}
