//
//  File.swift
//  
//
//  Created by Jatin Mathur on 7/7/23.
//

import Foundation
import MathUtil
import UIKit
import LASwift

public func doStartrack(image: UIImage, focalLength: Double) -> Matrix? {
    let catalog = Catalog()
    var starLocs = getStarLocations(img: image)

//     Restrict the search-space to 20 stars to avoid generating too many combinations
    var starLocsRng = SeededGenerator(seed: 7)
    starLocs.shuffle(using: &starLocsRng)
    let chosenStarLocs = starLocs.prefix(20)

//     Generate random combinations of 3 stars to test.
    var starCombos: [(Int, Int, Int)] = []
    for i in 0..<chosenStarLocs.count {
        for j in i + 1..<chosenStarLocs.count {
            for k in j + 1..<chosenStarLocs.count {
                starCombos.append((i, j, k))
            }
        }
    }
    var starCombosRng = SeededGenerator(seed: 7)
    starCombos.shuffle(using: &starCombosRng)
    
    let maxStarCombosToTry = 20 // only try this many before bailing
    let angleDelta = 0.017453 * 2 // 1 degree of tolerance
    let width = Int(image.size.width.rounded())
    let height = Int(image.size.height.rounded())
    let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
    let start = Date()
    for (i, j, k) in starCombos.prefix(maxStarCombosToTry) {
        let smIt = findStarMatches(
            starLocs: chosenStarLocs,
            pix2ray: pix2ray,
            curIndices: (i, j, k),
            angleDelta: angleDelta,
            catalog: catalog
        )
        while let sm = smIt.next() {
            let T_C_R = solveWahba(rvs: sm.toRVs())
            if testAttitude(starLocs: chosenStarLocs, pix2Ray: pix2ray, T_C_R: T_C_R, angleDelta: angleDelta) {
                let end = Date()
                let dt = end.timeIntervalSince(start)
                print("Find best time \(dt)")
                // Note that we currently solved the problem in the local camera reference frame, where:
                // +x is horizontal and to the right
                // +y is vertical and down
                // +z is into the page
                // The reference catalog defined:
                // +x into the page
                // +y is horizontal and to the left
                // +z is vertical and up
                // Hence, we must transform our camera-space solution to the catalog reference frame
                // "Cam0" and "Ref0" refers to the fact that these are a constant rotation between the two
                // coordinates systems
                let T_Cam0_Ref0 = Matrix(
                    [
                        Vector([0, -1, 0]),
                        Vector([0, 0, -1]),
                        Vector([1, 0, 0])
                    ]
                )
                // transformation from reference (R) to camera (Cam) in the some coordinate
                // system as the reference (R). Note that T_C_R is currently the product of
                // T_C_R = T_Cam_Cam0 * T_Cam0_Ref0
                // However, in our solver, we never first rotated the catalog rays by T_Cam0_Ref0
                // Hence, it is "baked into" T_C_R.
                let T_Cam_Ref = T_Cam0_Ref0.T * T_C_R
                // Swift wants us to use T_Ref_Cam as the camera orientation
                return T_Cam_Ref.T
            }
        }
    }
    return nil
}

func solveWahba(rvs: [RotatedVector]) -> Matrix {
    var B = Matrix(3, 3, 0.0)
    for rv in rvs {
        let cam = rv.cam.toMatrix()
        let cat = rv.catalog.toMatrix()
        B = B + cam * cat.T
    }
    let (U, _, V) = svd(B)
    return U * diag([1, 1, det(U) * det(V)]) * V.T
}

func testAttitude(starLocs: ArraySlice<StarLocation>, pix2Ray: Pix2Ray, T_C_R: Matrix, angleDelta: Double) -> Bool {
    let T_R_C = T_C_R.T
    let required_matched_stars = Int(0.75 * Double(starLocs.count))
    let max_unmatched_stars = starLocs.count - required_matched_stars
    var num_unmatched_stars = 0
    for sloc in starLocs {
        let sray_C = pix2Ray.pix2Ray(pix: sloc).toMatrix()
        let sray_R = (T_R_C * sray_C).toVector3()
        let nearest_star = Star.closest(to: sray_R, maximumMagnitude: 4.0, maximumAngularDistance: RadianAngle(angleDelta))
        if nearest_star == nil {
            // We failed to match this star
            num_unmatched_stars += 1
            if num_unmatched_stars >= max_unmatched_stars {
                return false
            }
        }
    }
    return true
}

extension Vector3 {
    func toMatrix() -> Matrix {
        let m = Matrix(3, 1, 0)
        m[0,0] = self.x
        m[1,0] = self.y
        m[2,0] = self.z
        return m
    }
}

extension Matrix {
    func toVector3() -> Vector3 {
        assert(self.rows == 3 && self.cols == 1)
        return Vector3(self[0,0], self[1,0], self[2,0])
    }
}

class Pix2Ray {
    let intrinsics_inv: Matrix
    
    init(focalLength: Double, cx: Double, cy: Double) {
        self.intrinsics_inv = Matrix([
            Vector([1.0/focalLength, 0.0, -cx/focalLength]),
            Vector([0.0, 1.0/focalLength, -cy/focalLength]),
            Vector([0.0, 0.0, 1.0])
        ])
    }
    
    func pix2Ray(pix: StarLocation) -> Vector3 {
        let ray = self.intrinsics_inv * Matrix(Vector([pix.u, pix.v, 1.0]))
        return Vector3(ray[0,0], ray[1,0], ray[2,0]).normalized()
    }
}

/// Finds all possible matches for the 3 star coordinates given. Algorithm overview:
/// 1) Compute pairwise angles between all star pairs
/// 2) Search catalog for star pairs that have the same pairwise angle (within +/- `angleDelta/2` tolerance)
/// 3) Find all matches that satisfy each pairwise angle constraint
func findStarMatches(
    starLocs: ArraySlice<StarLocation>,
    pix2ray: Pix2Ray,
    curIndices: (Int, Int, Int),
    angleDelta: Double,
    catalog: Catalog
) -> AnyIterator<TriangleStarMatch> {
    let star1Coord = pix2ray.pix2Ray(pix: starLocs[curIndices.0])
    let star2Coord = pix2ray.pix2Ray(pix: starLocs[curIndices.1])
    let star3Coord = pix2ray.pix2Ray(pix: starLocs[curIndices.2])
    
    let thetaS1S2 = acos(star1Coord.dot(star2Coord))
    let thetaS1S3 = acos(star1Coord.dot(star3Coord))
    let thetaS2S3 = acos(star2Coord.dot(star3Coord))
    
    let start = Date()
//    let s1s2Matches = getMatches(angle: thetaS1S2, angleDelta: angleDelta)!
//    let s1s3Matches = getMatches(angle: thetaS1S3, angleDelta: angleDelta)!
//    let s2s3Matches = getMatches(angle: thetaS2S3, angleDelta: angleDelta)!
    let s1s2Matches = catalog.getMatches(angle: thetaS1S2, angleDelta: angleDelta)
    let s1s3Matches = catalog.getMatches(angle: thetaS1S3, angleDelta: angleDelta)
    let s2s3Matches = catalog.getMatches(angle: thetaS2S3, angleDelta: angleDelta)
    let end = Date()
    let dt = end.timeIntervalSince(start)
    print("dt \(dt)")
    
    var s1s2MatchesIterator = s1s2Matches.makeIterator()
    var star1MatchesIterator: Set<Star>.Iterator? = nil
    var s3OptsIterator: Set<Star>.Iterator? = nil
    
    return AnyIterator {
        while let (star1, star1Matches) = s1s2MatchesIterator.next() {
            if star1MatchesIterator == nil {
                star1MatchesIterator = star1Matches.makeIterator()
            }

            while let star2 = star1MatchesIterator?.next() {
                if s3OptsIterator == nil {
                    let s3Opts = findS3(s1: star1, s2: star2, s1s3Stars: s1s3Matches, s2s3Stars: s2s3Matches)
                    s3OptsIterator = s3Opts.makeIterator()
                }

                while let star3 = s3OptsIterator?.next() {
                    return TriangleStarMatch(
                        star1: StarEntry(star: star1, vec: RotatedVector(cam: star1Coord, catalog: star1.physicalInfo.coordinate.normalized())),
                        star2: StarEntry(star: star2, vec: RotatedVector(cam: star2Coord, catalog: star2.physicalInfo.coordinate.normalized())),
                        star3: StarEntry(star: star3, vec: RotatedVector(cam: star3Coord, catalog: star3.physicalInfo.coordinate.normalized()))
                    )
//                    if let (star4, star4Coord) = verifyStarMatch(sm: TriangleStarMatch(star1: star1, star2: star2, star3: star3), starLocs: starLocs, pix2ray: pix2ray, curIndices: curIndices, star1Coord: star1Coord, star2Coord: star2Coord, star3Coord: star3Coord, angleDelta: angleDelta) {
//                        return PyramidStarMatch(
//                            star1: StarEntry(star: star1, vec: RotatedVector(cam: star1Coord, catalog: star1.physicalInfo.coordinate.normalized())),
//                            star2: StarEntry(star: star2, vec: RotatedVector(cam: star2Coord, catalog: star2.physicalInfo.coordinate.normalized())),
//                            star3: StarEntry(star: star3, vec: RotatedVector(cam: star3Coord, catalog: star3.physicalInfo.coordinate.normalized())),
//                            star4: StarEntry(star: star4, vec: RotatedVector(cam: star4Coord, catalog: star4.physicalInfo.coordinate.normalized()))
//                        )
//                    }
                }
                s3OptsIterator = nil
            }
            star1MatchesIterator = nil
        }
        return nil
    }
}

/// Verifies a StarMatch by finding a 4th star that has consistent pairwise angles
//func verifyStarMatch(
//    sm: TriangleStarMatch,
//    starLocs: ArraySlice<StarLocation>,
//    pix2ray: Pix2Ray,
//    curIndices: (Int, Int, Int),
//    star1Coord: Vector3,
//    star2Coord: Vector3,
//    star3Coord: Vector3,
//    angleDelta: Double
//) -> (Star, Vector3)? {
//    for i in 0..<starLocs.count {
//        if i == curIndices.0 || i == curIndices.1 || i == curIndices.2 {
//            continue
//        }
//        let star4Coord = pix2ray.pix2Ray(pix: starLocs[i])
//
//        let thetaS1S4 = acos(star4Coord.dot(star1Coord))
//        let thetaS2S4 = acos(star4Coord.dot(star2Coord))
//        let thetaS3S4 = acos(star4Coord.dot(star3Coord))
//        let s1s4Matches = getMatches(angle: thetaS1S4, angleDelta: angleDelta)!
//        let s2s4Matches = getMatches(angle: thetaS2S4, angleDelta: angleDelta)!
//        let s3s4Matches = getMatches(angle: thetaS3S4, angleDelta: angleDelta)!
//        guard let s1s4Matches = s1s4Matches[sm.star1] else {
//            continue
//        }
//        guard let s2s4Matches = s2s4Matches[sm.star2] else {
//            continue
//        }
//        guard let s3s4Matches = s3s4Matches[sm.star3] else {
//            continue
//        }
//        let s4Cands = s1s4Matches.intersection(s2s4Matches).intersection(s3s4Matches)
//        if s4Cands.count != 1 {
//            continue
//        }
//        return (s4Cands.first!, star4Coord)
//    }
//    return nil
//}

/// Finds all 3rd stars that are consistent with the choices for star1 and star2.
func findS3(s1: Star, s2: Star, s1s3Stars: [Star:Set<Star>], s2s3Stars: [Star:Set<Star>]) -> Set<Star> {
    guard let s1s3Cands = s1s3Stars[s1] else {
        return Set()
    }
    guard let s2s3Cands = s2s3Stars[s2] else {
        return Set()
    }
    return s1s3Cands.intersection(s2s3Cands)
}

public struct TriangleStarMatch {
    let star1: StarEntry
    let star2: StarEntry
    let star3: StarEntry
    
    init(star1: StarEntry, star2: StarEntry, star3: StarEntry) {
        self.star1 = star1
        self.star2 = star2
        self.star3 = star3
    }
    
    func toRVs() -> [RotatedVector] {
        return [self.star1.vec, self.star2.vec, self.star3.vec]
    }
}

public struct PyramidStarMatch {
    let star1: StarEntry
    let star2: StarEntry
    let star3: StarEntry
    let star4: StarEntry
    
    init(star1: StarEntry, star2: StarEntry, star3: StarEntry, star4: StarEntry) {
        self.star1 = star1
        self.star2 = star2
        self.star3 = star3
        self.star4 = star4
    }
    
    func toRVs() -> [RotatedVector] {
        return [self.star1.vec, self.star2.vec, self.star3.vec, self.star4.vec]
    }
}

public struct StarEntry {
    let star: Star
    let vec: RotatedVector
}

public struct RotatedVector {
    let cam: Vector3
    let catalog: Vector3
    
    init(cam: Vector3, catalog: Vector3) {
        self.cam = cam
        self.catalog = catalog
    }
}
