//
//  FormattersTest.swift
//  GravitonTests
//
//  Created by Sihao Lu on 2/7/18.
//  Copyright © 2018 Ben Lu. All rights reserved.
//

import XCTest
import CoreLocation
@testable import Graviton

class FormattersTest: XCTestCase {
    func testCoordinateFormatter() {
        let formatter = CoordinateFormatter()

        let coordinate = CLLocationCoordinate2D(latitude: -32.1, longitude: 58.42)
        let result = formatter.string(for: coordinate)
        XCTAssertEqual(result, "32° 6′ 0″ S, 58° 25′ 12″ E")

        let coordinate2 = CLLocationCoordinate2D(latitude: 173.94, longitude: -21.7)
        let result2 = formatter.string(for: coordinate2)
        XCTAssertEqual(result2, "173° 56′ 24″ N, 21° 41′ 60″ W")

        let zero = CLLocationCoordinate2D()
        XCTAssertEqual(formatter.string(for: zero), "0° 0′ 0″ N, 0° 0′ 0″ E")
    }
}
