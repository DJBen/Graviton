//
//  ConstellationTest.swift
//  Graviton
//
//  Created by Sihao Lu on 3/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import StarryNight
import SpaceTime
import MathUtil

class ConstellationTest: XCTestCase {
    func testConstellationQuery() {
        let iauQuery = Constellation.iau("Tau")
        XCTAssertNotNil(iauQuery)
        let nameQuery = Constellation.named("Orion")
        XCTAssertNotNil(nameQuery)
    }
    
    func testPointToConstellation() {
        let coord = EquatorialCoordinate.init(rightAscension: 1.547, declination: 0.129, distance: 1)
        XCTAssertEqual(coord.constellation, Constellation.iau("Ori"))
        for star in Star.magitudeLessThan(2) {
            let coord = EquatorialCoordinate(cartesian: star.physicalInfo.coordinate)
            XCTAssertEqual(coord.constellation, star.identity.constellation, "Star \(star.identity.hrId!) @ coordinate \(star.physicalInfo.coordinate) should be in \(star.identity.constellation), but calculated at \(coord.constellation)")
        }

    }
}
