
//
//  OrbitalMotionTest.swift
//  Graviton
//
//  Created by Sihao Lu on 4/18/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest

class OrbitalMotionTest: XCTestCase {
    func testCopying() {
        let motion = OrbitalMotionMoment(orbit: Orbit(semimajorAxis: 123, eccentricity: 0.2, inclination: 0.5, longitudeOfAscendingNode: 0.7, argumentOfPeriapsis: 1.2), gm: 1234, julianDate: 0, timeOfPeriapsisPassage: 0)
        let copiedMotion = motion.copy() as! OrbitalMotionMoment
        XCTAssertEqual(motion.orbit, copiedMotion.orbit)
        XCTAssertEqual(motion.gm, copiedMotion.gm)
        XCTAssertEqual(motion.phase, copiedMotion.phase)
    }
}
