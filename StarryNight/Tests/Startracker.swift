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
        let path = Bundle.module.path(forResource: "img", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let locs = image.getStarLocations()
        print()
        
//        let startTime = Date()
//        for y in 0...100 {
//            for x in 0...100 {
////                let startTime = Date()
//                let c = image.getPixelColor(pos: CGPoint(x: x, y: y))
////                let endTime = Date()
////                let timeInterval: Double = endTime.timeIntervalSince(startTime)
////                print("Time taken: \(timeInterval) seconds")
//            }
//        }
//        let endTime = Date()
//        let timeInterval: Double = endTime.timeIntervalSince(startTime)
//        print("Time taken: \(timeInterval) seconds")
    }
}


