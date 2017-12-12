//
//  ObserverParserTest.swift
//  Graviton
//
//  Created by Sihao Lu on 5/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits
import CoreLocation
import MathUtil

class ObserverParserTest: XCTestCase {
    
    var mockData: String!

    func testRTSParsing() {
        let path = Bundle.init(for: ObserverParserTest.self).path(forResource: "moon_ob_rts", ofType: "result")!
        mockData = try! String(contentsOfFile: path, encoding: .utf8)
        let results = ObserverRiseTransitSetParser.default.parse(content: mockData)
        XCTAssertEqual(results.count, 20)
        let location = CLLocation(latitude: 37.7816, longitude: wrapLongitude(237.5844))
        let expected0 = RiseTransitSetInfo(naifId: 301, jd: 2440587.865972222, location: location, daylightFlag: " ", rtsFlag: "r", azimuth: 100.8787, elevation: -0.7645)
        let expected4 = RiseTransitSetInfo(naifId: 301, jd: 2440589.133333333, location: location, daylightFlag: "C", rtsFlag: "t", azimuth: 179.0547, elevation: 35.8295)
        let expected5 = RiseTransitSetInfo(naifId: 301, jd: 2440589.354861111, location: location, daylightFlag: "*", rtsFlag: "s", azimuth: 248.5043, elevation: -0.8843)
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
        result6.apparentMagnitude.value = -10.05
        result6.surfaceBrightness.value = 5.20
        result6.illuminatedPercentage = 49.244
        result6.angularDiameter = 1805.181
        result6.obLon = 352.62499
        result6.obLat = 3.49985
        result6.slLon.value = 261.84260
        result6.slLat.value = -1.40367
        result6.npRa = 270.94699
        result6.npDec = 68.05665
        result6.naifId = 301
        result6.jd = 2440587.541666667
        result6.daylightFlag = "*"
        result6.rtsFlag = ""
        result6.location = CLLocation(latitude: 37.7816, longitude: wrapLongitude(237.5844))
        assertEqual(result6, results[6])
    }

    private func assertEqual(_ lhs: CelestialBodyObserverInfo, _ rhs: CelestialBodyObserverInfo) {
        XCTAssertEqual(lhs.naifId, rhs.naifId)
        XCTAssertEqual(lhs.jd, rhs.jd)
        XCTAssertEqual(lhs.daylight, lhs.daylight)
        XCTAssertEqual(lhs.rts, rhs.rts)
        XCTAssertEqual(lhs.apparentMagnitude.value, rhs.apparentMagnitude.value)
        XCTAssertEqual(lhs.surfaceBrightness.value, rhs.surfaceBrightness.value)
        XCTAssertEqual(lhs.illuminatedPercentage, rhs.illuminatedPercentage)
        XCTAssertEqual(lhs.angularDiameter, rhs.angularDiameter)
        XCTAssertEqual(lhs.obLat, lhs.obLat)
        XCTAssertEqual(lhs.obLon, rhs.obLon)
        XCTAssertEqual(lhs.slLat.value, rhs.slLat.value)
        XCTAssertEqual(lhs.slLon.value, rhs.slLon.value)
        XCTAssertEqual(lhs.npRa, rhs.npRa)
        XCTAssertEqual(lhs.npDec, rhs.npDec)
        XCTAssertTrue(lhs.location.coordinate ~= rhs.location.coordinate)
    }

    private func assertEqual(_ lhs: RiseTransitSetInfo, _ rhs: RiseTransitSetInfo) {
        XCTAssertEqual(lhs.naifId, rhs.naifId)
        XCTAssertEqual(lhs.jd, rhs.jd)
        XCTAssertEqual(lhs.daylight, lhs.daylight)
        XCTAssertEqual(lhs.rts, rhs.rts)
        XCTAssertEqual(lhs.azimuth, rhs.azimuth)
        XCTAssertEqual(lhs.elevation, rhs.elevation)
        XCTAssertTrue(lhs.location.coordinate ~= rhs.location.coordinate)
    }
}

func ~=(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude ~= rhs.latitude && lhs.longitude ~= rhs.longitude
}
