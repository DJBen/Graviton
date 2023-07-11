//
//  File.swift
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
    func testStarMatching() {
        // TODO: make this a manufactured unit test so we know the expected answer
        let path = Bundle.module.path(forResource: "img", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        // (hr, v, u)
        let expectedLocs = [(8450, 650, 67), (8698, 455, 84), (8308, 734, 95), (8518, 562, 102), (8892, 298, 122), (8709, 386, 143), (8131, 740, 194), (7882, 927, 207), (8232, 612, 236), (8278, 506, 292), (8204, 479, 356), (7950, 652, 356), (8820, 112, 361), (7602, 928, 380), (7710, 806, 388), (8556, 200, 403), (8353, 310, 410), (7570, 869, 427), (7754, 674, 445), (8425, 196, 466)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let a = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(a.u, Double(e.1), accuracy: 0.001)
            XCTAssertEqual(a.v, Double(e.2), accuracy: 0.001)
        }
    }
}


