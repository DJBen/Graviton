//
//  JulianDateTest.swift
//  Graviton
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
@testable import Graviton

class JulianDateTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDateToJulianDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 2000, month: 1, day: 1, hour: 12)
        let date = calendar.date(from: components)!
        let JD = JulianDate(date: date)
        XCTAssertEqualWithAccuracy(JD.value, JD.J2000, accuracy: 1e-6)
    }
    
    func testJulianDateToDate() {
        let JD = 2457660.5
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = JulianDate(value: JD).date
        let component = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        // A.D. 2016-Sep-29
        XCTAssertEqual(component.year, 2016)
        XCTAssertEqual(component.month, 9)
        XCTAssertEqual(component.day, 29)
        XCTAssertEqual(component.hour, 0)
        XCTAssertEqual(component.minute, 0)
        XCTAssertEqual(component.second, 0)
    }
}
