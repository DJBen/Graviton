//
//  StateVectorTest.swift
//  Graviton
//
//  Created by Ben Lu on 9/16/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits
import SceneKit

class StateVectorTest: XCTestCase {
    
    let sun = CelestialBody(knownBody: .sun)
    let earth = CelestialBody(knownBody: .earth)
    
    // this body will generate 1m/s^2 of gravity acceleration to any object that is 1 meter away
    let hypotheticalBody = CelestialBody(name: "perfect", mass: 1 / gravConstant, radius: 0)
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCircularStateVectors() {
        let position = SCNVector3(x: 0, y: 1, z: 0)
        let velocity = SCNVector3(x: -1, y: 0, z: 0)
        let motion = OrbitalMotion(centralBody: hypotheticalBody, position: position, velocity: velocity)
        XCTAssertLessThan(motion.specificMechanicalEnergy, 0)
        XCTAssertEqualWithAccuracy(motion.orbit.shape.semimajorAxis!, 1, accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.orbit.shape.eccentricity, 0, accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.orbit.orientation.inclination, 0, accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, Double(2 * M_PI) * sqrt(1), accuracy: 1e-4)
        // circular orbit not being able to calculate mean anomaly
        XCTAssertEqualWithAccuracy(motion.meanAnomaly, 0, accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.orbit.orientation.argumentOfPeriapsis, Double(M_PI_2), accuracy: 1e-4)
        XCTAssertNil(motion.orbit.orientation.longitudeOfAscendingNode)
    }
    
    func testEllipticalStateVectors() {
        let position = SCNVector3(x: 0, y: 1, z: 0)
        let velocity = SCNVector3(x: -1.154572372132788, y: 0, z: 0)
        let motion = OrbitalMotion(centralBody: hypotheticalBody, position: position, velocity: velocity)
        XCTAssertLessThan(motion.specificMechanicalEnergy, 0)
        XCTAssertEqualWithAccuracy(motion.orbit.shape.semimajorAxis!, 1.5, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(motion.orbit.shape.eccentricity, 1/3.0, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(motion.orbit.orientation.inclination, 0, accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, 11.5353, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(motion.meanAnomaly, 0, accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.orbit.orientation.argumentOfPeriapsis, Double(M_PI_2), accuracy: 1e-3)
        XCTAssertNil(motion.orbit.orientation.longitudeOfAscendingNode)
        let p2 = SCNVector3(x: 0, y: 2, z: 0)
        let v2 = SCNVector3(x: 0.577286, y: 0, z: 0)
        let m2 = OrbitalMotion(centralBody: hypotheticalBody, position: p2, velocity: v2)
        XCTAssertLessThan(m2.specificMechanicalEnergy, 0)
        XCTAssertEqualWithAccuracy(m2.orbit.shape.semimajorAxis!, 1.5, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(m2.orbit.shape.eccentricity, 1/3.0, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(m2.orbit.orientation.inclination, Double(M_PI), accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(m2.orbitalPeriod!, 11.5353, accuracy: 1e-2)
        XCTAssertEqualWithAccuracy(m2.meanAnomaly, Double(M_PI), accuracy: 1e-2)
        XCTAssertEqualWithAccuracy(m2.orbit.orientation.argumentOfPeriapsis, Double(-M_PI_2), accuracy: 1e-3)
        XCTAssertNil(m2.orbit.orientation.longitudeOfAscendingNode)
    }
    
    func testStateVectorsToClassicalOrbitalElements() {
        let position = SCNVector3(
            x: -88165364687.77095,
            y: 117966526597.76492,
            z: -3022322007.0290756
        )
        let velocity = SCNVector3(
            x: -24348.935884637474,
            y: -17933.232592161017,
            z: 551.9426101828388
        )
        let motion = OrbitalMotion(centralBody: sun, position: position, velocity: velocity)
        XCTAssertLessThan(motion.specificMechanicalEnergy, 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, 31557995.894672215, accuracy: 1e3)
        XCTAssertEqualWithAccuracy(motion.orbit.shape.semimajorAxis!, 149_598_000_000, accuracy: 149_598_000_000 / 1e3)
        XCTAssertEqualWithAccuracy(motion.orbit.shape.eccentricity, 0.0167086, accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.orbit.orientation.inclination, 0.02755333837, accuracy: 1e-5)
        XCTAssertEqualWithAccuracy(motion.orbit.orientation.longitudeOfAscendingNode!, 174.9 / 180 * Double(M_PI), accuracy: 1e-5)
        XCTAssertEqualWithAccuracy(motion.orbit.orientation.argumentOfPeriapsis, 288.1 / 180 * Double(M_PI), accuracy: 1e-3)
    }
    
}
