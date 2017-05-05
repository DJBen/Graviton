//
//  ParserTest.swift
//  StarCatalog
//
//  Created by Ben Lu on 11/27/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
import MathUtil
@testable import Orbits

class ParserTest: XCTestCase {

    static var mockData: String!

    override class func setUp() {
        super.setUp()
        let path = Bundle.init(for: ParserTest.self).path(forResource: "mars", ofType: "result")!
        mockData = try! String(contentsOfFile: path, encoding: .utf8)
    }

    func testParseDoubleColumn() {
        let result = ResponseParser.default.parseDoubleColumn("Sidereal rot. period  =   24.622962 hr  Rot. Rate (x10^5 s)   =  7.088218")
        XCTAssertEqual(result?.0.0, "Sidereal rot. period")
        XCTAssertEqual(result?.0.1, "24.622962 hr")
        XCTAssertEqual(result?.1?.0, "Rot. Rate (x10^5 s)")
        XCTAssertEqual(result?.1?.1, "7.088218")
    }

    func testField() {
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
        let result = ResponseParser.default.parseField(ParserTest.mockData)
        detailAssertEqual(result, expectedResult)
    }

    private func detailAssertEqual(_ result: [String: String], _ expected: [String: String]) {
        for k in result.keys where expected[k] == nil {
            XCTFail("Extra key \(k) in result")
        }
        for k in expected.keys {
            if let r = result[k] {
                let e = expected[k]
                XCTAssertEqual(r, e)
            } else {
                XCTFail("Missing key \(k) expected")
            }
        }
    }

    func testOtherInfo() {
        let expectedResult = ["Target body name": ("Mars (499)", Optional("{source: mar097}")), "Center body name": ("Sun (10)", Optional("{source: mar097}")), "Center-site name": ("BODY CENTER", nil), "Start time": ("A.D. 2017-Jan-01 00:00:00.0000 TDB", nil), "Stop  time": ("A.D. 2017-Jan-01 00:30:00.0000 TDB", nil), "Step-size": ("1 steps", nil), "Center geodetic": ("0.00000000,0.00000000,0.0000000", Optional("{E-lon(deg),Lat(deg),Alt(km)}")), "Center cylindric": ("0.00000000,0.00000000,0.0000000", Optional("{E-lon(deg),Dxy(km),Dz(km)}")), "Center radii": ("696000.0 x 696000.0 x 696000.0 k", Optional("{Equator, meridian, pole}")), "Keplerian GM": ("1.3271248287031293E+11 km^3/s^2", nil), "Output units": ("KM-S, deg, Julian Day Number (Tp)", nil), "Output type": ("GEOMETRIC osculating elements", nil), "Output format": ("10", nil), "Reference frame": ("ICRF/J2000.0", nil), "Coordinate systm": ("Ecliptic and Mean Equinox of Reference Epoch", nil)]
        let result: [String: (String, String?)] = ResponseParser.default.parseLineBasedContent(ParserTest.mockData)
        for k in result.keys {
            XCTAssertEqual(expectedResult[k]!.0, result[k]!.0)
            XCTAssertEqual(expectedResult[k]!.1, result[k]!.1)
        }
    }

    func testParsingMars() {
        let body = ResponseParser.default.parse(content: ParserTest.mockData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body!.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 3389.9e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 25.19), accuracy: 1e-3)
        XCTAssertEqual(body!.naifId, 499)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 88642.6632, accuracy: 1e-3)
        XCTAssertEqual(body!.centerBody?.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 42828.3, accuracy: 1e-6)
    }

    func testParsingEarth() {
        let path = Bundle.init(for: ParserTest.self).path(forResource: "earth", ofType: "result")!
        let earthData = try! String(contentsOfFile: path, encoding: .utf8)
        let body = ResponseParser.default.parse(content: earthData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body?.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 6371.01e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 23.45), accuracy: 1e-3)
        XCTAssertEqual(body?.naifId, 399)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 23.93419 * 3600, accuracy: 1e-3)
        XCTAssertEqual(body?.centerBody?.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 398600.440, accuracy: 1e-4)
    }

    func testParsingVenus() {
        let path = Bundle.init(for: ParserTest.self).path(forResource: "venus", ofType: "result")!
        let earthData = try! String(contentsOfFile: path, encoding: .utf8)
        let body = ResponseParser.default.parse(content: earthData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body?.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 6051.8e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 177.3), accuracy: 1e-3)
        XCTAssertEqual(body?.naifId, 299)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, -243.0185 * 3600 * 24, accuracy: 1e-3)
        XCTAssertEqual(body?.centerBody?.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 324858.63, accuracy: 1e-4)
    }

    func testParsingNeptune() {
        let path = Bundle.init(for: ParserTest.self).path(forResource: "neptune", ofType: "result")!
        let earthData = try! String(contentsOfFile: path, encoding: .utf8)
        let body = ResponseParser.default.parse(content: earthData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body?.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 24624e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 29.56), accuracy: 1e-3)
        XCTAssertEqual(body?.naifId, 899)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 16.7 * 3600, accuracy: 1e-3)
        XCTAssertEqual(body?.centerBody?.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 6835107, accuracy: 1e-4)
    }

    func testParsingPluto() {
        let path = Bundle.init(for: ParserTest.self).path(forResource: "pluto", ofType: "result")!
        let earthData = try! String(contentsOfFile: path, encoding: .utf8)
        let body = ResponseParser.default.parse(content: earthData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body?.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 1195e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, 0, accuracy: 1e-3)
        XCTAssertEqual(body?.naifId, 999)
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 0, accuracy: 1e-3)
        XCTAssertEqual(body?.centerBody?.naifId, Sun.sol.naifId)
        XCTAssertEqualWithAccuracy(body!.gravParam, 872.4, accuracy: 1e-4)
    }

    func testParsingMoon() {
        let path = Bundle.init(for: ParserTest.self).path(forResource: "moon", ofType: "result")!
        let earthData = try! String(contentsOfFile: path, encoding: .utf8)
        let body = ResponseParser.default.parse(content: earthData)
        XCTAssertNotNil(body)
        XCTAssertNotNil(body?.motion)
        XCTAssertEqualWithAccuracy(body!.radius, 1737.4e3, accuracy: 1e-3)
        XCTAssertEqualWithAccuracy(body!.obliquity, radians(degrees: 6.67), accuracy: 1e-4)
        XCTAssertEqual(body?.naifId, 301)
        // rotation period equals to orbital period
        XCTAssertEqualWithAccuracy(body!.rotationPeriod, 2360584.6847, accuracy: 1e-3)
        XCTAssertEqual(body?.centerBody?.naifId, 399)
        XCTAssertEqualWithAccuracy(body!.gravParam, 4902.80007, accuracy: 1e-4)
    }
}
