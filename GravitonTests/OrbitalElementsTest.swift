//
//  OrbitalMechanicsTest.swift
//  Graviton
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
import SceneKit
@testable import Graviton

class OrbitalMechanicsTest: XCTestCase {
    
    lazy var earth: CelestialBody = CelestialBody(knownBody: .earth)
    
    var circularEquatorialLEO: Orbit!
    var ellipticalEquatorialLEO: Orbit!
    var geoSyncOrbit: Orbit!
    var polarOrbit: Orbit!
    var incliningOrbit: Orbit!
    var nonZeroLoANIncliningOrbit: Orbit!
    var fullFledgedOrbit: Orbit!
    
    override func setUp() {
        super.setUp()
        circularEquatorialLEO = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 378_000 + self.earth.radius,
                eccentricity: 0
            ),
            orientation: Orbit.Orientation(
                inclination: 0,
                longitudeOfAscendingNode: nil,
                argumentOfPeriapsis: nil
            )
        )
        ellipticalEquatorialLEO = Orbit(
            shape: Orbit.ConicSection.from(
                apoapsis: 435_000 + self.earth.radius,
                periapsis: 330_000 + self.earth.radius
            ),
            orientation: Orbit.Orientation(
                inclination: 0,
                longitudeOfAscendingNode: nil,
                argumentOfPeriapsis: 0
            )
        )
        geoSyncOrbit = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 35786_000 + self.earth.radius,
                eccentricity: 0
            ),
            orientation: Orbit.Orientation(
                inclination: 0,
                longitudeOfAscendingNode: nil,
                argumentOfPeriapsis: 0
            )
        )
        polarOrbit = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 8000_000,
                eccentricity: 0
            ),
            orientation: Orbit.Orientation(
                inclination: Float(M_PI_2),
                longitudeOfAscendingNode: 0,
                argumentOfPeriapsis: 0
            )
        )
        incliningOrbit = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 8000_000,
                eccentricity: 0
            ),
            orientation: Orbit.Orientation(
                inclination: 15 / 180 * Float(M_PI),
                longitudeOfAscendingNode: 0,
                argumentOfPeriapsis: 0
            )
        )
        nonZeroLoANIncliningOrbit = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 12345_678,
                eccentricity: 0.662
            ),
            orientation: Orbit.Orientation(
                inclination: 67 / 180 * Float(M_PI),
                longitudeOfAscendingNode: 239 / 180 * Float(M_PI),
                argumentOfPeriapsis: 0
            )
        )
        fullFledgedOrbit = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 9313_000,
                eccentricity: 0.3
            ),
            orientation: Orbit.Orientation(
                inclination: 184 / 180 * Float(M_PI),
                longitudeOfAscendingNode: 11 / 180 * Float(M_PI),
                argumentOfPeriapsis: 32 / 180 * Float(M_PI)
            )
        )
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
    
    func testPolarOrbit() {
        let rotationMatrix = SCNMatrix4ToMat4(SCNMatrix4MakeRotation(Float(-M_PI_2), 1, 0, 0))
        let coord = float4(0, 10, 0, 1)
        let result = matrix_multiply(rotationMatrix, coord)
        XCTAssertEqualWithAccuracy(result.z, -10, accuracy: 1e-5)
        var motion = OrbitalMotion(centralBody: earth, orbit: polarOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, 7121.0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.position.x, 8000_000, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, 0, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 7059, accuracy: 1)
        motion.setMeanAnomaly(Float(M_PI_2))
        XCTAssertEqualWithAccuracy(motion.velocity.x, -7059, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 0, accuracy: 1)
        motion.setMeanAnomaly(Float(M_PI))
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, -7059, accuracy: 1)
        motion.setMeanAnomaly(Float(3 * M_PI_2))
        XCTAssertEqualWithAccuracy(motion.velocity.x, 7059, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 0, accuracy: 1)
    }
    
    func testIncliningOrbit() {
        var motion = OrbitalMotion(centralBody: earth, orbit: incliningOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.position.x, 8000_000, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, 0, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 6818.22, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 1826.9, accuracy: 1)
        motion.setMeanAnomaly(23 / 180 * Float(M_PI))
        XCTAssertEqualWithAccuracy(motion.position.x, 7364039, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, 3019338, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, 809029, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -2758.1, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 6276.2, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 1681.7, accuracy: 1)
        motion.orbit.shape = Orbit.ConicSection.from(semimajorAxis: 8000_000, eccentricity: 0.18)
        motion.setMeanAnomaly(821 / 180 * Float(M_PI))
        XCTAssertEqualWithAccuracy(motion.meanAnomaly, 101 / 180 * Float(M_PI), accuracy: 1e-5)
        XCTAssertEqualWithAccuracy(motion.position.x, -4261345.2, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, 7112803.5, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, 1905870.0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -6211, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -2224, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, -596, accuracy: 1)
    }
    
    func testNonZeroLoANIncliningOrbit() {
        var motion = OrbitalMotion(centralBody: earth, orbit: nonZeroLoANIncliningOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, 13651.5, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.x, -2149171, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, -3576821, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 4220, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -2536, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 11598, accuracy: 1)
        XCTAssertLessThan(motion.specificMechanicalEnergy, 0)
        motion.setTime(500)
        // mean anomaly becomes 0.2301281877
        XCTAssertEqualWithAccuracy(motion.info.timeFromPeriapsis, 500, accuracy: 1e-5)
        XCTAssertEqualWithAccuracy(motion.meanAnomaly, 500 / motion.orbitalPeriod! * Float(M_PI * 2), accuracy: 1e-4)
        XCTAssertEqualWithAccuracy(motion.position.x, 764390, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, -2741302, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, 4869748.73, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 6223.7, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 4555, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 7039.9, accuracy: 1)
    }
    
    func testFullFledgedOrbit() {
        var motion = OrbitalMotion(centralBody: earth, orbit: fullFledgedOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, 8944.21, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.x, 6084498, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, -2327975, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, -240980.48, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -3198.6, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -8305, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, -527.418, accuracy: 1)
        XCTAssertLessThan(motion.specificMechanicalEnergy, 0)
        motion.setMeanAnomaly(23 / 180 * Float(M_PI))
    }
    
}
