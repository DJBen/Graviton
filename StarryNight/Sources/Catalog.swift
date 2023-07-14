//
//  catalog.swift
//  Graviton
//
//  Created by Jatin Mathur on 7/7/23.
//  Copyright © 2023 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime
import SQLite
import MathUtil
import Collections

public class Catalog {
    let kvector: KVector<StarAngle>
    
    init() {
        let start = Date()
        let query = StarryNight.StarAngles.table
        do {
            let rows = try StarryNight.db.prepare(query)
            var angles: [(Double, StarAngle)] = []
            for row in rows {
                let sa = StarAngle(row: row)
                angles.append((sa.angle, sa))
            }
            self.kvector = KVector(data: &angles)
        } catch {
            print("SQLite operation failed: \(error)")
            var data: [(Double, StarAngle)] = []
            self.kvector = KVector(data: &data)
        }
        let end = Date()
        let dt = end.timeIntervalSince(start)
        print("catalog time \(dt)")
    }
    
    /// Search database for star pairs that have the given pairwise angle (within +/- `angleDelta` tolerance)
    public func getMatches(angle: Double, angleDelta: Double) -> [MinimalStar:OrderedSet<MinimalStar>] {
        let res = self.kvector.getData(lower: angle - angleDelta, upper: angle + angleDelta)
        
        var starAngles: [MinimalStar:OrderedSet<MinimalStar>] = [:]
        for (_, sa) in res {
            // Insert for both stars as it could be queried either way
            if starAngles[sa.star1] == nil {
                starAngles[sa.star1] = OrderedSet()
            }
            starAngles[sa.star1]!.append(sa.star2)
            
            if starAngles[sa.star2] == nil {
                starAngles[sa.star2] = OrderedSet()
            }
            starAngles[sa.star2]!.append(sa.star1)
        }
        return starAngles
    }
}

public struct StarAngle {
    let star1: MinimalStar
    let star2: MinimalStar
    let angle: Double
    
    public init(row: Row) {
        let star1_hr = try! row.get(StarryNight.StarAngles.star1Hr)!
        let star2_hr = try! row.get(StarryNight.StarAngles.star2Hr)!
        self.angle = try! row.get(StarryNight.StarAngles.angle)
        let star1_coord = Vector3(try! row.get(StarryNight.StarAngles.star1_x), try! row.get(StarryNight.StarAngles.star1_y), try! row.get(StarryNight.StarAngles.star1_z))
        let star2_coord = Vector3(try! row.get(StarryNight.StarAngles.star2_x), try! row.get(StarryNight.StarAngles.star2_y), try! row.get(StarryNight.StarAngles.star2_z))
        self.star1 = MinimalStar(hr: star1_hr, coord: star1_coord)
        self.star2 = MinimalStar(hr: star2_hr, coord: star2_coord)
    }
}

public struct MinimalStar: Hashable, Equatable {
    let hr: Int
    let coord: Vector3
    
    public init(hr: Int, coord: Vector3) {
        self.hr = hr
        self.coord = coord
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.hr)
    }
    
    public static func ==(lhs: MinimalStar, rhs: MinimalStar) -> Bool {
        return lhs.hr == rhs.hr
    }
}

// for testing...
public func getAllStarAngles(lower: Double, upper: Double) -> [(Double, (Star, Star))] {
    var actual: [(Double, (Star, Star))] = []
    let query = StarryNight.StarAngles.table.filter(
        StarryNight.StarAngles.angle < upper &&
        StarryNight.StarAngles.angle > lower
    )
    let rows = try! StarryNight.db.prepare(query)
    for row in rows {
        let star1 = Star.hr(try! row.get(StarryNight.StarAngles.star1Hr)!)!
        let star2 = Star.hr(try! row.get(StarryNight.StarAngles.star2Hr)!)!
        let angle = try! row.get(StarryNight.StarAngles.angle)
        actual.append((angle, (star1, star2)))
    }
    return actual
}
