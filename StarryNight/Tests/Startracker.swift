//
//  Startracker.swift
//
//  Tests major components of the startracking algorithm, including end-to-end tests where startracking
//  is performed on synthetic (see Python code) and real images.
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
        // The following was created by using the star locations outputted by `create_synthetic_img.py`
        let starLocs = [
            StarLocation(u: 1209, v: 3727), // HR: 5191
            StarLocation(u: 595, v: 3638), // HR: 4905
            StarLocation(u: 310, v: 3187), // HR: 4554
        ]
        let pix2ray = Pix2Ray(focalLength: 2863.6364166951494, cx: 3024/2, cy: 4032/2)
        let st = StarTracker()
        
        // Extremely tight so that only one answer comes out. The real startracker will also solve the Wahba problem
        // and check alignment to observations.
        let angleDelta = 0.001
        let allSMIt = st.findStarMatches(starLocs: starLocs, pix2ray: pix2ray, curIndices: (0, 1, 2), angleDelta: angleDelta)
        let allSM = Array(allSMIt)
        XCTAssertFalse(allSM.isEmpty)
        XCTAssertTrue(allSM.count == 1)
        let sm = allSM.first!;
        XCTAssertEqual(sm.star1.star.hr, 5191)
        XCTAssertEqual(sm.star2.star.hr, 4905)
        XCTAssertEqual(sm.star3.star.hr, 4554)
    }
    
    func testDoStartrackSynEasy0() {
        let path = Bundle.module.path(forResource: "img_syn_easy_0", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let T_R_C = try! st.track(image: image, focalLength: 2863.6363, maxStarCombos: 1).get()
        let expected_T_R_C = Matrix([
            Vector([-0.9137, 0.195, -0.3566]),
            Vector([-0.067, 0.7931, 0.6054]),
            Vector([0.4009, 0.5771, -0.7116]),
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
            Vector([-0.3512, 0.3304, -0.876]),
            Vector([-0.9254, 0.0198, 0.3785]),
            Vector([0.1424, 0.9436, 0.2988]),
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
            Vector([-0.1615, 0.0408, 0.986]),
            Vector([0.915, -0.3682, 0.1651]),
            Vector([0.3698, 0.9288, 0.0222]),
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
            Vector([-0.9137, 0.195, -0.3566]),
            Vector([-0.067, 0.7931, 0.6054]),
            Vector([0.4009, 0.5771, -0.7116]),
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
            Vector([-0.3512, 0.3304, -0.876]),
            Vector([-0.9254, 0.0198, 0.3785]),
            Vector([0.1424, 0.9436, 0.2988]),
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
            Vector([-0.1615, 0.0408, 0.986]),
            Vector([0.915, -0.3682, 0.1651]),
            Vector([0.3698, 0.9288, 0.0222]),
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
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 30).get()

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
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 30).get()
        
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
    func testBadAlign0() {
        let path = Bundle.module.path(forResource: "bad_align_0", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 30).get()
        
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
    
    /// Handles edge-case where camera shake induces somewhat disjoint stars
    func testBadAlign1() {
        let path = Bundle.module.path(forResource: "bad_align_1", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 30).get()
        
        // (hr, u, v)
        let bigDipperStars = [
            (5191, 724.4148936170212, 2477.8617021276596),
            (5054, 739.4285714285714,2861.9065934065934),
            (4905, 584.3502304147465,3091.3640552995394),
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
        XCTAssertTrue(avgReprojErr < 80)
    }
    
    /// This initially only found 3 stars and needed to be improved. This is a hard case because there is some clear hand-shake/distortion affects
    /// that lead to the algorithm needing to be flexible and use score-based results.
    func testNotEnoughStars0() {
        let path = Bundle.module.path(forResource: "not_enough_stars_0", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let T_R_C = try! st.track(image: image, focalLength: focalLength, maxStarCombos: 30).get()
        
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
    
    /// This initially only found 8 stars and needed to be improved. This is a hard case because there is some clear hand-shake/distortion affects
    /// that lead to the algorithm needing to be flexible and use score-based results.
    ///  TODO: for now, this example is too hard and out-of-scope. Most likely we need to add some smoothing convolutional filter then rework thresholds
    func testNotEnoughStars1() {
        let path = Bundle.module.path(forResource: "not_enough_stars_1", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let stResult = st.track(image: image, focalLength: focalLength, maxStarCombos: 30)
        switch stResult {
            case .failure(_):
                // Success! We expected an error and we got one.
                XCTAssertTrue(true)
            case .success(_):
                XCTFail("Expected an error, but track() was successful.")
        }
        
        // TODO: below can be used to help debug this image
//        // (hr, u, v)
//        let knownStars = [
//            (7001, 2024.6751824817518,1641.85401459854)
//        ]
//        let T_Cam0_Ref0 = Matrix(
//            [
//                Vector([0, -1, 0]),
//                Vector([0, 0, -1]),
//                Vector([1, 0, 0])
//            ]
//        )
//        let width = Int(image.size.width.rounded())
//        let height = Int(image.size.height.rounded())
//        let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
//        let intrinsics = inv(pix2ray.intrinsics_inv)
//        var reprojErr = 0.0
//        for (hr, u, v) in knownStars {
//            let s = Star.hr(hr)!
//            let rotStar = (T_Cam0_Ref0 * T_R_C.T * s.physicalInfo.coordinate.toMatrix()).toVector3()
//            XCTAssertTrue(rotStar.z > 0)
//            let rotStarScaled = rotStar / rotStar.z
//            let projUV = (intrinsics * rotStarScaled.toMatrix()).toVector3()
//            let err = sqrt(pow(projUV.x - u, 2) + pow(projUV.y - v, 2))
//            reprojErr += err
//        }
//        let avgReprojErr = reprojErr / Double(knownStars.count)
//        print("Average Star Reprojection Error: \(avgReprojErr)")
//        XCTAssertTrue(avgReprojErr < 40)
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


