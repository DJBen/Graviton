//
//  SolarSystemTest.swift
//  Graviton
//
//  Created by Ben Lu on 9/18/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
@testable import Graviton
import SceneKit

class SolarSystemTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSystemAssembling() {
        var system = solarSystem
        XCTAssertEqual(system.star.name, "sol")
        XCTAssertEqual(system.star.satellites.count, 1)
        XCTAssertEqual(system.star.satellites[0].name, "earth")
        XCTAssertTrue(system["earth"] === system.star.satellites[0])
        system.time = 10
        XCTAssertEqualWithAccuracy(system.star.time, 10, accuracy: 1e-6)
        XCTAssertEqualWithAccuracy(system["earth"]!.time, 10, accuracy: 1e-6)
    }
    
}
