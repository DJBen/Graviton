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
        // (hr, v, u)
        let expectedLocs = [(8308, 465, 19), (3185, 795, 19), (7417, 931, 24), (2948, 896, 29), (8558, 294, 38), (3748, 495, 59), (7906, 651, 64), (8698, 181, 73), (8414, 351, 81), (7635, 776, 87), (3845, 421, 110), (8131, 500, 110), (4359, 62, 121), (4133, 228, 124), (8709, 125, 157), (4357, 30, 180), (3665, 457, 181), (8232, 400, 184), (3982, 276, 188), (8812, 42, 194), (3314, 602, 199), (7557, 716, 207), (3852, 353, 209), (2970, 744, 216), (7235, 877, 229), (4057, 199, 248), (8322, 303, 257), (3482, 492, 258), (7710, 604, 263), (7570, 658, 277), (7950, 472, 283), (7377, 738, 302), (8728, 26, 309), (3249, 540, 327), (3873, 259, 331), (8204, 311, 343), (2943, 647, 353), (7754, 516, 354), (3461, 426, 363), (2356, 936, 368), (7236, 730, 409), (8353, 147, 468), (3705, 243, 471), (6869, 875, 487), (2763, 618, 492), (7340, 601, 496), (6973, 788, 506), (2985, 507, 515), (4033, 43, 519), (2484, 724, 527)]
        //XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let l = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(locs[i].0, expectedLocs[i].1)
            XCTAssertEqual(locs[i].1, expectedLocs[i].2)
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


