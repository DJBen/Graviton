//
//  OrbitalMechanicsTest.swift
//  Graviton
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
import SceneKit
@testable import Orbits

class OrbitalMechanicsTest: XCTestCase {
    let sun = CelestialBody(knownBody: .sun)
    let earth: CelestialBody = CelestialBody(knownBody: .earth)
    
    var circularEquatorialLEO: Orbit!
    var ellipticalEquatorialLEO: Orbit!
    var geoSyncOrbit: Orbit!
    var polarOrbit: Orbit!
    var incliningOrbit: Orbit!
    var nonZeroLoANIncliningOrbit: Orbit!
    var fullFledgedOrbit: Orbit!
    var earthOrbitRelativeToInvariantPlane: Orbit!
    var earthOrbitRelativeToEcliptic: Orbit!
    
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
                argumentOfPeriapsis: 0
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
                inclination: Double(M_PI_2),
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
                inclination: 15 / 180 * Double(M_PI),
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
                inclination: 67 / 180 * Double(M_PI),
                longitudeOfAscendingNode: 239 / 180 * Double(M_PI),
                argumentOfPeriapsis: 0
            )
        )
        fullFledgedOrbit = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 9313_000,
                eccentricity: 0.3
            ),
            orientation: Orbit.Orientation(
                inclination: 184 / 180 * Double(M_PI),
                longitudeOfAscendingNode: 11 / 180 * Double(M_PI),
                argumentOfPeriapsis: 32 / 180 * Double(M_PI)
            )
        )
        earthOrbitRelativeToInvariantPlane = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 149_598_000_000,
                eccentricity: 0.0167086
            ),
            orientation: Orbit.Orientation(
                inclination: 0.02755333837,
                longitudeOfAscendingNode: 174.9 / 180 * Double(M_PI),
                argumentOfPeriapsis: 288.1 / 180 * Double(M_PI)
            )
        )
        earthOrbitRelativeToEcliptic = Orbit(
            shape: Orbit.ConicSection.from(
                semimajorAxis: 149_598_000_000,
                eccentricity: 0.0167086
            ),
            orientation: Orbit.Orientation(
                inclination: 23.446 / 180 * Double(M_PI),
                longitudeOfAscendingNode: 174.9 / 180 * Double(M_PI),
                argumentOfPeriapsis: 288.1 / 180 * Double(M_PI)
            )
        )
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrbitalShapeCalculation() {
        let ap: Double = 500000 + earth.radius
        let pe: Double = 250000 + earth.radius
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
        motion.setMeanAnomaly(Double(M_PI_2))
        XCTAssertEqualWithAccuracy(motion.position.x, 0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.y, 378000 + self.earth.radius, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -7800, accuracy: 300)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 10)
        motion.setMeanAnomaly(Double(M_PI))
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
        motion.setMeanAnomaly(Double(M_PI))
        
        XCTAssertEqualWithAccuracy(motion.distance, ellipticalEquatorialLEO.shape.apoapsis!, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(motion.position.x, -(435000 + self.earth.radius), accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.position.y, 0, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -7700, accuracy: 300)
        motion.setMeanAnomaly(Double(3 * M_PI_2))
        motion.setMeanAnomaly(Double(2 * M_PI))
    }
    
    func testGeosynchrounousOrbit() {
        let motion = OrbitalMotion(centralBody: earth, orbit: geoSyncOrbit, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, siderealDay, accuracy: 5)
    }
    
    func testPolarOrbit() {
        let rotationMatrix = SCNMatrix4ToMat4(SCNMatrix4MakeRotation(Double(-M_PI_2), 1, 0, 0))
        let coord = Double4(0, 10, 0, 1)
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
        motion.setMeanAnomaly(Double(M_PI_2))
        XCTAssertEqualWithAccuracy(motion.velocity.x, -7059, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 0, accuracy: 1)
        motion.setMeanAnomaly(Double(M_PI))
        XCTAssertEqualWithAccuracy(motion.velocity.x, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 0, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, -7059, accuracy: 1)
        motion.setMeanAnomaly(Double(3 * M_PI_2))
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
        motion.setMeanAnomaly(23 / 180 * Double(M_PI))
        XCTAssertEqualWithAccuracy(motion.position.x, 7364039, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.y, 3019338, accuracy: 100)
        XCTAssertEqualWithAccuracy(motion.position.z, 809029, accuracy: 10)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -2758.1, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.y, 6276.2, accuracy: 1)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 1681.7, accuracy: 1)
        motion.orbit.shape = Orbit.ConicSection.from(semimajorAxis: 8000_000, eccentricity: 0.18)
        motion.setMeanAnomaly(821 / 180 * Double(M_PI))
        XCTAssertEqualWithAccuracy(motion.meanAnomaly, 101 / 180 * Double(M_PI), accuracy: 1e-5)
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
        XCTAssertEqualWithAccuracy(motion.meanAnomaly, 500 / motion.orbitalPeriod! * Double(M_PI * 2), accuracy: 1e-4)
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
        motion.setMeanAnomaly(23 / 180 * Double(M_PI))
    }
    
    func testEarthOrbit() {
        var motion = OrbitalMotion(centralBody: sun, orbit: earthOrbitRelativeToInvariantPlane, meanAnomaly: 0)
        XCTAssertEqualWithAccuracy(motion.orbitalPeriod!, 31557995.894672215, accuracy: 1e3)
        XCTAssertEqualWithAccuracy(motion.position.x, -33094663934.4392, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(motion.position.y, 143275442683.98468, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(motion.position.z, -3852002938.4423165, accuracy: 1000)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -29510.23235850027, accuracy: 5)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -6809.489885013334, accuracy: 5)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 259.22742540323713, accuracy: 5)
        XCTAssertLessThan(motion.specificMechanicalEnergy, 0)
        motion.setMeanAnomaly(23 / 180 * Double(M_PI))
        XCTAssertEqualWithAccuracy(motion.position.x, -88165364687.77095, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(motion.position.y, 117966526597.76492, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(motion.position.z, -3022322007.0290756, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(motion.velocity.x, -24348.935884637474, accuracy: 5)
        XCTAssertEqualWithAccuracy(motion.velocity.y, -17933.232592161017, accuracy: 5)
        XCTAssertEqualWithAccuracy(motion.velocity.z, 551.9426101828388, accuracy: 5)
        
        // no inclination
        var m2 = OrbitalMotion(centralBody: sun, orbit: earthOrbitRelativeToEcliptic)
        XCTAssertEqualWithAccuracy(m2.orbitalPeriod!, 31557995.894672215, accuracy: 1e3)
        XCTAssertEqualWithAccuracy(m2.position.x, -34116152572.08163, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(m2.position.y, 131829886930.60522, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(m2.position.z, -55631971288.14792, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(m2.velocity.x, -29441.489454134317, accuracy: 5)
        XCTAssertEqualWithAccuracy(m2.velocity.y, -6039.240745105468, accuracy: 5)
        XCTAssertEqualWithAccuracy(m2.velocity.z, 3743.8529818373216, accuracy: 5)
        m2.setMeanAnomaly(Double(M_PI_2))
        XCTAssertEqualWithAccuracy(m2.position.x, -144222775250.07266, accuracy: 1e5)
        XCTAssertEqualWithAccuracy(m2.position.y, -34301604751.735603, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(m2.position.z, 20377629035.8853, accuracy: 1e4)
        XCTAssertEqualWithAccuracy(m2.velocity.x, 7388.525658101777, accuracy: 5)
        XCTAssertEqualWithAccuracy(m2.velocity.y, -26582.941501553762, accuracy: 5)
        XCTAssertEqualWithAccuracy(m2.velocity.z, 11198.323688787713, accuracy: 5)
    }
}
