//
//  OrbitalMechanicsTest.swift
//  Graviton
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
@testable import Graviton

class OrbitalMechanicsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrbitalShapeCalculation() {
        let ap: Float = 250
        let pe: Float = 500
        let shape = Orbit.Shape(semimajorAxis: (500 + 250) / 2, eccentricity: (ap - pe) / (ap + pe))
        XCTAssertEqualWithAccuracy(ap, shape.apoapsis, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(pe, shape.periapsis, accuracy: 0.01)
    }
}
