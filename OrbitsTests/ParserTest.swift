//
//  ParserTest.swift
//  StarCatalog
//
//  Created by Ben Lu on 11/27/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
import SpaceTime
@testable import Orbits

class ParserTest: XCTestCase {
    
    static var mockData: String!
    
    override class func setUp() {
        super.setUp()
        let path = Bundle.init(for: ParserTest.self).path(forResource: "mars", ofType: "result")!
        mockData = try! String(contentsOfFile: path, encoding: .utf8)
    }
    
    func testBodyInfo() {
        let expectedResult = [
            "Mean radius (km)": "3389.9(2+-4)",
            "Density (g cm^-3)": "3.933(5+-4)",
            "Mass (10^23 kg )": "6.4185",
            "Flattening, f": "1/154.409",
            "Volume (x10^10 km^3)": "16.318",
            "Semi-major axis": "3397+-4",
            "Sidereal rot. period": "24.622962 hr",
            "Rot. Rate (x10^5 s)": "7.088218",
            "Mean solar day": "1.0274907 d",
            "Polar gravity ms^-2": "3.758",
            "Mom. of Inertia": "0.366",
            "Equ. gravity  ms^-2": "3.71",
            "Core radius (km)": "~1700",
            "Potential Love # k2": "0.153 +-.017",
            "Grav spectral fact u": "14 (x10^5)",
            "Topo. spectral fact t": "96 (x10^5)",
            "Fig. offset (Rcf-Rcm)": "2.50+-0.07 km",
            "Offset (lat./long.)": "62d / 88d",
            "GM (km^3 s^-2)": "42828.3",
            "Equatorial Radius, Re": "3394.0 km",
            "GM 1-sigma (km^3 s^-2)": "+- 0.1",
            "Mass ratio (Sun/Mars)": "3098708+-9",
            "Atmos. pressure (bar)": "0.0056",
            "Max. angular diam.": "17.9\"",
            "Mean Temperature (K)": "210",
            "Visual mag. V(1,0)": "-1.52",
            "Geometric albedo": "0.150",
            "Obliquity to orbit": "25.19 deg",
            "Orbit vel.  km/s": "24.1309",
            "Mean sidereal orb per": "686.98 d",
            "Escape vel. km/s": "5.027",
            "Hill\'s sphere rad. Rp": "319.8",
            "Mag. mom (gauss Rp^3)": "< 1x10^-4"
        ]
        let result = ResponseParser.parseBodyInfo(ParserTest.mockData)
        XCTAssertEqual(expectedResult, result)
    }
    
    func testOtherInfo() {
        let expectedResult = ["Target body name": ("Mars (499)", Optional("{source: mar097}")), "Center body name": ("Sun (10)", Optional("{source: mar097}")), "Center-site name": ("BODY CENTER", nil), "Start time": ("A.D. 2016-Dec-21 11:22:00.0000 TDB", nil), "Stop  time": ("A.D. 2016-Dec-21 12:22:00.0000 TDB", nil), "Step-size": ("1 steps", nil), "Center geodetic": ("0.00000000,0.00000000,0.0000000", Optional("{E-lon(deg),Lat(deg),Alt(km)}")), "Center cylindric": ("0.00000000,0.00000000,0.0000000", Optional("{E-lon(deg),Dxy(km),Dz(km)}")), "Center radii": ("696000.0 x 696000.0 x 696000.0 k", Optional("{Equator, meridian, pole}")), "System GM": ("1.3271248287031293E+11 km^3/s^2", nil), "Output units": ("KM-S, deg, Julian Day Number (Tp)", nil), "Output type": ("GEOMETRIC osculating elements", nil), "Output format": ("10", nil), "Reference frame": ("ICRF/J2000.0", nil), "Coordinate systm": ("Ecliptic and Mean Equinox of Reference Epoch", nil)]
        let result: [String: (String, Optional<String>)] = ResponseParser.parseLineBasedContent(ParserTest.mockData)
        for k in result.keys {
            XCTAssertEqual(expectedResult[k]!.0, result[k]!.0)
            XCTAssertEqual(expectedResult[k]!.1, result[k]!.1)
        }
    }
    
    func testParsingMars() {
        let body = ResponseParser.parse(content: ParserTest.mockData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body!.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 3389.9e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 25.19), accuracy: 1e-3)
        XCTAssertEqual(body!.naifId, 499)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 88642.6632, accuracy: 1e-3)
        XCTAssertEqual(body!.centralBody?.entity.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 42828.3, accuracy: 1e-6)
//        print(Double(bodyInfo["Hill's sphere rad. Rp"]!))
    }
    
    func testParsingEarth() {
        let path = Bundle.init(for: ParserTest.self).path(forResource: "earth", ofType: "result")!
        let earthData = try! String(contentsOfFile: path, encoding: .utf8)
        let body = ResponseParser.parse(content: earthData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body!.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 6371.01e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 23.45), accuracy: 1e-3)
        XCTAssertEqual(body!.naifId, 399)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 23.93419 * 3600, accuracy: 1e-3)
        XCTAssertEqual(body!.centralBody?.entity.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 398600.440, accuracy: 1e-4)
    }
    
    func testParsingNeptune() {
        let path = Bundle.init(for: ParserTest.self).path(forResource: "neptune", ofType: "result")!
        let earthData = try! String(contentsOfFile: path, encoding: .utf8)
        let body = ResponseParser.parse(content: earthData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body!.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 24624e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 29.56), accuracy: 1e-3)
        XCTAssertEqual(body!.naifId, 899)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 16.7 * 3600, accuracy: 1e-3)
        XCTAssertEqual(body!.centralBody?.entity.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 6835107, accuracy: 1e-4)
    }
}
