//
//  SiderealTimeTest.swift
//  Graviton
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
import CoreLocation

class SiderealTimeTest: XCTestCase {
    
    var date: Date!
    
    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 2017, month: 1, day: 3, hour: 3, minute: 29)
        date = calendar.date(from: components)!
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSiderealTime() {
        XCTAssertEqualWithAccuracy(date.julianDate, 2457756.645138889, accuracy: 1e-5)
        XCTAssertEqualWithAccuracy(date.greenwichMeanSiderealTime, 10 + 20 / 60.0 + 47.358 / 3600.0, accuracy: 1e-3)
        // coordinate of my hometown
        let coord = CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7969)
        XCTAssertEqualWithAccuracy(date.localSiderealTime(coordinate: coord), 18 + 15 / 60.0 + 58.614 / 3600.0, accuracy: 1e-3)
    }
    
}
