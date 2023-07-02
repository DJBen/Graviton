//
//  MathUtilTests.swift
//  MathUtil
//
//  Created by Sihao Lu on 7/21/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import XCTest
@testable import MathUtil

class MathUtilTests: XCTestCase {
    
    func testAngleConversion() {
        XCTAssertEqual(degrees(radians: Double.pi / 2), 90)
        XCTAssertEqual(radians(degrees: 30), 30 * Double.pi / 180)
        XCTAssertEqual(radians(degrees: degrees(radians: 43.32)), 43.32)
    }

    func testHourConversion() {
        XCTAssertEqual(radians(hours: 6, minutes: 45, seconds: 9), radians(degrees: 101.2875), accuracy: 1e-3)
    }

    func testInterpolation() {
        let interp = Easing(startValue: 2.1, endValue: 7.5)
        XCTAssertEqual(interp.value(at: 0.85), 2.1 + (7.5 - 2.1) * 0.85)
    }

    func testHmsConversion() {
        let hms = HourMinuteSecond(value: 101.2875)
        hms.decimalNumberFormatter = NumberFormatter()
        XCTAssertEqual(hms.sign, 1)
        XCTAssertEqual(hms.values[0], 6)
        XCTAssertEqual(hms.values[1], 45)
        XCTAssertEqual(hms.values[2], 9, accuracy: 0.5)
        XCTAssertEqual(hms.value, 101.2875, accuracy: 1e-3)
        XCTAssertEqual(hms.description, "6h 45m 9s")
    }

    func testDmsConversion() {
        let dms = DegreeMinuteSecond(value: -26.432002)
        dms.decimalNumberFormatter = NumberFormatter()
        XCTAssertEqual(dms.sign, -1)
        XCTAssertEqual(dms.values[0], 26)
        XCTAssertEqual(dms.values[1], 25)
        XCTAssertEqual(dms.values[2], 55.2094, accuracy: 1e-2)
        XCTAssertEqual(dms.value, -26.432002, accuracy: 1e-3)
        XCTAssertEqual(dms.description, "-26° 25′ 55″")
    }

    func testNearZeroDmsConversion() {
        let dms = DegreeMinuteSecond(value: -0.324)
        dms.decimalNumberFormatter = NumberFormatter()
        XCTAssertEqual(dms.sign, -1)
        XCTAssertEqual(dms.values[0], 0)
        XCTAssertEqual(dms.values[1], 19)
        XCTAssertEqual(dms.values[2], 26.4, accuracy: 1e-2)
        XCTAssertEqual(dms.value, -0.324, accuracy: 1e-3)
        XCTAssertEqual(dms.description, "-0° 19′ 26″")
    }
}
