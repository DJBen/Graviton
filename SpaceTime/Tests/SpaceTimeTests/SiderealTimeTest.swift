//
//  SiderealTimeTest.swift
//  Graviton
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
import CoreLocation
@testable import SpaceTime

class SiderealTimeTest: XCTestCase {

    var locationTime: ObserverLocationTime!
    var locationTime2: ObserverLocationTime!
    var locationTime3: ObserverLocationTime!

    var date: JulianDay {
        return locationTime.timestamp
    }

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 2017 , month: 1, day: 3, hour: 3, minute: 29)
        let date = JulianDay(date: calendar.date(from: components)!)
        // coordinate of my hometown
        locationTime = ObserverLocationTime(location: CLLocation(latitude: 32.0603, longitude: 118.7969), timestamp: date)
        locationTime2 = ObserverLocationTime(location: CLLocation(latitude: 37.704215, longitude: -122.462358), timestamp: date)
        locationTime3 = ObserverLocationTime(location: CLLocation(latitude: 42, longitude: 9.32), timestamp: date)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSiderealTime() {
        let sidTime = SiderealTime(julianDay: date)
        let localSidTime = SiderealTime(observerLocationTime: locationTime)
        XCTAssertEqual(date.value, 2457756.645138889, accuracy: 1e-5)
        XCTAssertEqual(sidTime.hourAngle.wrappedValue, 10 + 20 / 60.0 + 47.358 / 3600.0, accuracy: 1e-3)
        let hour: Double = (18 + 15 / 60.0 + 58.614 / 3600.0)
        XCTAssertEqual(localSidTime.hourAngle.wrappedValue, hour, accuracy: 1e-3)
        let sidTime2 = SiderealTime(julianDay: 2457756.845138889)
        XCTAssertEqual(sidTime2.hourAngle.wrappedValue, 15.15996, accuracy: 1e-3)
    }

    func testSiderealTimeOffset() {
        let localSidTime = SiderealTime(observerLocationTime: locationTime)
        let localSidTime2 = SiderealTime(observerLocationTime: locationTime2)
        let localSidTime3 = SiderealTime(observerLocationTime: locationTime3)

        XCTAssertEqual(localSidTime.offsetFromGreenwichMeanSiderealTime.hourAngle.wrappedValue, 118.7969 / 15, accuracy: 1e-5)
        XCTAssertEqual(String(describing: localSidTime.offsetFromGreenwichMeanSiderealTime), "+07:55:11")
        XCTAssertEqual(localSidTime2.offsetFromGreenwichMeanSiderealTime.hourAngle.wrappedValue, -122.462358 / 15, accuracy: 1e-5)
        XCTAssertEqual(String(describing: localSidTime2.offsetFromGreenwichMeanSiderealTime), "-08:09:50")
        XCTAssertEqual(localSidTime3.offsetFromGreenwichMeanSiderealTime.hourAngle.wrappedValue, 9.32 / 15, accuracy: 1e-5)
        XCTAssertEqual(String(describing: localSidTime3.offsetFromGreenwichMeanSiderealTime), "+00:37:16")
    }
}
