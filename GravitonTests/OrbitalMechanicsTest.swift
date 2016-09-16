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
    
    lazy var earth: CelestialBody = CelestialBody(knownBody: .earth)
    
    lazy var circularEquatorialLEO: Orbit = Orbit(
        shape: Orbit.ConicSection.from(
            semimajorAxis: 378000 + self.earth.radius,
            eccentricity: 0
        ),
        orientation: Orbit.Orientation(
            inclination: 0,
            longitudeOfAscendingNode: nil,
            argumentOfPeriapsis: nil
        )
    )
    
    lazy var ellipticalEquatorialLEO: Orbit = Orbit(
        shape: Orbit.ConicSection.from(
            apoapsis: 435000 + self.earth.radius,
            periapsis: 330000 + self.earth.radius
        ),
        orientation: Orbit.Orientation(
            inclination: 0,
            longitudeOfAscendingNode: nil,
            argumentOfPeriapsis: 0
        )
    )
    
    lazy var geoSyncOrbit: Orbit = Orbit(
        shape: Orbit.ConicSection.from(
            apoapsis: 35786_000 + self.earth.radius,
            periapsis: 35785_000 + self.earth.radius
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
        let ap: Float = 500000 + earth.radius
        let pe: Float = 250000 + earth.radius
        let shape = Orbit.ConicSection.from(semimajorAxis: (ap + pe) / 2, eccentricity: (ap - pe) / (ap + pe))
        XCTAssertEqualWithAccuracy(ap, shape.apoapsis!, accuracy: 1)
        XCTAssertEqualWithAccuracy(pe, shape.periapsis, accuracy: 1)
        let shape2 = Orbit.ConicSection.from(apoapsis: ap, periapsis: pe)
        XCTAssertEqualWithAccuracy(shape.semimajorAxis!, shape2.semimajorAxis!, accuracy: 1)
        XCTAssertEqualWithAccuracy(shape.eccentricity, shape2.eccentricity, accuracy: 1)
        XCTAssertEqualWithAccuracy(shape.semimajorAxis! * (1 - shape.eccentricity), shape2.periapsis, accuracy: 1)
    }
    
    func testCircularEquatorialOrbit() {
        var motion = OrbitalMotion(centralBody: earth, orbit: circularEquatorialLEO, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.distance, circularEquatorialLEO.shape.semimajorAxis!, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.position.x, 378000 + self.earth.radius, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.y, 0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 7800, accuracy: 300)
        motion.setMeanAnomaly(Float(M_PI_2))
        XCTAssertEqualWithAccuracy(motion.position.x, 0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.y, 378000 + self.earth.radius, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -7800, accuracy: 300)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 10)
        motion.setMeanAnomaly(Float(M_PI))
        XCTAssertEqualWithAccuracy(motion.position.x, -(378000 + self.earth.radius), accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.y, 0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -7800, accuracy: 300)
        
        XCTAssertEqualWithAccuracy(motion.distance, circularEquatorialLEO.shape.semimajorAxis!, accuracy: 1)
        // should attain orbital velocity
        XCTAssertEqualWithAccuracy(motion.info.speed, 7800, accuracy: 300)
    }
    
    func testEllipticalEquatorialOrbit() {
        var motion = OrbitalMotion(centralBody: earth, orbit: ellipticalEquatorialLEO, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.distance, ellipticalEquatorialLEO.shape.periapsis, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(motion.position.x, 330000 + self.earth.radius, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.y, 0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 7700, accuracy: 300)
        motion.setMeanAnomaly(Float(M_PI))
        
        XCTAssertEqualWithAccuracy(motion.distance, ellipticalEquatorialLEO.shape.apoapsis!, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(motion.position.x, -(435000 + self.earth.radius), accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.y, 0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -7700, accuracy: 300)
        motion.setMeanAnomaly(Float(3 * M_PI_2))
        motion.setMeanAnomaly(Float(2 * M_PI))
    }
    
    func testGeosynchrounousOrbit() {
        let motion = OrbitalMotion(centralBody: earth, orbit: geoSyncOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, siderealDay, accuracy: 5)
    }
    
}
