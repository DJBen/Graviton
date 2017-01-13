//
//  HorizonsTest.swift
//  StarCatalog
//
//  Created by Ben Lu on 12/20/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits

class HorizonsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUrlConstruction() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MMM-dd HH:mm"

        let timeString = f.string(from: Date())
        let timeString1hLater = f.string(from: Date(timeIntervalSinceNow: 3600))
        let urls = (1...8).map { String($0) }.map { $0 + "99" }.map { "\(Horizons.batchUrl)?MAKE_EPHEM='YES'&CENTER='10'&TABLE_TYPE='Elements'&COMMAND='\($0)'&STOP_TIME='\(timeString1hLater)'&CSV_FORMAT='YES'&batch='1'&START_TIME='\(timeString)'&STEP_SIZE='1'".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlAllowedCharacterSet) }
        zip(urls, HorizonsQuery.planetQueryItems).forEach { (urlString, query) in
            XCTAssertEqual(query.url.absoluteString, urlString)
        }
    }
    
}

fileprivate extension CharacterSet {
    static var urlAllowedCharacterSet: CharacterSet {
        return CharacterSet.urlPathAllowed.union(.urlHostAllowed).union(.urlQueryAllowed)
    }
}
