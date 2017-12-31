//
//  YinYangTests.swift
//  YinYangTests
//
//  Created by Sihao Lu on 12/26/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
import SpaceTime
@testable import YinYang

class YinYangTests: XCTestCase {

    private let accuracy = 1e-6

    func testLunaUtil() {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 1992, month: 4, day: 12, hour: 0, minute: 0, second: 0)
        let julianDay = JulianDay(date: calendar.date(from: components)!)
        let L´ = LunaUtil.moonMeanLongitude(forJulianDay: julianDay)
        let D = LunaUtil.moonMeanElongation(forJulianDay: julianDay)
        let M = LunaUtil.sunMeanAnomaly(forJulianDay: julianDay)
        let M´ = LunaUtil.moonMeanAnomaly(forJulianDay: julianDay)
        let F = LunaUtil.moonLatitudeArgument(forJulianDay: julianDay)
        XCTAssertEqual(L´.wrappedValue, 134.290186, accuracy: accuracy)
        XCTAssertEqual(D.wrappedValue, 113.842309, accuracy: accuracy)
        XCTAssertEqual(M.wrappedValue, 97.643514, accuracy: accuracy)
        XCTAssertEqual(M´.wrappedValue, 5.150839, accuracy: accuracy)
        XCTAssertEqual(F.wrappedValue, 219.889726, accuracy: accuracy)

        let coord = LunaUtil.moonEclipticCoordinate(forJulianDay: julianDay)
        XCTAssertEqual(coord.longitude.wrappedValue, 133.162659, accuracy: accuracy)
        XCTAssertEqual(coord.latitude.wrappedValue, -3.229127, accuracy: accuracy)
        XCTAssertEqual(coord.distance, 368409.7, accuracy: 1e-1)
    }
}
