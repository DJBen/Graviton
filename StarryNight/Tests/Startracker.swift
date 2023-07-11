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
        let s1Coord = Vector3(-13.775959/25.31, -3.309169/25.31, 20.972944/25.31)
        
        // Star 2: https://in-the-sky.org/data/object.php?id=TYC4146-1274-1
        let s2Coord = Vector3(-17.298705/37.679, 4.33488/37.679, 33.191332/37.679)
        
        // Star 3: https://in-the-sky.org/data/object.php?id=TYC3467-1257-1
        let s3Coord = Vector3(-18.529548/31.8674, -9.394541/31.8674, 24.164506/31.8674)
        
        // A random rotation matrix
        let rotation = Matrix([
            Vector([0.66341395, -0.73502409, -0.14007684]),
            Vector([0.5566704, 0.60992316, -0.56401402]),
            Vector([0.5, 0.29619813, 0.81379768]),
        ])
        
        let s1 = (rotation * s1Coord.toMatrix()).toVector3()
        let s2 = (rotation * s2Coord.toMatrix()).toVector3()
        let s3 = (rotation * s3Coord.toMatrix()).toVector3()
        
        // Extremely tight so that only one answer comes out. The real startracker will also solve the Wahba problem
        // and check alignment to observations.
        let angleDelta = 0.001
        let allSM = findStarMatches(star1Coord: s1, star2Coord: s2, star3Coord: s3, angleDelta: angleDelta)
        XCTAssertFalse(allSM.isEmpty)
        XCTAssertTrue(allSM.count == 1)
        let sm = allSM.first!;
        XCTAssertEqual(sm.star1, Star.hr(4905)!)
        XCTAssertEqual(sm.star2, Star.hr(4301)!)
        XCTAssertEqual(sm.star3, Star.hr(5191)!)
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
        
        // rough check to make sure solution is close
        // a more interpretable test might convert to axis-angle
        // and test that the axis of rotation is close and the
        // amount of rotation is close
        let diff = T_CR - expected_T_CR
        var score = 0.0
        for i in 0..<diff.rows {
            for j in 0..<diff.cols {
                score += abs(diff[i,j])
            }
        }
        XCTAssertTrue(score <= 0.01)
    }
}


