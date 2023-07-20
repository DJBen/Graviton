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
    
    func testDoStartrackSynEasy0() {
        let path = Bundle.module.path(forResource: "img_syn_easy_0", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363, maxStarCombos: 1).get()
        let expected_T_R_C = Matrix([
            Vector([0.3509, -0.2196, 0.9103]),
            Vector([-0.0005, -0.9722, -0.2343]),
            Vector([0.9364, 0.0818, -0.3413]),
            ])
        testRotationEqual(expected: expected_T_R_C, actual: T_R_C, tol: 0.01
        )
    }
    
    func testDoStartrackSynEasy1() {
        let path = Bundle.module.path(forResource: "img_syn_easy_1", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363, maxStarCombos: 1).get()
        let expected_T_R_C = Matrix([
            Vector([0.5626, -0.3935, -0.7271]),
            Vector([0.7793, -0.0411, 0.6253]),
            Vector([-0.276, -0.9184, 0.2835]),
        ])
        testRotationEqual(expected: expected_T_R_C, actual: T_R_C, tol: 0.01)
    }
    
    func testDoStartrackSynEasy2() {
        let path = Bundle.module.path(forResource: "img_syn_easy_2", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363, maxStarCombos: 1).get()
        let expected_T_R_C = Matrix([
            Vector([0.0058, -0.7905, 0.6124]),
            Vector([-1.0, -0.0007, 0.0085]),
            Vector([-0.0063, -0.6125, -0.7905]),
        ])
        testRotationEqual(expected: expected_T_R_C, actual: T_R_C, tol: 0.01)
    }
    
    func testDoStartrackSynHard0() {
        let path = Bundle.module.path(forResource: "img_syn_hard_0", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363, maxStarCombos: 1).get()
        let expected_T_R_C = Matrix([
            Vector([0.3509, -0.2196, 0.9103]),
            Vector([-0.0005, -0.9722, -0.2343]),
            Vector([0.9364, 0.0818, -0.3413]),
        ])
        testRotationEqual(expected: expected_T_R_C, actual: T_R_C, tol: 0.05)
    }
    
    func testDoStartrackSynHard1() {
        let path = Bundle.module.path(forResource: "img_syn_hard_1", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363, maxStarCombos: 1).get()
        let expected_T_R_C = Matrix([
            Vector([0.5626, -0.3935, -0.7271]),
            Vector([0.7793, -0.0411, 0.6253]),
            Vector([-0.276, -0.9184, 0.2835]),
        ])
        testRotationEqual(expected: expected_T_R_C, actual: T_R_C, tol: 0.05)
    }
    
    func testDoStartrackSynHard2() {
        let path = Bundle.module.path(forResource: "img_syn_hard_2", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363, maxStarCombos: 1).get()
        let expected_T_R_C = Matrix([
            Vector([0.0058, -0.7905, 0.6124]),
            Vector([-1.0, -0.0007, 0.0085]),
            Vector([-0.0063, -0.6125, -0.7905]),
            ])
        testRotationEqual(expected: expected_T_R_C, actual: T_R_C, tol: 0.05)
    }
    
    /// Old image with a cloud. Code should still work on it.
    func testDoStartrackReal1() {
        let path = Bundle.module.path(forResource: "img_real_1", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let focalLength = 2863.6363
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 10).get()

        // (hr, u, v)
        let bigDipperStars = [
            (5191, 1339.1477832512314, 1680.344827586207),
            (5054, 1689.1881533101046, 1766.9233449477351),
            (4905, 1828.3333333333333, 1955.3854166666667),
            (4660, 2021.3779527559054,2174.7952755905512),
            (4301, 2557.1111111111113, 2377.763285024155),
            (4554, 1979.2583732057417, 2431.3684210526317),
            (4295, 2384.342105263158, 2635.821052631579)
        ]
        let T_Cam0_Ref0 = Matrix(
            [
                Vector([0, -1, 0]),
                Vector([0, 0, -1]),
                Vector([1, 0, 0])
            ]
        )
        
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
        let intrinsics = inv(pix2ray.intrinsics_inv)
        var reprojErr = 0.0
        for (hr, u, v) in bigDipperStars {
            let s = Star.hr(hr)!
            let rotStar = (T_Cam0_Ref0 * T_R_C.T * s.physicalInfo.coordinate.toMatrix()).toVector3()
            XCTAssertTrue(rotStar.z > 0)
            let rotStarScaled = rotStar / rotStar.z
            let projUV = (intrinsics * rotStarScaled.toMatrix()).toVector3()
            reprojErr += sqrt(pow(projUV.x - u, 2) + pow(projUV.y - v, 2))
        }
        let avgReprojErr = reprojErr / Double(bigDipperStars.count)
        print("Average Big Dipper Reprojection Error: \(avgReprojErr)")
        XCTAssertTrue(avgReprojErr < 50)
    }
    
    /// Straightforwad good image
    func testDoStartrackReal2() {
        let path = Bundle.module.path(forResource: "img_real_2", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 10).get()
        
        // (hr, u, v)
        let bigDipperStars = [
            (5191, 861.1294642857143, 1480.7767857142858),
            (5054, 852.6482412060302, 1855.1608040201006),
            (4905, 691.4754901960785, 2040.5),
            (4554, 221.8046875, 2315.34375),
            (4295, 100.02150537634408, 2790.7526881720432),
            (4301, 421.6077348066298, 2901.546961325967)
        ]
        
        let T_Cam0_Ref0 = Matrix(
            [
                Vector([0, -1, 0]),
                Vector([0, 0, -1]),
                Vector([1, 0, 0])
            ]
        )
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
        let intrinsics = inv(pix2ray.intrinsics_inv)
        var reprojErr = 0.0
        for (hr, u, v) in bigDipperStars {
            let s = Star.hr(hr)!
            let rotStar = (T_Cam0_Ref0 * T_R_C.T * s.physicalInfo.coordinate.toMatrix()).toVector3()
            XCTAssertTrue(rotStar.z > 0)
            let rotStarScaled = rotStar / rotStar.z
            let projUV = (intrinsics * rotStarScaled.toMatrix()).toVector3()
            let err = sqrt(pow(projUV.x - u, 2) + pow(projUV.y - v, 2))
            reprojErr += err
        }
        let avgReprojErr = reprojErr / Double(bigDipperStars.count)
        print("Average Big Dipper Reprojection Error: \(avgReprojErr)")
        XCTAssertTrue(avgReprojErr < 100)
    }
    
    /// This is a complex test case because the image has a lot of visual aliasing. Without better star identification and better algorithmic checks on the solution,
    /// it is possible for this to give a bad result.
    func testDoStartrackReal3() {
        let path = Bundle.module.path(forResource: "img_real_3", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 10).get()
        
        // (hr, u, v)
        let bigDipperStars = [
            (5191, 533.8735294117647,1697.285294117647),
            (5054, 601.0240384615385, 2063.4326923076924),
            (4905, 472.3482849604222,2276.831134564644),
            (4554, 50.39,2652.47),
            (4295, 21.725, 3157.2),
            (4301, 366.3243243243243, 3187.864864864865)
        ]
        let T_Cam0_Ref0 = Matrix(
            [
                Vector([0, -1, 0]),
                Vector([0, 0, -1]),
                Vector([1, 0, 0])
            ]
        )
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
        let intrinsics = inv(pix2ray.intrinsics_inv)
        var reprojErr = 0.0
        for (hr, u, v) in bigDipperStars {
            let s = Star.hr(hr)!
            let rotStar = (T_Cam0_Ref0 * T_R_C.T * s.physicalInfo.coordinate.toMatrix()).toVector3()
            XCTAssertTrue(rotStar.z > 0)
            let rotStarScaled = rotStar / rotStar.z
            let projUV = (intrinsics * rotStarScaled.toMatrix()).toVector3()
            let err = sqrt(pow(projUV.x - u, 2) + pow(projUV.y - v, 2))
            reprojErr += err
        }
        let avgReprojErr = reprojErr / Double(bigDipperStars.count)
        print("Average Big Dipper Reprojection Error: \(avgReprojErr)")
        XCTAssertTrue(avgReprojErr < 60)
    }
    
    /// This initially only found 3 stars and needed to be improved. This is a hard case because there is some clear hand-shake/distortion affects
    /// that lead to the algorithm needing to be flexible and use score-based results.
    func testDoStartrackReal4() {
        let path = Bundle.module.path(forResource: "img_real_4", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 10).get()
        
        // (hr, u, v)
        let bigDipperStars = [
            (5191, 341.11764705882354, 1797.4705882352941),
            (5054, 406.0, 2176.0285714285715),
            (4905, 273.16129032258067,  2399.6129032258063),
            (4660, 155.06896551724137, 3357.67241379310333),
            (4301, 155.06896551724137, 3357.6724137931033)
        ]
        let T_Cam0_Ref0 = Matrix(
            [
                Vector([0, -1, 0]),
                Vector([0, 0, -1]),
                Vector([1, 0, 0])
            ]
        )
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
        let intrinsics = inv(pix2ray.intrinsics_inv)
        var reprojErr = 0.0
        for (hr, u, v) in bigDipperStars {
            let s = Star.hr(hr)!
            let rotStar = (T_Cam0_Ref0 * T_R_C.T * s.physicalInfo.coordinate.toMatrix()).toVector3()
            XCTAssertTrue(rotStar.z > 0)
            let rotStarScaled = rotStar / rotStar.z
            let projUV = (intrinsics * rotStarScaled.toMatrix()).toVector3()
            let err = sqrt(pow(projUV.x - u, 2) + pow(projUV.y - v, 2))
            reprojErr += err
        }
        let avgReprojErr = reprojErr / Double(bigDipperStars.count)
        print("Average Big Dipper Reprojection Error: \(avgReprojErr)")
        XCTAssertTrue(avgReprojErr < 250)
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
    print("L1 Difference: \(score)")
    XCTAssertTrue(score <= tol)
}


