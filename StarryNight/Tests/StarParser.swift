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
    func testStarMatchingEasy() {
        let path = Bundle.module.path(forResource: "img_easy", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        // (hr, v, u)
        let expectedLocs = [(8450, 650, 68), (8698, 455, 85), (8308, 734, 95), (8518, 562, 103), (8892, 298, 122), (8709, 387, 144), (8131, 741, 194), (7882, 927, 207), (8232, 613, 237), (8278, 506, 293), (8204, 479, 357), (7950, 652, 357), (8820, 113, 362), (7602, 929, 381), (7710, 806, 388), (8556, 200, 404), (8353, 310, 410), (7570, 870, 427), (7754, 674, 446), (8425, 197, 466)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let a = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(a.u, Double(e.1), accuracy: 0.001)
            XCTAssertEqual(a.v, Double(e.2), accuracy: 0.001)
        }
    }
    
    func testStarMatchingHard() {
        let path = Bundle.module.path(forResource: "img_hard", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        // (hr, v, u)
        let expectedLocs =  [(3165, 510, 50), (2878, 430, 85), (-1, 488, 104), (2020, 216, 145), (1465, 59, 156), (2451, 360, 160), (2948, 581, 187), (2538, 460, 228), (2580, 518, 284), (2970, 729, 308), (1862, 298, 311), (1326, 82, 323), (2491, 559, 357), (2294, 510, 385), (-1, 421, 409), (2035, 432, 412), (-1, 495, 412), (1464, 199, 429), (1829, 376, 449), (-1, 497, 450), (1654, 318, 470), (2227, 576, 502), (-1, 426, 515), (1702, 367, 519), (2004, 496, 521)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let a = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(a.u, Double(e.1), accuracy: 0.001)
            XCTAssertEqual(a.v, Double(e.2), accuracy: 0.001)
        }
    }
}


