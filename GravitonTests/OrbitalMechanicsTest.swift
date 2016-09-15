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
    
    lazy var circularEquatorialLowEarthOrbit: Orbit = Orbit(
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
    
    lazy var ISSOrbit: Orbit = Orbit(
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
        var motion = OrbitalMotion(centralBody: earth, orbit: circularEquatorialLowEarthOrbit, meanAnomaly: Float(M_PI))
        XCTAssertEqualWithAccuracy(motion.distance, circularEquatorialLowEarthOrbit.shape.semimajorAxis!, accuracy: 1)
        motion.meanAnomaly = Float(M_PI)
        XCTAssertEqualWithAccuracy(motion.distance, circularEquatorialLowEarthOrbit.shape.semimajorAxis!, accuracy: 1)
        // should attain orbital velocity
        XCTAssertEqualWithAccuracy(motion.info.speed, 7800, accuracy: 300)
    }
    
    func testEllipticalEquatorialOrbit() {
        var motion = OrbitalMotion(centralBody: earth, orbit: ISSOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.distance, ISSOrbit.shape.periapsis, accuracy: 0.001)
        motion.meanAnomaly = Float(M_PI_2)
        motion.meanAnomaly = Float(M_PI)
        XCTAssertEqualWithAccuracy(motion.distance, ISSOrbit.shape.apoapsis!, accuracy: 0.001)
        motion.meanAnomaly = Float(3 * M_PI_2)
        motion.meanAnomaly = Float(2 * M_PI)
    }
    
    func testGeosynchrounousOrbit() {
        let motion = OrbitalMotion(centralBody: earth, orbit: geoSyncOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, siderealDay, accuracy: 5)
    }
}
