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
import Collections

public enum StarTrackError: Error, CustomStringConvertible {
    case tooFewStars(Int)
    case noGoodMatches
    
   public var description: String {
        switch self {
        case .noGoodMatches:
            return "Failed to find a good attitude."
        case .tooFewStars(let starCount):
            return "Too few stars detected. Only found \(starCount) stars."
        }
    }
}

public class StarTracker {
    let catalog: Catalog
    
    public init() {
        self.catalog = Catalog()
    }
    
    public func track(image: UIImage, focalLength: Double, maxStarCombos: Int) -> Result<Matrix, StarTrackError> {
        let s = Date()
        var starLocs = getStarLocations(img: image)
        let e = Date()
        let dtGSL = e.timeIntervalSince(s)
        print("Get star locs time: \(dtGSL). Num stars: \(starLocs.count)")
        
        for sl in starLocs {
            print("(\(sl.u),\(sl.v)),")
        }
        
        let minStars = 8
        if starLocs.count < minStars {
            return .failure(StarTrackError.tooFewStars(starLocs.count))
        }
        var rng = SeededGenerator(seed: 7)
        starLocs.shuffle(using: &rng)
        
        let angleDelta = 0.017453 * 2 // 2 degrees of tolerance due to camera shake during long-exposure
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
        let expectedNumMatches = Int(0.85 * Double(starLocs.count))
        
        let gen = starLocsGenerator(n: starLocs.count)
        let sItr = Date()
        for (itrCount, (i, j, k)) in gen.enumerated() {
            let eIter = Date()
            let dtIter = eIter.timeIntervalSince(sItr)
            print("Itr time: \(dtIter)")
            if itrCount == maxStarCombos {
                break
            }
            
            let smStart = Date()
            let allSM = self.findStarMatches(
                starLocs: starLocs,
                pix2ray: pix2ray,
                curIndices: (i, j, k),
                angleDelta: angleDelta
            )
            let smEnd = Date()
            let dtSM = smEnd.timeIntervalSince(smStart)
            print("SM time: \(dtSM)")
        
            for sm in allSM {
                let T_C_R = solveWahba(rvs: sm.toRVs())
                let matchedStars = self.testAttitude(starLocs: starLocs, pix2Ray: pix2ray, T_C_R: T_C_R, angleDelta: angleDelta)
                if matchedStars.count < expectedNumMatches {
                    continue
                }
                // We have a good enough solution!
                let best_T_C_R_opt = solveWahba(rvs: matchedStars)
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
                let T_Cam_Ref = T_Cam0_Ref0.T * best_T_C_R_opt
                // Swift wants us to use T_Ref_Cam as the camera orientation
                return .success(T_Cam_Ref.T)
            }
        }
        return .failure(StarTrackError.noGoodMatches)
    }
    
    /// Tests that an attitude is correct by checking if `requiredFracMatchStars` match.
    func testAttitude(starLocs: [StarLocation], pix2Ray: Pix2Ray, T_C_R: Matrix, angleDelta: Double) -> [RotatedVector] {
        let T_R_C = T_C_R.T
        //        let requiredFracMatchStars = 0.85
        //        let required_matched_stars = Int(requiredFracMatchStars * Double(starLocs.count))
        //        let max_unmatched_stars = starLocs.count - required_matched_stars
        //        var num_unmatched_stars = 0
        var matchedStars: [RotatedVector] = []
        for sloc in starLocs {
            let sray_C = pix2Ray.pix2Ray(pix: sloc)
            let sray_R = (T_R_C * sray_C.toMatrix()).toVector3()
            let nearestStar = catalog.findNearbyStars(coord: sray_R, angleDelta: angleDelta)
            //            if nearestStar == nil {
            //                // We failed to match this star
            //                num_unmatched_stars += 1
            //                if num_unmatched_stars >= max_unmatched_stars {
            //                    return false
            //                }
            //            }
            guard let nearestStar = nearestStar else {
                continue
            }
            matchedStars.append(RotatedVector(cam: sray_C, catalog: nearestStar.normalized_coord))
        }
        //        return true
        return matchedStars
    }
    
    /// Finds all possible matches for the 3 star coordinates given. Algorithm overview:
    /// 1) Compute pairwise angles between all star pairs
    /// 2) Search catalog for star pairs that have the same pairwise angle (within +/- `angleDelta` tolerance)
    /// 3) Find all matches that satisfy each pairwise angle constraint
    func findStarMatches(
        starLocs: [StarLocation],
        pix2ray: Pix2Ray,
        curIndices: (Int, Int, Int),
        angleDelta: Double
    ) -> [TriangleStarMatch] {
        let star1Coord = pix2ray.pix2Ray(pix: starLocs[curIndices.0])
        let star2Coord = pix2ray.pix2Ray(pix: starLocs[curIndices.1])
        let star3Coord = pix2ray.pix2Ray(pix: starLocs[curIndices.2])
        
        let thetaS1S2 = acos(star1Coord.dot(star2Coord))
        let thetaS1S3 = acos(star1Coord.dot(star3Coord))
        let thetaS2S3 = acos(star2Coord.dot(star3Coord))
        
        let s1s2Matches = catalog.getMatches(angle: thetaS1S2, angleDelta: angleDelta)
        let s1s3Matches = catalog.getMatches(angle: thetaS1S3, angleDelta: angleDelta)
        let s2s3Matches = catalog.getMatches(angle: thetaS2S3, angleDelta: angleDelta)
        
        var allTSM: [TriangleStarMatch] = []
        for (star1, star1Matches) in s1s2Matches {
            for star2 in star1Matches {
                let s3Opts1 = findS3(s1: star1, s2: star2, s1s3Stars: s1s3Matches, s2s3Stars: s2s3Matches)
                for star3 in s3Opts1 {
                    let tsm = TriangleStarMatch(
                        star1: StarEntry(star: star1, vec: RotatedVector(cam: star1Coord, catalog: star1.normalized_coord)),
                        star2: StarEntry(star: star2, vec: RotatedVector(cam: star2Coord, catalog: star2.normalized_coord)),
                        star3: StarEntry(star: star3, vec: RotatedVector(cam: star3Coord, catalog: star3.normalized_coord))
                    )
                    allTSM.append(tsm)
                }
                let s3Opts2 = findS3(s1: star2, s2: star1, s1s3Stars: s2s3Matches, s2s3Stars: s1s3Matches)
                for star3 in s3Opts2 {
                    let tsm = TriangleStarMatch(
                        star1: StarEntry(star: star2, vec: RotatedVector(cam: star2Coord, catalog: star2.normalized_coord)),
                        star2: StarEntry(star: star1, vec: RotatedVector(cam: star1Coord, catalog: star1.normalized_coord)),
                        star3: StarEntry(star: star3, vec: RotatedVector(cam: star3Coord, catalog: star3.normalized_coord))
                    )
                    allTSM.append(tsm)
                }
            }
        }
        return allTSM
    }
    
    //        var s1s2MatchesIterator = s1s2Matches.makeIterator()
    //        var star1MatchesIterator: DeterministicSet<MinimalStar>.Iterator? = nil
    //        var s3OptsIterator1: DeterministicSet<MinimalStar>.Iterator? = nil
    //        var s3OptsIterator2: DeterministicSet<MinimalStar>.Iterator? = nil
    //
    //        return AnyIterator {
    //            while let (star1, star1Matches) = s1s2MatchesIterator.next() {
    //                if star1MatchesIterator == nil {
    //                    star1MatchesIterator = star1Matches.makeIterator()
    //                }
    //
    //                if star1.hr == 153 {
    //                    print()
    //                }
    //
    //                while let star2 = star1MatchesIterator?.next() {
    //                    if (star1.hr == 153 && star2.hr == 464) {
    //                        print()
    //                    }
    //                    if (star1.hr == 464 && star2.hr == 153) {
    //                        print()
    //                    }
    //
    //                    if s3OptsIterator1 == nil {
    //                        let s3Opts = findS3(s1: star1, s2: star2, s1s3Stars: s1s3Matches, s2s3Stars: s2s3Matches)
    //                        s3OptsIterator1 = s3Opts.makeIterator()
    //                    }
    //
    //                    while let star3 = s3OptsIterator1?.next() {
    //                        let tsm = TriangleStarMatch(
    //                            star1: StarEntry(star: star1, vec: RotatedVector(cam: star1Coord, catalog: star1.normalized_coord)),
    //                            star2: StarEntry(star: star2, vec: RotatedVector(cam: star2Coord, catalog: star2.normalized_coord)),
    //                            star3: StarEntry(star: star3, vec: RotatedVector(cam: star3Coord, catalog: star3.normalized_coord))
    //                        )
    //                        return tsm
    //                    }
    //                    s3OptsIterator1 = nil
    //
    //                    if s3OptsIterator2 == nil {
    //                        let s3Opts = findS3(s1: star2, s2: star1, s1s3Stars: s2s3Matches, s2s3Stars: s1s3Matches)
    //                        s3OptsIterator2 = s3Opts.makeIterator()
    //                    }
    //
    //                    while let star3 = s3OptsIterator2?.next() {
    //                        let tsm = TriangleStarMatch(
    //                            star1: StarEntry(star: star2, vec: RotatedVector(cam: star2Coord, catalog: star2.normalized_coord)),
    //                            star2: StarEntry(star: star1, vec: RotatedVector(cam: star1Coord, catalog: star1.normalized_coord)),
    //                            star3: StarEntry(star: star3, vec: RotatedVector(cam: star3Coord, catalog: star3.normalized_coord))
    //                        )
    //                        return tsm
    //                    }
    //                    s3OptsIterator2 = nil
    //                }
    //                star1MatchesIterator = nil
    //            }
    //            return nil
    //        }
    //    }
}

/// An iterator that returns the next star combination to try using the indexing algorithm in https://onlinelibrary.wiley.com/doi/abs/10.1002/j.2161-4296.2004.tb00349.x
/// There are two objectives:
/// 1) Avoid sampling the same stars (which might be false positives)
/// 2) Avoid generating all combinations (which can be expensive as it is N choose 3) if they are not needed.
public func starLocsGenerator(n: Int) -> AnyIterator<(Int, Int, Int)> {
    assert(n >= 3)
    // NOTE: The implementation below just copies the 1-based indexing from the paper, then corrects it
    // when returning a result
    var dj = 1
    var dk = 1
    var i = 1
    return AnyIterator {
        if dj == n - 1 {
            return nil
        }
        let result = (i - 1, i + dj - 1, i + dj + dk - 1)
        i += 1
        if i == n - dj - dk + 1 {
            i = 1
            dk += 1
            if dk == n - dj {
                i = 1
                dk = 1
                dj += 1
            }
        }
        return result
    }
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
func findS3(s1: MinimalStar, s2: MinimalStar, s1s3Stars: OrderedDictionary<MinimalStar, DeterministicSet<MinimalStar>>, s2s3Stars: OrderedDictionary<MinimalStar, DeterministicSet<MinimalStar>>) -> DeterministicSet<MinimalStar> {
    guard let s1s3Cands = s1s3Stars[s1] else {
        return DeterministicSet()
    }
    guard let s2s3Cands = s2s3Stars[s2] else {
        return DeterministicSet()
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
    let star: MinimalStar
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
