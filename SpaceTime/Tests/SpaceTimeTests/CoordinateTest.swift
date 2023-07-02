//
//  CoordinateTest.swift
//  Graviton
//
//  Created by Sihao Lu on 1/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import SpaceTime
import CoreLocation
import MathUtil

class CoordinateTest: XCTestCase {

    func testEquatorialToCartesianConversion() {
        let sph = EquatorialCoordinate(
            rightAscension: HourAngle(14.4966),
            declination: DegreeAngle(-62.681),
            distance: 1.29)
        let converted = Vector3.init(equatorialCoordinate: sph)
        XCTAssertEqual(converted.x, -0.4700, accuracy: 1e-3)
        XCTAssertEqual(converted.y, -0.3600, accuracy: 1e-3)
        XCTAssertEqual(converted.z, -1.1461, accuracy: 1e-3)
    }

    func testNearEpochEquatorialToHorizontalConversion() {
        let sph = EquatorialCoordinate(
            rightAscension: HourAngle(hour: 11, minute: 3, second: 43),
            declination: DegreeAngle(degree: 61, minute: 45, second: 3.72),
            distance: 1)
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(abbreviation: "PST"), year: 2000, month: 1, day: 1, hour: 5)
        let julianDay = JulianDay(date: calendar.date(from: components)!)
        let location = CLLocation(latitude: CLLocationDegrees(degrees(degrees: 37, minutes: 46, seconds: 51)), longitude: CLLocationDegrees(-degrees(degrees: 122, minutes: 24, seconds: 47)))
        let obs = ObserverLocationTime(location: location, timestamp: julianDay)
        let horizontal = HorizontalCoordinate(equatorialCoordinate: sph, observerInfo: obs)
        XCTAssertEqual(horizontal.azimuth.value, 351.79, accuracy: 1e-2)
        XCTAssertEqual(horizontal.altitude.value, 65.63, accuracy: 1e-2)
    }

    func testEquatorialToHorizontalConversion() {
        // at 2017.1.6, 1:31 AM PT
        // Dubhe is at RA 11h 03m 43s, DEC +61° 45' 3.72''
        // Azm +32° 41' 21.16'', Alt 55° 55' 30.18''
        // Current location 37° 46' 51'' N, 122° 24' 47'' W
        let sph = EquatorialCoordinate(
            rightAscension: HourAngle(hour: 11, minute: 3, second: 43),
            declination: DegreeAngle(degree: 61, minute: 45, second: 3.72),
            distance: 1)
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(abbreviation: "PST"), year: 2017, month: 1, day: 6, hour: 1, minute: 31, second: 30)
        let date = JulianDay(date: calendar.date(from: components)!)
        let obs = ObserverLocationTime(location:
            CLLocation(
                latitude: CLLocationDegrees(degrees(degrees: 37, minutes: 46, seconds: 51)),
                longitude: CLLocationDegrees(-degrees(degrees: 122, minutes: 24, seconds: 47))
            ),
            timestamp: date
        )
        let horizontal = HorizontalCoordinate(equatorialCoordinate: sph, observerInfo: obs)
        XCTAssertEqual(horizontal.azimuth.wrappedValue, 32.43, accuracy: 1e-2)
        XCTAssertEqual(horizontal.altitude.wrappedValue, 56.01, accuracy: 1e-2)
    }

    func testSouthernEquatorialToHorizontalConversion() {
        // Sirius
        let sph = EquatorialCoordinate(
            rightAscension: HourAngle(hour: 6, minute: 45, second: 8),
            declination: -DegreeAngle(degree: 16, minute: 42, second: 58.02),
            distance: 1)
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(abbreviation: "PST"), year: 2017, month: 1, day: 6, hour: 2, minute: 27)
        let date = JulianDay(date: calendar.date(from: components)!)
        let obs = ObserverLocationTime(location:
            CLLocation(
                latitude: CLLocationDegrees(-33.9249),
                longitude: CLLocationDegrees(18.4241)
            ),
            timestamp: date
        )
        let horizontal = HorizontalCoordinate(equatorialCoordinate: sph, observerInfo: obs)
        XCTAssertEqual(horizontal.azimuth.wrappedValue, 179.90, accuracy: 1e-2)
        XCTAssertEqual(horizontal.altitude.wrappedValue, -39.36, accuracy: 1e-2)
    }

    func testEclipticalToEquatorialConversion() {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 1992, month: 4, day: 12, hour: 0, minute: 0, second: 0)
        let julianDay = JulianDay(date: calendar.date(from: components)!)
        XCTAssertEqual(EclipticUtil.trueObliquityOfEcliptic(julianDay: julianDay).value, 23.440636, accuracy: 1e-5)
        let moon = EclipticCoordinate(longitude: DegreeAngle(degree: 133, minute: 10, second: 2), latitude: -DegreeAngle(degree: 3, minute: 13, second: 45), distance: 1, julianDay: julianDay)
        let equat = EquatorialCoordinate(EclipticCoordinate: moon, julianDay: julianDay)
        XCTAssertEqual(equat.rightAscension.wrappedValue, HourAngle(hour: 8, minute: 58, second: 45.2).wrappedValue, accuracy: 1e-5)
        XCTAssertEqual(equat.declination.wrappedValue, DegreeAngle(degree: 13, minute: 46, second: 6).wrappedValue, accuracy: 1e-5)
    }

    func testEclipticUtil() {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 1987, month: 4, day: 10, hour: 0, minute: 0, second: 0)
        let julianDay = JulianDay(date: calendar.date(from: components)!)
        XCTAssertEqual(EclipticUtil.meanObliquityOfEcliptic(julianDay: julianDay).value, DegreeAngle(degree: 23, minute: 26, second: 27.407).wrappedValue, accuracy: 1e-5)
        XCTAssertEqual(EclipticUtil.trueObliquityOfEcliptic(julianDay: julianDay).value, DegreeAngle(degree: 23, minute: 26, second: 36.850).wrappedValue, accuracy: 1e-5)
    }

    func testNutation() {
        let julianDay = JulianDay(2446895.5)
        let (D, M, M´, F) = (EclipticUtil.meanElongationOfTheMoonFromTheSum(julianDay: julianDay), EclipticUtil.meanAnomalyOfTheSun(julianDay: julianDay), EclipticUtil.meanAnomalyOfTheMoon(julianDay: julianDay), EclipticUtil.moonArgumentOfLatitude(julianDay: julianDay))
        let Ω = EclipticUtil.loANOfMoonMeanOrbitOnEcliptic(julianDay: julianDay)
        XCTAssertEqual(D.wrappedValue, 136.9623, accuracy: 1e-4)
        XCTAssertEqual(M.wrappedValue, 94.9792, accuracy: 1e-4)
        XCTAssertEqual(M´.wrappedValue, 229.2784, accuracy: 1e-4)
        XCTAssertEqual(F.wrappedValue, 143.4079, accuracy: 1e-4)
        XCTAssertEqual(Ω.wrappedValue, 11.2531, accuracy: 1e-4)
        let (Δψ, Δε) = EclipticUtil.longitudeAndObliquityNutation(julianDay: julianDay)
        XCTAssertEqual(Δψ.inSeconds, -3.788, accuracy: 1e-3)
        XCTAssertEqual(Δε.inSeconds, 9.443, accuracy: 1e-3)
    }

    func testEquatorialToEclipticalConversion() {
        let pollux = EquatorialCoordinate(rightAscension: HourAngle(hour: 7, minute: 45, second: 18.946), declination: DegreeAngle(degree: 28, minute: 1, second: 34.26), distance: 1)
        let eclip = EclipticCoordinate(equatorialCoordinate: pollux, julianDay: JulianDay.J2000)
        XCTAssertEqual(eclip.longitude.wrappedValue, 113.21563, accuracy: 1e-5)
        XCTAssertEqual(eclip.latitude.wrappedValue, 6.68417, accuracy: 1e-5)
    }

    func testAngularSeparation() {
        let merak = EquatorialCoordinate(rightAscension: 11.0306, declination: 56.3825, distance: 1)
        let dubhe = EquatorialCoordinate(rightAscension: 11.0622, declination: 61.7511, distance: 1)
        XCTAssertEqual(merak.angularSeparation(from: dubhe).wrappedValue, 5.37413, accuracy: 1e-4)
    }
}
