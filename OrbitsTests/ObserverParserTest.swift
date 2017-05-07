//
//  ObserverParserTest.swift
//  Graviton
//
//  Created by Sihao Lu on 5/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits

class ObserverParserTest: XCTestCase {
    
    var mockData: String!

    func testRTSParsing() {
        let path = Bundle.init(for: ObserverParserTest.self).path(forResource: "moon_ob_rts", ofType: "result")!
        mockData = try! String(contentsOfFile: path, encoding: .utf8)
        let results = ObserverRiseTransitSetParser.default.parse(content: mockData)
        XCTAssertEqual(results.count, 20)
        let expected0 = RiseTransitSetInfo(naifId: 301, jd: 2440587.865972222, daylightFlag: " ", rtsFlag: "r", azimuth: 100.8787, elevation: -0.7645)
        let expected4 = RiseTransitSetInfo(naifId: 301, jd: 2440589.133333333, daylightFlag: "C", rtsFlag: "t", azimuth: 179.0547, elevation: 35.8295)
        let expected5 = RiseTransitSetInfo(naifId: 301, jd: 2440589.354861111, daylightFlag: "*", rtsFlag: "s", azimuth: 248.5043, elevation: -0.8843)
        assertEqual(results[0], expected0)
        assertEqual(results[4], expected4)
        assertEqual(results[5], expected5)
    }

    func testObserverParsing() {
        let path = Bundle.init(for: ObserverParserTest.self).path(forResource: "moon_ob", ofType: "result")!
        mockData = try! String(contentsOfFile: path, encoding: .utf8)
        let results = ObserverEphemerisParser.default.parse(content: mockData)
        XCTAssertEqual(results.count, 4321)
        let result6 = CelestialBodyObserverInfo()
        result6.apparentMagnitude = -10.05
        result6.surfaceBrightness = 5.20
        result6.illuminatedPercentage = 49.244
        result6.angularDiameter = 1805.181
        result6.obLon = 352.62499
        result6.obLat = 3.49985
        result6.slLon = 261.84260
        result6.slLat = -1.40367
        result6.npRa = 270.94699
        result6.npDec = 68.05665
        result6.naifId = 301
        result6.jd = 2440587.541666667
        result6.daylightFlag = "*"
        result6.rtsFlag = ""
        assertEqual(result6, results[6])
    }

    private func assertEqual(_ lhs: CelestialBodyObserverInfo, _ rhs: CelestialBodyObserverInfo) {
        XCTAssertEqual(lhs.naifId, rhs.naifId)
        XCTAssertEqual(lhs.jd, rhs.jd)
        XCTAssertEqual(lhs.daylight, lhs.daylight)
        XCTAssertEqual(lhs.rts, rhs.rts)
        XCTAssertEqual(lhs.apparentMagnitude, rhs.apparentMagnitude)
        XCTAssertEqual(lhs.surfaceBrightness, rhs.surfaceBrightness)
        XCTAssertEqual(lhs.illuminatedPercentage, rhs.illuminatedPercentage)
        XCTAssertEqual(lhs.angularDiameter, rhs.angularDiameter)
        XCTAssertEqual(lhs.obLat, lhs.obLat)
        XCTAssertEqual(lhs.obLon, rhs.obLon)
        XCTAssertEqual(lhs.slLat, rhs.slLat)
        XCTAssertEqual(lhs.slLon, rhs.slLon)
        XCTAssertEqual(lhs.npRa, rhs.npRa)
        XCTAssertEqual(lhs.npDec, rhs.npDec)
    }

    private func assertEqual(_ lhs: RiseTransitSetInfo, _ rhs: RiseTransitSetInfo) {
        XCTAssertEqual(lhs.naifId, rhs.naifId)
        XCTAssertEqual(lhs.jd, rhs.jd)
        XCTAssertEqual(lhs.daylight, lhs.daylight)
        XCTAssertEqual(lhs.rts, rhs.rts)
        XCTAssertEqual(lhs.azimuth, rhs.azimuth)
        XCTAssertEqual(lhs.elevation, rhs.elevation)
    }
}
