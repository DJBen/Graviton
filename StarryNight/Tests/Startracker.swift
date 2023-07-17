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
    /// Explicitly tests the somewhat complex index generation logic for correctness
    func testStarLocationGeneratorEasy() {
        let gen = starLocsGenerator(n: 5)
        let expectedLocs = [
            (0, 1, 2),
            (1, 2, 3),
            (2, 3, 4),
            (0, 1, 3),
            (1, 2, 4),
            (0, 1, 4),
            (0, 2, 3),
            (1, 3, 4),
            (0, 2, 4),
            (0, 3, 4)
        ]
        var eGen = expectedLocs.makeIterator()
        for (i, j, k) in gen {
            let (eI, eJ, eK) = eGen.next()!
            XCTAssertTrue(i == eI)
            XCTAssertTrue(j == eJ)
            XCTAssertTrue(k == eK)
        }
        XCTAssertNil(eGen.next())
    }
    
    /// Tests the somewhat complex index generation logic to make sure it does not skip any
    /// indices on a "large" number of stars
    func testStarLocationGeneratorHard() {
        let n = 10
        let gen = starLocsGenerator(n: n)
        var allLocs: [(Int, Int, Int)] = []
        for (i, j, k) in gen {
            allLocs.append((i, j, k))
        }
        allLocs.sort { (loc1, loc2) -> Bool in
            if loc1.0 != loc2.0 {
                return loc1.0 < loc2.0
            } else if loc1.1 != loc2.1 {
                return loc1.1 < loc2.1
            } else {
                return loc1.2 < loc2.2
            }
        }
        
        var allLocsIt = allLocs.makeIterator()
        
        // These are the order of indices we expect post sorting
        // This is a completeness check to make sure we did not miss any combinations
        for i in 0..<n {
            for j in i + 1..<n {
                for k in j + 1..<n {
                    let (itI, itJ, itK) = allLocsIt.next()!
                    XCTAssertTrue(i == itI)
                    XCTAssertTrue(j == itJ)
                    XCTAssertTrue(k == itK)
                }
            }
        }
        // make sure iterator is finished
        XCTAssertNil(allLocsIt.next())
    }
    
    func testStarAngleMatching() {
        // The following was created by using the `create_synthetic_img.py` script
        let starLocs = [
            StarLocation(u: 237, v: 394), // HR: 5191
            StarLocation(u: 332, v: 452), // HR: 4905
            StarLocation(u: 358, v: 543), // HR: 4554
            StarLocation(u: 161, v: 525), // HR: 4915
        ]
        let pix2ray = Pix2Ray(focalLength: 600, cx: 484/2, cy: 969/2)
        let st = StarTracker()
        
        // Extremely tight so that only one answer comes out. The real startracker will also solve the Wahba problem
        // and check alignment to observations.
        let angleDelta = 0.002
        let allSMIt = st.findStarMatches(starLocs: starLocs, pix2ray: pix2ray, curIndices: (0, 1, 3), angleDelta: angleDelta)
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
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 600).get()
//        let expected_T_C_R = Matrix([
//            Vector([-0.14007684, -0.66341395, 0.73502409]),
//            Vector([-0.56401402, -0.5566704, -0.60992316]),
//            Vector([ 0.81379768, -0.5, -0.29619813])
//        ])
//        testRotationEqual(expected: expected_T_C_R, actual: T_C_R, tol: 0.01)
    }
    
    func testDoStartrackHard() {
        let path = Bundle.module.path(forResource: "img_hard", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 600).get()
//        let expected_T_C_R = Matrix([
//            Vector([-0.78171649, 0.17101007, 0.599729]),
//            Vector([0.599729, 0.46984631, 0.6477419]),
//            Vector([-0.17101007, 0.8660254, -0.46984631])
//        ])
//        testRotationEqual(expected: expected_T_C_R, actual: T_C_R, tol: 0.02)
    }
    
    func testDoStartrackIPhoneCam() {
        let path = Bundle.module.path(forResource: "img_test", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363).get()
        let expected = Matrix([
            Vector([-0.650, -0.565, 0.509]),
            Vector([-0.146, -0.564, -0.813]),
            Vector([0.746, -0.602, 0.284])
        ])
        testRotationEqual(expected: expected, actual: T_R_C, tol: 0.1)
    }
    
    func testDoStartrackReal() {
        let path = Bundle.module.path(forResource: "img_real", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363).get()
        let expected = Matrix([
            Vector([-0.429, -0.637, 0.639]),
            Vector([-0.205, -0.620, -0.757]),
            Vector([0.880, -0.456, 0.135])
        ])
        testRotationEqual(expected: expected, actual: T_R_C, tol: 0.1)
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


