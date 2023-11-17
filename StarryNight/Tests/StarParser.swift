//
//  StarParser.swift
//
//
//  Created by Jatin Mathur on 7/7/23.
//

import Foundation

import XCTest
@testable import StarryNight
import SpaceTime
import MathUtil
import LASwift

class StarParserTest: XCTestCase {
    func testStarMatching0() {
        let path = Bundle.module.path(forResource: "img_syn_easy_0", ofType: "png")!
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        // (hr, v, u)
        let expectedLocs = [(2356, 2079, 268), (2004, 1601, 708), (1735, 1483, 1148), (1852, 1869, 1206), (1666, 1480, 1309), (1481, 865, 1315), (1567, 1678, 1685), (1231, 586, 1747), (1910, 2819, 1865), (1543, 1824, 1868), (1136, 628, 2018), (1251, 1431, 2301), (1457, 2104, 2303), (874, 249, 2543), (1038, 1314, 2789), (1178, 2094, 3016), (1142, 2067, 3063), (804, 675, 3091), (1203, 2508, 3250), (1228, 2750, 3358)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let a = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(a.u, Double(e.1), accuracy: 0.001)
            XCTAssertEqual(a.v, Double(e.2), accuracy: 0.001)
        }
    }
    
    func testStarMatching1() {
        let path = Bundle.module.path(forResource: "img_syn_easy_1", ofType: "png")!
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        // (hr, v, u)
        let expectedLocs =  [(1228, 1029, 273), (2012, 2315, 523), (1220, 1069, 552), (1641, 1803, 592), (921, 476, 620), (1135, 972, 734), (1605, 1744, 748), (1708, 1873, 886), (2088, 2294, 896), (1273, 1252, 993), (1017, 900, 1191), (2077, 2134, 1404), (915, 819, 1431), (219, 117, 2225), (264, 292, 2277), (580, 999, 2450), (8974, 931, 3013), (8694, 228, 3144), (8238, 498, 3578), (4787, 2671, 3806)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let a = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(a.u, Double(e.1), accuracy: 0.001)
            XCTAssertEqual(a.v, Double(e.2), accuracy: 0.001)
        }
    }
    
    func testStarMatching2() {
        let path = Bundle.module.path(forResource: "img_syn_easy_2", ofType: "png")!
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        // (hr, v, u)
        let expectedLocs =  [(7986, 1387, 263), (8425, 476, 484), (8556, 206, 625), (7590, 2172, 689), (8636, 395, 838), (8502, 1187, 894), (8675, 647, 966), (25, 318, 1687), (322, 494, 2191), (1208, 2176, 2198), (472, 1109, 2222), (591, 1366, 2241), (440, 696, 2353), (566, 909, 2476), (1175, 1885, 2586), (674, 989, 2621), (1465, 1915, 3225), (2326, 2856, 3675), (2020, 2482, 3713), (1326, 1404, 3827)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let a = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(a.u, Double(e.1), accuracy: 0.001)
            XCTAssertEqual(a.v, Double(e.2), accuracy: 0.001)
        }
    }
    
    func testCloud() {
        let path = Bundle.module.path(forResource: "img_cloud", ofType: "png")!
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        XCTAssertEqual(locs.count, 0)
    }
}


