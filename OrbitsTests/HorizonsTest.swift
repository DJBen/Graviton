//
//  HorizonsTest.swift
//  StarCatalog
//
//  Created by Ben Lu on 12/20/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits
import SpaceTime
import CoreLocation

class HorizonsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEphemerisUrlConstruction() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MMM-dd HH:mm"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        let d1970 = Date(timeIntervalSince1970: 3282994)
        let precise1970 = Date(timeIntervalSince1970: 0)
        let timeString = f.string(from: precise1970)
        let timeString1hLater = f.string(from: Date(timeIntervalSince1970: 1800))
        let urls = (1...9).map { String($0) }.map { $0 + "99" }.map { "\(Horizons.batchUrl)?CENTER='10'&COMMAND='\($0)'&CSV_FORMAT='YES'&MAKE_EPHEM='YES'&START_TIME='\(timeString)'&STEP_SIZE='1'&STOP_TIME='\(timeString1hLater)'&TABLE_TYPE='Elements'&batch='1'".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlAllowedCharacterSet)! }
        let queryStrings = HorizonsQuery.planetQuery(date: d1970).map { $0.url.absoluteString }
        XCTAssertEqual(queryStrings.sorted(), urls.sorted())
    }

    func testObserverUrlConstruction() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MMM-dd HH:mm"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        var query = HorizonsQuery.observerQuery(target: Naif.moon(.luna), site: ObserverSite.sanFrancisco, startTime: Date(timeIntervalSince1970: 0), stopTime: Date(timeIntervalSince1970: 86400 * 30))
        query.stepSize = .minute(10)
        let queryString = query.url.absoluteString
        let expected = "http://ssd.jpl.nasa.gov/horizons_batch.cgi?ANG_FORMAT='DEG'&CENTER='coord@399'&COMMAND='301'&CSV_FORMAT='YES'&OBJ_PAGE='YES'&QUANTITIES='1,9,10,13,14,15,32'&REF_SYSTEM='J2000'&R_T_S_ONLY='NO'&SITE_COORD='-122.4156,37.7816,12.0'&START_TIME='1970-Jan-01 00:00'&STEP_SIZE='10m'&STOP_TIME='1970-Jan-31 00:00'&TABLE_TYPE='Observer'&batch='1'".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlAllowedCharacterSet)!
        XCTAssertEqual(queryString, expected)
    }

    func testRtsObserverUrlConstruction() {
        let queries = HorizonsQuery.rtsQueries(site: ObserverSite.sanFrancisco, date: Date(timeIntervalSince1970: 0))
        let queryStrings = queries.map { $0.url.absoluteString }
        let expected = ["http://ssd.jpl.nasa.gov/horizons_batch.cgi?ANG_FORMAT='DEG'&CENTER='coord@399'&COMMAND='301'&CSV_FORMAT='YES'&OBJ_PAGE='NO'&QUANTITIES='1'&REF_SYSTEM='J2000'&R_T_S_ONLY='NO'&SITE_COORD='-122.4156,37.7816,12.0'&START_TIME='1970-Jan-01 00:00'&STEP_SIZE='1m'&STOP_TIME='1970-Jan-08 00:00'&TABLE_TYPE='Observer'&batch='1'"].map { $0.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlAllowedCharacterSet)! }
        XCTAssertEqual(queryStrings.sorted(), expected.sorted())
    }

    func testCelestialBodyMerge() {
        func bodyWithId(_ id: Int, jd: Double) -> CelestialBody {
            let o = Orbit(semimajorAxis: 23.2, eccentricity: 43.4, inclination: 45.6, longitudeOfAscendingNode: 73.8, argumentOfPeriapsis: 19.0)
            let motion = OrbitalMotionMoment(orbit: o, gm: 10, julianDate: JulianDate(jd), timeOfPeriapsisPassage: JulianDate.J2000 + 1)
            let c = CelestialBody(naifId: id, name: "stub", gravParam: 0, radius: 0)
            c.motion = motion
            return c
        }
        let bodies1 = Set<CelestialBody>([
            bodyWithId(50001, jd: JulianDate.J2000.value),
            bodyWithId(40000, jd: JulianDate.J2000.value - 10000),
            bodyWithId(50009, jd: JulianDate.J2000.value + 10000)
        ])
        let bodies2 = Set<CelestialBody>([
            bodyWithId(50001, jd: JulianDate.J2000.value + 1000),
            bodyWithId(50009, jd: JulianDate.J2000.value + 9000),
            bodyWithId(34567, jd: 12)
        ])
        let merged = Horizons.shared.mergeCelestialBodies(bodies1, bodies2, refTime: JulianDate(JulianDate.J2000.value - 100).date)
        let expected = Set<CelestialBody>([
            bodyWithId(50001, jd: JulianDate.J2000.value),
            bodyWithId(50009, jd: JulianDate.J2000.value + 9000),
            bodyWithId(40000, jd: JulianDate.J2000.value - 10000),
            bodyWithId(34567, jd: 12)
        ])
        XCTAssertEqual(merged, expected)
    }

    func testObserverFieldSerialization() {
        let field = HorizonsQuery.ObserverField.geocentricObserverFields
        XCTAssertEqual(field.quantities, "1,9,10,13,14,15,32")
    }
}

fileprivate extension CharacterSet {
    static var urlAllowedCharacterSet: CharacterSet {
        return CharacterSet.urlPathAllowed.union(.urlHostAllowed).union(.urlQueryAllowed)
    }
}

fileprivate extension ObserverSite {
    static var sanFrancisco: ObserverSite {
        return ObserverSite.init(naif: Naif.majorBody(.earth), location: CLLocation(coordinate: CLLocationCoordinate2D.init(latitude: 37.7816, longitude: -122.4156), altitude: 12, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date()))
    }
}
