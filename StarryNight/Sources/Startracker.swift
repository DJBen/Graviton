//
//  File.swift
//  
//
//  Created by Jatin Mathur on 7/7/23.
//

import Foundation
import MathUtil

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
