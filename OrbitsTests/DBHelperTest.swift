//
//  DBHelperTest.swift
//  Graviton
//
//  Created by Sihao Lu on 1/18/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits

class DBHelperTest: XCTestCase {
    
    var helper: DBHelper!
    
    override func setUp() {
        super.setUp()
        helper = TransientDBHelper.setupDatabaseHelper()
    }
    
    func testCelestialBodyStorage() {
        let body = CelestialBody(naifId: 12345, name: "Test", gravParam: 1.1, radius: 2.2, rotationPeriod: 3.3, obliquity: 4.4, centerBodyNaifId: 10, hillSphereRadRp: 5.5)
        helper.saveCelestialBody(body, shouldSaveMotion: false)
        let loaded = helper.loadCelestialBody(withNaifId: 12345)
        XCTAssertNotNil(loaded)
        deepEqual(loaded!, body)
        
        let known = CelestialBody(naifId: 399, gravParam: 828, radius: 2344.3, rotationPeriod: 12.3, obliquity: 4111.4, centerBodyNaifId: 10, hillSphereRadRp: 590.3773)
        helper.saveCelestialBody(known, shouldSaveMotion: false)
        let loaded2 = helper.loadCelestialBody(withNaifId: 399)
        XCTAssertNotNil(loaded2)
        XCTAssertEqual(loaded2?.name, "Earth")
        deepEqual(loaded2!, known)
    }
    
    private func deepEqual(_ c1: CelestialBody, _ c2: CelestialBody) {
        XCTAssertEqual(c1.naifId, c2.naifId)
        XCTAssertEqual(c1.gravParam, c2.gravParam)
        XCTAssertEqual(c1.radius, c2.radius)
        XCTAssertEqual(c1.rotationPeriod, c2.rotationPeriod)
        XCTAssertEqual(c1.obliquity, c2.obliquity)
        XCTAssertEqual(c1.centerBody, c2.centerBody)
    }
}
