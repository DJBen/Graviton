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

class StartrackerTest: XCTestCase {
    func testStarAngleMatching() {
        // The following are stars in the Big Dipper. We will test that under
        // arbitrary rotation, we can match to them. The coordinates themselves
        // from the sqlite3 catalog.
        
        // Star 1: https://in-the-sky.org/data/object.php?id=TYC3845-1190-1
        let s1_coord = Vector3(-13.775959/25.31, -3.309169/25.31, 20.972944/25.31)
        
        // Star 2: https://in-the-sky.org/data/object.php?id=TYC4146-1274-1
        let s2_coord = Vector3(-17.298705/37.679, 4.33488/37.679, 33.191332/37.679)
        
        // Star 3: https://in-the-sky.org/data/object.php?id=TYC3467-1257-1
        let s3_coord = Vector3(-18.529548/31.8674, -9.394541/31.8674, 24.164506/31.8674)
        
        // TODO: add rotation for these
        // Extremely tight so that only one answer comes out. The real startracker will also solve the Wahba problem
        // and check alignment to observations.
        let angle_thresh = 0.001
        let all_sm = find_all_star_matches(star_coord1: s1_coord, star_coord2: s2_coord, star_coord3: s3_coord, angle_thresh: angle_thresh)
        XCTAssertFalse(all_sm.isEmpty)
        XCTAssertTrue(all_sm.count == 1)
        let sm = all_sm.first!;
        XCTAssertEqual(sm.star1, Star.hr(4905)!)
        XCTAssertEqual(sm.star2, Star.hr(4301)!)
        XCTAssertEqual(sm.star3, Star.hr(5191)!)
    }
    
    func testStarMatching() {
        // TODO: make this a manufactured unit test so we know the expected answer
        let path = Bundle.module.path(forResource: "img", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        let expectedLocs = [(115, 11), (91, 16), (385, 23), (876, 24), (510, 31), (429, 55), (614, 77), (609, 85), (747, 93), (300, 124), (169, 136), (903, 148), (663, 164), (426, 184), (227, 200), (533, 200), (356, 210), (882, 218), (749, 227), (59, 237), (237, 238), (113, 240), (535, 263), (732, 284), (347, 302), (940, 314), (940, 342), (382, 347), (823, 347), (570, 349), (25, 351), (148, 362), (662, 375), (150, 390), (322, 390), (731, 395), (536, 396), (414, 419), (283, 427), (399, 439), (211, 450), (147, 455), (14, 462), (498, 472), (641, 503), (60, 508), (272, 522), (310, 533), (933, 535), (393, 536)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            XCTAssertEqual(locs[i].0, expectedLocs[i].0)
            XCTAssertEqual(locs[i].1, expectedLocs[i].1)
        }
    }
    
    func testDoStartrack() {
//        let starLocs = [(453, 2025), (1265, 965), (2158, 2873)]
//        let attitude = findAttitude(starLocs: starLocs)
        let path = Bundle.module.path(forResource: "img", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let T_CR = doStartrack(image: image, focalLength: 900)
        XCTAssertNotNil(T_CR)
    }
}


