//
//  NaifTest.swift
//  Orbits
//
//  Created by Ben Lu on 1/27/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits

class NaifTest: XCTestCase {

    func testNaifComparison() {
        let (n499, n10, n402, n401, n599) = (Naif(naifId: 399), Naif(naifId: 10), Naif(naifId: 402), Naif(naifId: 401), Naif(naifId: 599))
        let sorted = [n499, n10, n402, n401, n599].sorted()
        XCTAssertEqual(sorted, [n10, n499, n401, n402, n599])

        let naifs = [301, 399, 10, 499, 402, 599, 501, 509, 508].map { Naif(naifId: $0) }
        XCTAssertEqual(naifs.sorted(), [10, 399, 301, 499, 402, 599, 501, 508, 509].map { Naif(naifId: $0) })
    }

}
