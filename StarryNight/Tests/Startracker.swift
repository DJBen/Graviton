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
        // The following was created by using the `create_synthetic_img.py` script
        let catalog = Catalog()
        
        let starLocs = [
            StarLocation(u: 237, v: 394), // HR: 5191
            StarLocation(u: 332, v: 452), // HR: 4905
            StarLocation(u: 358, v: 543), // HR: 4554
            StarLocation(u: 161, v: 525), // HR: 4915
        ]
        let pix2ray = Pix2Ray(focalLength: 600, cx: 484/2, cy: 969/2)
        let chosenStarLocs = starLocs.prefix(4)
        
        // Extremely tight so that only one answer comes out. The real startracker will also solve the Wahba problem
        // and check alignment to observations.
        let angleDelta = 0.002
        let allSMIt = findStarMatches(starLocs: chosenStarLocs, pix2ray: pix2ray, curIndices: (0, 1, 3), angleDelta: angleDelta, catalog: catalog)
        let allSM = Array(allSMIt)
        XCTAssertFalse(allSM.isEmpty)
        XCTAssertTrue(allSM.count == 1)
        let sm = allSM.first!;
        XCTAssertEqual(sm.star1.star.hr, 5191)
        XCTAssertEqual(sm.star2.star.hr, 4905)
        XCTAssertEqual(sm.star3.star.hr, 4915)
    }
    
    func testDoStartrackEasy() {
        let path = Bundle.module.path(forResource: "img_easy", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        // Transform from reference (R) to Camera (C)
        let T_C_R = doStartrack(image: image, focalLength: 600)!
        let expected_T_C_R = Matrix([
            Vector([-0.14007684, -0.66341395, 0.73502409]),
            Vector([-0.56401402, -0.5566704, -0.60992316]),
            Vector([ 0.81379768, -0.5, -0.29619813])
        ])
        testRotationEqual(expected: expected_T_C_R, actual: T_C_R, tol: 0.01)
    }
    
    func testDoStartrackHard() {
        let path = Bundle.module.path(forResource: "img_hard", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        // Transform from reference (R) to Camera (C)
        let T_C_R = doStartrack(image: image, focalLength: 600)!
        let expected_T_C_R = Matrix([
            Vector([-0.78171649, 0.17101007, 0.599729]),
            Vector([0.599729, 0.46984631, 0.6477419]),
            Vector([-0.17101007, 0.8660254, -0.46984631])
        ])
        testRotationEqual(expected: expected_T_C_R, actual: T_C_R, tol: 0.02)
    }
    
    func testDoStartrackReal() {
        let path = Bundle.module.path(forResource: "img_test", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        // Transform from reference (R) to Camera (C)
        let T_C_R = doStartrack(image: image, focalLength: 2852.574)!
        let expected = Matrix([
            Vector([-0.650, -0.565, 0.509]),
            Vector([-0.146, -0.564, -0.813]),
            Vector([0.746, -0.602, 0.284])
        ])
        testRotationEqual(expected: expected, actual: T_C_R, tol: 0.1)
    }
}

func testRotationEqual(expected: Matrix, actual: Matrix, tol: Double) {
    // rough check to make sure solution is close
    // a more interpretable test might convert to axis-angle
    // and test that the axis of rotation is close and the
    // amount of rotation is close
    let diff = actual - expected
    var score = 0.0
    for i in 0..<diff.rows {
        for j in 0..<diff.cols {
            score += abs(diff[i,j])
        }
    }
    print("SCORE \(score)")
    XCTAssertTrue(score <= tol)
}


