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
    
    let circularEquatorialLowEarthOrbit = Orbit(
        shape: Orbit.Shape(
            semimajorAxis: 378000,
            eccentricity: 0
        ),
        orientation: Orbit.Orientation(
            inclination: 0,
            longitudeOfAscendingNode: nil,
            argumentOfPeriapsis: nil
        )
    )
    
    let ISSOrbit = Orbit(
        shape: Orbit.Shape(
            apoapsis: 435000,
            periapsis: 330000
        ),
        orientation: Orbit.Orientation(
            inclination: 0,
            longitudeOfAscendingNode: nil,
            argumentOfPeriapsis: 0
        )
    )
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrbitalShapeCalculation() {
        let ap: Float = 500
        let pe: Float = 250
        let shape = Orbit.Shape(semimajorAxis: (500 + 250) / 2, eccentricity: (ap - pe) / (ap + pe))
        XCTAssertEqualWithAccuracy(ap, shape.apoapsis, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(pe, shape.periapsis, accuracy: 0.01)
        let shape2 = Orbit.Shape(apoapsis: ap, periapsis: pe)
        XCTAssertEqualWithAccuracy(shape.semimajorAxis, shape2.semimajorAxis, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(shape.eccentricity, shape2.eccentricity, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(shape.semimajorAxis * (1 - shape.eccentricity), shape2.periapsis, accuracy: 0.01)
    }
    
    func testCircularEquatorialOrbit() {
        let motion = OrbitalMotion(centralBody: Body(knownBody: .earth), orbit: circularEquatorialLowEarthOrbit, meanAnomaly: Float(M_PI))
        XCTAssertEqualWithAccuracy(motion.distance, circularEquatorialLowEarthOrbit.shape.semimajorAxis, accuracy: 0.001)
    }
    
    func testEllipticalEquatorialOrbit() {
        var motion = OrbitalMotion(centralBody: Body(knownBody: .earth), orbit: ISSOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.distance, ISSOrbit.shape.periapsis, accuracy: 0.001)
        motion.meanAnomaly = Float(M_PI)
        XCTAssertEqualWithAccuracy(motion.distance, ISSOrbit.shape.apoapsis, accuracy: 0.001)
    }
}
