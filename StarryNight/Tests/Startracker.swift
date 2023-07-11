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
        
        let rotation = Matrix([
            Vector([0.66341395, -0.73502409, -0.14007684]),
            Vector([0.5566704, 0.60992316, -0.56401402]),
            Vector([0.5, 0.29619813, 0.81379768]),
        ])
        
        let s1 = (rotation * s1_coord.toMatrix()).toVector3()
        let s2 = (rotation * s2_coord.toMatrix()).toVector3()
        let s3 = (rotation * s3_coord.toMatrix()).toVector3()
        
        // Extremely tight so that only one answer comes out. The real startracker will also solve the Wahba problem
        // and check alignment to observations.
        let angle_thresh = 0.001
        let all_sm = find_all_star_matches(star_coord1: s1, star_coord2: s2, star_coord3: s3, angle_thresh: angle_thresh)
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
        let expectedLocs = [(8450, 650, 67), (8698, 455, 84), (8308, 734, 95), (8518, 562, 102), (8892, 298, 122), (8709, 386, 143), (8131, 740, 194), (7882, 927, 207), (8232, 612, 236), (8278, 506, 292), (8204, 479, 356), (7950, 652, 356), (8820, 112, 361), (7602, 928, 380), (7710, 806, 388), (8556, 200, 403), (8353, 310, 410), (7570, 869, 427), (7754, 674, 445), (8425, 196, 466)]
        XCTAssertEqual(locs.count, expectedLocs.count)
        for i in 0..<locs.count {
            let l = locs[i]
            let e = expectedLocs[i]
            XCTAssertEqual(locs[i].0, expectedLocs[i].1)
            XCTAssertEqual(locs[i].1, expectedLocs[i].2)
        }
    }
    
    func testDoStartrack() {
        let path = Bundle.module.path(forResource: "img", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let T_CR = doStartrack(image: image, focalLength: 600)!
        let expected_T_CR = Matrix([
            Vector([-0.14007684, -0.66341395, 0.73502409]),
            Vector([-0.56401402, -0.5566704, -0.60992316]),
            Vector([ 0.81379768, -0.5, -0.29619813])
        ])
        let diff = T_CR - expected_T_CR
        var score = 0.0
        for i in 0..<diff.rows {
            for j in 0..<diff.cols {
                score += pow(diff[i,j], 2)
            }
        }
        // heuristic to make sure solution is close
        XCTAssertTrue(score <= 0.001)
    }
}


