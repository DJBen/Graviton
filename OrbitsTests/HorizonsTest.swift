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

class HorizonsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUrlConstruction() {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MMM-dd HH:mm"

        f.timeZone = TimeZone(secondsFromGMT: 0)
        let d1970 = Date(timeIntervalSince1970: 3282994)
        let precise1970 = Date(timeIntervalSince1970: 0)
        let timeString = f.string(from: precise1970)
        let timeString1hLater = f.string(from: Date(timeIntervalSince1970: 1800))
        let urls = (1...8).map { String($0) }.map { $0 + "99" }.map { "\(Horizons.batchUrl)?MAKE_EPHEM='YES'&CENTER='10'&TABLE_TYPE='Elements'&COMMAND='\($0)'&STOP_TIME='\(timeString1hLater)'&CSV_FORMAT='YES'&batch='1'&START_TIME='\(timeString)'&STEP_SIZE='1'".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlAllowedCharacterSet)! }
        let queryStrings = HorizonsQuery.planetQuery(date: d1970).map { $0.url.absoluteString }
        XCTAssertEqual(queryStrings.sorted(), urls.sorted())
    }
    
    func testCelestialBodyMerge() {
        func bodyWithId(_ id: Int, jd: Double) -> CelestialBody {
            let o = Orbit(semimajorAxis: 23.2, eccentricity: 43.4, inclination: 45.6, longitudeOfAscendingNode: 73.8, argumentOfPeriapsis: 19.0)
            let motion = OrbitalMotionMoment(orbit: o, gm: 10, julianDate: jd, timeOfPeriapsisPassage: JulianDate.J2000 + 1)
            let c = CelestialBody(naifId: id, name: "stub", gravParam: 0, radius: 0)
            c.motion = motion
            return c
        }
        let bodies1 = Set<CelestialBody>([
            bodyWithId(50001, jd: JulianDate.J2000),
            bodyWithId(40000, jd: JulianDate.J2000 - 10000),
            bodyWithId(50009, jd: JulianDate.J2000 + 10000)
        ])
        let bodies2 = Set<CelestialBody>([
            bodyWithId(50001, jd: JulianDate.J2000 + 1000),
            bodyWithId(50009, jd: JulianDate.J2000 + 9000),
            bodyWithId(34567, jd: 12)
        ])
        let merged = Horizons.shared.mergeCelestialBodies(bodies1, bodies2, refTime: JulianDate(value: JulianDate.J2000 - 100).date)
        let expected = Set<CelestialBody>([
            bodyWithId(50001, jd: JulianDate.J2000),
            bodyWithId(50009, jd: JulianDate.J2000 + 9000),
            bodyWithId(40000, jd: JulianDate.J2000 - 10000),
            bodyWithId(34567, jd: 12)
        ])
        XCTAssertEqual(merged, expected)
    }
}

fileprivate extension CharacterSet {
    static var urlAllowedCharacterSet: CharacterSet {
        return CharacterSet.urlPathAllowed.union(.urlHostAllowed).union(.urlQueryAllowed)
    }
}
