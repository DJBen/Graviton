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
    var starLocs = getStarLocations(img: image)
    
    // Restrict the search-space to 20 stars to avoid generating too many combinations
    var starLocsRng = SeededGenerator(seed: 7)
    starLocs.shuffle(using: &starLocsRng)
    let chosenStarLocs = starLocs.prefix(20)
    
    // Generate random combinations of 3 stars to test.
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
    let angleDelta = 0.017453 // 1 degree of tolerance
    let width = Int(image.size.width.rounded())
    let height = Int(image.size.height.rounded())
    let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
    for (i, j, k) in starCombos.prefix(maxStarCombosToTry) {
        let star1 = pix2ray.pix2Ray(pix: chosenStarLocs[i])
        let star2 = pix2ray.pix2Ray(pix: chosenStarLocs[j])
        let star3 = pix2ray.pix2Ray(pix: chosenStarLocs[k])
        let start = Date()
        // can take up to a second
        let all_sm = findStarMatches(star1Coord: star1, star2Coord: star2, star3Coord: star3, angleDelta: angleDelta)
        let end = Date()
        let timeInterval: Double = end.timeIntervalSince(start)
        print("Total time taken to find matches: \(timeInterval) seconds")
        for sm in all_sm {
            // Transformation from Reference (R) to Camera (C)
            let T_C_R = solveWahba(star1Cam: star1, star1Catalog: sm.star1.physicalInfo.coordinate, star2Cam: star2, star2Catalog: sm.star2.physicalInfo.coordinate, star3Cam: star3, star3Catalog: sm.star3.physicalInfo.coordinate)
            if testAttitude(starLocs: chosenStarLocs, pix2Ray: pix2ray, T_C_R: T_C_R, angleDelta: angleDelta) {
                return T_C_R
            }
        }
    }
    return nil
}

func solveWahba(star1Cam: Vector3, star1Catalog: Vector3, star2Cam: Vector3, star2Catalog: Vector3, star3Cam: Vector3, star3Catalog: Vector3) -> Matrix {
    var B = Matrix(3, 3, 0.0)
    
    let s1Cam = star1Cam.toMatrix()
    let s1Cat = star1Catalog.toMatrix()
    B = B + s1Cam * s1Cat.T
    
    let s2Cam = star2Cam.toMatrix()
    let s2Cat = star2Catalog.toMatrix()
    B = B + s2Cam * s2Cat.T
    
    let s3Cam = star3Cam.toMatrix()
    let s3Cat = star3Catalog.toMatrix()
    B = B + s3Cam * s3Cat.T
    
    let (U, _, V) = svd(B)
    return U * diag([1, 1, det(U) * det(V)]) * V.T
}

func testAttitude(starLocs: ArraySlice<StarLocation>, pix2Ray: Pix2Ray, T_C_R: Matrix, angleDelta: Double) -> Bool {
    let T_R_C = T_C_R.T
    var matched_stars = 0
    let required_matched_stars = Int(0.9 * Double(starLocs.count))
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
public func findStarMatches(star1Coord: Vector3, star2Coord: Vector3, star3Coord: Vector3, angleDelta: Double) -> [StarMatch] {
    let thetaS1S2 = acos(star1Coord.dot(star2Coord))
    let thetaS1S3 = acos(star1Coord.dot(star3Coord))
    let thetaS2S3 = acos(star2Coord.dot(star3Coord))
    let s1s2Matches = getMatches(angle: thetaS1S2, angleDelta: angleDelta)!
    let s1s3Matches = getMatches(angle: thetaS1S3, angleDelta: angleDelta)!
    let s2s3Matches = getMatches(angle: thetaS2S3, angleDelta: angleDelta)!
    
    var star_matches: [StarMatch] = [];
    for (star1, star1Matches) in s1s2Matches {
        for star2 in star1Matches {
            // Assume star1 corresponds to the first star in the star pair
            let s3Opts1 = findS3(s1: star1, s2: star2, s1s3Stars: s1s3Matches, s2s3Stars: s2s3Matches)
            if s3Opts1.count > 0 {
                for s3 in s3Opts1 {
                    star_matches.append(StarMatch(star1: star1, star2: star2, star3: s3))
                }
            }
    
            // Assume star1 corresponds to the second star in the star pair
            let s3Opts2 = findS3(s1: star2, s2: star1, s1s3Stars: s1s3Matches, s2s3Stars: s2s3Matches)
            if s3Opts2.count > 0 {
                for s3 in s3Opts2 {
                    star_matches.append(StarMatch(star1: star2, star2: star1, star3: s3))
                }
            }
        }
    }
    return star_matches
}

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

public struct StarMatch {
    let star1: Star
    let star2: Star
    let star3: Star
    
    init(star1: Star, star2: Star, star3: Star) {
        self.star1 = star1
        self.star2 = star2
        self.star3 = star3
    }
}
