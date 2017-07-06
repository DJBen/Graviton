//
//  StarTest.swift
//  Graviton
//
//  Created by Ben Lu on 2/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import StarryNight
import SpaceTime
import MathUtil

class StarTest: XCTestCase {
    func testStarQuery() {
        let starQuery = Star.magitudeLessThan(0)
        XCTAssertEqual(starQuery.count, 4)
        let s2Query = Star.hip(69673)
        XCTAssertNotNil(s2Query)
        XCTAssertEqual(s2Query!.identity.properName, "Arcturus")
        measure {
            _ = Star.magitudeLessThan(5.6)
        }
    }

    func testMassHrQueries() {
        measure {
            for i in 0..<10000 {
                _ = Star.hr(i)
            }
        }
    }

    func testClosestToStarQuery() {
        let coord = Vector3.init(equatorialCoordinate: EquatorialCoordinate.init(rightAscension: radians(hours: 5, minutes: 20), declination: radians(degrees: 10), distance: 1)).normalized()
        let star = Star.closest(to: coord, maximumMagnitude: 2.5)
        let star2 = Star.closest(to: coord, maximumMagnitude: 4)
        let star3 = Star.closest(to: coord)
        XCTAssertEqual(star!.identity.properName, "Bellatrix")
        XCTAssertEqual(star2!.identity.hrId, 1879)
        XCTAssertEqual(star3!.identity.hipId, 24971)
        let northStar = Star.closest(to: Vector3(equatorialCoordinate: EquatorialCoordinate.init(rightAscension: radians(hours: 21, minutes: 20), declination: radians(degrees: 89), distance: 1)).normalized(), maximumMagnitude: 5)
        XCTAssertEqual(northStar!.identity.properName, "Polaris")
        let northStar2 = Star.closest(to: Vector3(equatorialCoordinate: EquatorialCoordinate.init(rightAscension: radians(hours: 0, minutes: 1), declination: radians(degrees: 88), distance: 1)).normalized(), maximumMagnitude: 5)
        XCTAssertEqual(northStar2!.identity.properName, "Polaris")
        let southStar = Star.closest(to: Vector3(equatorialCoordinate: EquatorialCoordinate.init(rightAscension: radians(hours: 3, minutes: 1), declination: radians(degrees: -89), distance: 1)).normalized(), maximumMagnitude: 2)
        let southStar2 = Star.closest(to: Vector3(equatorialCoordinate: EquatorialCoordinate.init(rightAscension: radians(hours: 3, minutes: 1), declination: radians(degrees: -90), distance: 1)).normalized(), maximumMagnitude: 6)
        // Beta Carinae
        XCTAssertEqual(southStar?.identity.properName, "Miaplacidus")
        // https://en.wikipedia.org/wiki/Sigma_Octantis
        XCTAssertEqual(southStar2?.identity.hrId, 7228)
        let brightStar = Star.closest(to: coord, maximumMagnitude: 0)
        XCTAssertEqual(brightStar!.identity.properName, "Sirius")
        let brightStarNot = Star.closest(to: coord, maximumMagnitude: 0, maximumAngularDistance: radians(degrees: 20))
        XCTAssertNil(brightStarNot)
        let brightStarYes = Star.closest(to: coord, maximumMagnitude: 0, maximumAngularDistance: radians(degrees: 35))
        XCTAssertEqual(brightStarYes!.identity.properName, "Sirius")
    }
}
