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
    var starLocs = image.getStarLocations()
//    var starGen = SeededGenerator(seed: 7)
//    starLocs.shuffle(using: &starGen)
    let chosenStarLocs = starLocs.prefix(50)
    
    var starCombos: [(Int, Int, Int)] = []
    for i in 0..<chosenStarLocs.count {
        for j in (i + 1)..<chosenStarLocs.count {
            for k in (j + 1)..<chosenStarLocs.count {
                starCombos.append((i,j,k))
            }
        }
    }
//    var starComboGen = SeededGenerator(seed: 7)
//    starCombos.shuffle(using: &starComboGen)
    
    let angle_thresh = 0.005 //0.017453 // 1 degree of tolerance
    let width = Int(image.size.width.rounded())
    let height = Int(image.size.height.rounded())
    let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
    for (i, j, k) in starCombos {
        let star1 = pix2ray.pix2Ray(pix: chosenStarLocs[i])
        let star2 = pix2ray.pix2Ray(pix: chosenStarLocs[j])
        let star3 = pix2ray.pix2Ray(pix: chosenStarLocs[k])
        let all_sm = find_all_star_matches(star_coord1: star1, star_coord2: star2, star_coord3: star3, angle_thresh: angle_thresh)
        for sm in all_sm {
            let T_CR = solveWahba(star1Cam: star1, star1Catalog: sm.star1.physicalInfo.coordinate, star2Cam: star2, star2Catalog: sm.star2.physicalInfo.coordinate, star3Cam: star3, star3Catalog: sm.star3.physicalInfo.coordinate)
            if testAttitude(starLocs: chosenStarLocs, pix2Ray: pix2ray, T_CR: T_CR, angle_thresh: angle_thresh) {
                print("FOUND ATTITUDE \(T_CR)")
                return T_CR
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

func testAttitude(starLocs: ArraySlice<(Int, Int)>, pix2Ray: Pix2Ray, T_CR: Matrix, angle_thresh: Double) -> Bool {
    let T_RC = T_CR.T
    var matched_stars = 0
    let expected_matched_stars = Int(0.9 * Double(starLocs.count))
    for sloc in starLocs {
        let sray_C = pix2Ray.pix2Ray(pix: sloc).toMatrix()
        let _sray_R = T_RC * sray_C
        let sray_R = Vector3(_sray_R[0,0], _sray_R[1, 0], _sray_R[2, 0])
        let nearest_star = Star.closest(to: sray_R)
        guard let nearest_star = nearest_star else {
            continue
        }
        let ang_dist = nearest_star.physicalInfo.coordinate.angularSeparation(from: sray_R)
        if abs(ang_dist) < angle_thresh {
            matched_stars += 1
        }
    }
    return matched_stars >= expected_matched_stars
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

struct SeededGenerator: RandomNumberGenerator {
    let seed: Int

    init(seed: Int) {
        self.seed = seed
    }

    func next() -> UInt64 {
        var rng = SystemRandomNumberGenerator()
        var next = rng.next()
        next ^= UInt64(seed)
        return next
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
    
    func pix2Ray(pix: (Int, Int)) -> Vector3 {
        let ray = self.intrinsics_inv * Matrix(Vector([Double(pix.0), Double(pix.1), 1.0]))
        return Vector3(ray[0,0], ray[1,0], ray[2,0]).normalized()
    }
}

extension UIImage {
    func getStarLocations() -> [(Int, Int)] {
        let image = convertToGrayscale(self)!
        let cgImg = image.cgImage!;
        let pixelData = cgImg.dataProvider?.data!
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var hasAlpha: Bool = false;
        var grayscale_idx: Int = 0;
        switch cgImg.alphaInfo {
            case .none:
                break
            case .premultipliedLast, .last:
                hasAlpha = true;
            case .premultipliedFirst, .first:
                hasAlpha = true;
                grayscale_idx = 1
            case .noneSkipFirst:
                grayscale_idx = 1;
            case .noneSkipLast:
                break
            default:
                print("Could not determine alpha?")
                return [];
        }
        
        let items = hasAlpha ? 4 : 3
        
        let startTime = Date()
        var stars: [(Int, Int)] = []
        
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        var visited = Array(repeating: false, count: width * height)
        let STAR_PIX_THRESH = 230
        
        for y in 0..<height {
            for x in 0..<width {
                let posData = pix2Pos(y: y, x: x, width: width, idx_value: grayscale_idx, num_channels: items)
                let posVis = pix2Pos(y: y, x: x, width: width, idx_value: 0, num_channels: 1)
                let dataVal = data[posData]
                let isVisited = visited[posVis]
                if dataVal > STAR_PIX_THRESH && !isVisited {
                    var pixels: [(Int, Int)] = [(x, y)]
                    var stack: [(Int, Int)] = [(x, y)]
                    visited[posVis] = true
                    
                    // Run flood fill
                    while let (x, y) = stack.popLast() {
                        for dx in -1...1 {
                            for dy in -1...1 {
                                let nx = x + dx
                                let ny = y + dy
                                let nxPosData = pix2Pos(y: ny, x: nx, width: width, idx_value: grayscale_idx, num_channels: items)
                                let nxPosVis = pix2Pos(y: ny, x: nx, width: width, idx_value: 0, num_channels: 1)
                                if nx >= 0 && nx < width && ny >= 0 && ny < height && !visited[nxPosVis] && data[nxPosData] > STAR_PIX_THRESH {
                                    visited[nxPosVis] = true
                                    pixels.append((nx, ny))
                                    stack.append((nx, ny))
                                }
                            }
                        }
                    }
                    
                    // Calculate the centroid of the filled area
                    // TODO: exclude things smaller than say 10 pixels and bigger than 1000?
                    let sum = pixels.reduce((0, 0)) { ($0.0 + $1.0, $0.1 + $1.1) }
                    let centroid = (sum.0 / pixels.count, sum.1 / pixels.count)
                    stars.append(centroid)
                }
            }
        }
        let endTime = Date()
        let timeInterval: Double = endTime.timeIntervalSince(startTime)
        print("Total time taken: \(timeInterval) seconds")
        return stars
    }
}

func pix2Pos(y: Int, x: Int, width: Int, idx_value: Int, num_channels: Int) -> Int {
    return y * width * num_channels + x * num_channels + idx_value
}

func convertToGrayscale(_ image: UIImage) -> UIImage? {
    let context = CIContext(options: nil)
    if let filter = CIFilter(name: "CIPhotoEffectMono") {
        filter.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        if let output = filter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage)
        }
    }
    return nil
}


public func find_all_star_matches(star_coord1: Vector3, star_coord2: Vector3, star_coord3: Vector3, angle_thresh: Double) -> [StarMatch] {
    let theta_s1_s2 = acos(star_coord1.dot(star_coord2))
    let theta_s1_s3 = acos(star_coord1.dot(star_coord3))
    let theta_s2_s3 = acos(star_coord2.dot(star_coord3))
    let s1_s2_matches = get_matches(angle: theta_s1_s2, angle_delta: angle_thresh)!
    let s1_s3_matches = get_matches(angle: theta_s1_s3, angle_delta: angle_thresh)!
    let s2_s3_matches = get_matches(angle: theta_s2_s3, angle_delta: angle_thresh)!
    
    var star_matches: [StarMatch] = [];
    for sm in s1_s2_matches {
        let s3_opts1 = find_s3(s1: sm.star1, s2: sm.star2, s1s3List: s1_s3_matches, s2s3List: s2_s3_matches)
        if s3_opts1.count > 0 {
            for s3 in s3_opts1 {
                star_matches.append(StarMatch(star1: sm.star1, star2: sm.star2, star3: s3))
            }
        }
        
        let s3_opts2 = find_s3(s1: sm.star2, s2: sm.star1, s1s3List: s1_s3_matches, s2s3List: s2_s3_matches)
        if s3_opts2.count > 0 {
            for s3 in s3_opts2 {
                star_matches.append(StarMatch(star1: sm.star2, star2: sm.star1, star3: s3))
            }
        }
    }
    
    return star_matches
}

func find_s3(s1: Star, s2: Star, s1s3List: [StarAngle], s2s3List: [StarAngle]) -> [Star] {
    var s3_cands: [Star] = []
    for sm in s1s3List {
        if sm.star1 == s1 {
            s3_cands.append(sm.star2)
        } else if sm.star2 == s1 {
            s3_cands.append(sm.star1)
        }
    }
    if s3_cands.count == 0 {
        return [];
    }
    
    var s3_matches: [Star] = [];
    for sm in s2s3List {
        // check if any (s2,s3) pair is consistent with our s3 candidates
        if (sm.star1 == s2 && s3_cands.contains(sm.star2)) {
            s3_matches.append(sm.star2)
        }
        else if (sm.star2 == s2 && s3_cands.contains(sm.star1)) {
            s3_matches.append(sm.star1)
        }
    }
    return s3_matches
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
