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
        let expectedLocs = [(3852, 78, 137), (3975, 308, 781), (4540, 1962, 902), (4689, 2360, 1039), (4357, 1005, 1451), (4534, 1532, 1451), (4910, 2580, 1527), (4247, 413, 1936), (4377, 696, 2026), (5235, 2577, 2651), (4915, 1336, 2868), (5340, 2748, 2902), (4554, 310, 3187), (4660, 314, 3476), (5429, 2384, 3477), (5505, 2658, 3530), (4905, 595, 3638), (5191, 1209, 3727), (5435, 2007, 3754), (5054, 808, 3790)]
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
        let expectedLocs =  [(5477, 1621, 438), (5681, 425, 650), (5511, 2257, 670), (5487, 2705, 722), (5793, 777, 998), (5788, 1617, 1230), (5854, 1789, 1406), (5933, 1292, 1427), (5892, 1861, 1515), (6212, 314, 1690), (6148, 890, 1736), (6056, 2174, 1924), (6149, 1831, 2039), (6410, 542, 2187), (6175, 2438, 2313), (6406, 1066, 2361), (6603, 1417, 2883), (6561, 2487, 3183), (6812, 2739, 3858), (7235, 446, 3878)]
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
        let expectedLocs =  [(1228, 420, 92), (1346, 1699, 116), (1463, 2930, 151), (1457, 1682, 390), (1552, 2337, 517), (1788, 2827, 973), (1612, 377, 977), (1791, 1120, 1170), (1931, 2831, 1186), (1948, 2789, 1219), (1910, 1521, 1274), (2095, 704, 1577), (2216, 1473, 1724), (2286, 1474, 1818), (2421, 1779, 1994), (2763, 1749, 2483), (2890, 945, 2599), (2845, 2171, 2639), (3579, 90, 3495), (3314, 2875, 3627)]
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


