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
import KDTree

public class Catalog {
    let kvector: KVector<StarAngle>
    let kdtree: KDTree<MinimalStar>
    
    init() {
        let start = Date()
        let query = StarryNight.StarAngles.table
        var uniqueStars: DeterministicSet<MinimalStar> = DeterministicSet()
        do {
            let rows = try StarryNight.db.prepare(query)
            var angles: [(Double, StarAngle)] = []
            for row in rows {
                let sa = StarAngle(row: row)
                angles.append((sa.angle, sa))
                uniqueStars.append(sa.star1)
                uniqueStars.append(sa.star2)
            }
            self.kvector = KVector(data: &angles)
        } catch {
            print("SQLite operation failed: \(error)")
            var data: [(Double, StarAngle)] = []
            self.kvector = KVector(data: &data)
        }
        let end = Date()
        let dt = end.timeIntervalSince(start)
        
        self.kdtree = KDTree(values: uniqueStars.arrayRepresentation())
        
        print("catalog time \(dt)")
    }
    
    /// Search database for star pairs that have the given pairwise angle (within +/- `angleDelta` tolerance)
    public func getMatches(angle: Double, angleDelta: Double) -> OrderedDictionary<MinimalStar, DeterministicSet<MinimalStar>> {
        let res = self.kvector.getData(lower: angle - angleDelta, upper: angle + angleDelta)
        
        var starAngles: OrderedDictionary<MinimalStar, DeterministicSet<MinimalStar>> = OrderedDictionary()
        for (_, sa) in res {
            // Insert for both stars as it could be queried either way
            if starAngles[sa.star1] == nil {
                starAngles[sa.star1] = DeterministicSet()
            }
            starAngles[sa.star1]!.append(sa.star2)
            
            if starAngles[sa.star2] == nil {
                starAngles[sa.star2] = DeterministicSet()
            }
            starAngles[sa.star2]!.append(sa.star1)
        }
        return starAngles
    }
    
    /// Search database for nearby stars
    public func findNearbyStars(coord: Vector3, angleDelta: Double?) -> MinimalStar? {
        let ms = MinimalStar(hr: 0, coord: coord)
        let nearest = self.kdtree.nearest(to: ms)
        guard let nearest = nearest else {
            return nil
        }
        guard let angleDelta = angleDelta else {
            return nearest
        }
        let angle = acos(nearest.normalized_coord.dot(ms.normalized_coord))
        if angle < angleDelta {
            return nearest
        } else {
            return nil
        }
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

public struct MinimalStar: Hashable, Equatable, KDTreePoint {
    let hr: Int
    // Normalized 3D coordinated
    let normalized_coord: Vector3
    
    public init(hr: Int, coord: Vector3) {
        self.hr = hr
        self.normalized_coord = coord.normalized()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.hr)
    }
    
    public static func ==(lhs: MinimalStar, rhs: MinimalStar) -> Bool {
        return lhs.hr == rhs.hr
    }
    
    // Implement KDTreePoint
    public static var dimensions: Int {
        3
    }
    
    public func kdDimension(_ dimension: Int) -> Double {
        if dimension == 0 {
            return self.normalized_coord.x
        } else if dimension == 1{
            return self.normalized_coord.y
        } else if dimension == 2 {
            return self.normalized_coord.z
        }
        fatalError("Startracker KDTree cannot query dimension \(dimension)")
    }
    
    public func squaredDistance(to otherPoint: Self) -> Double {
        return pow(self.normalized_coord.x - otherPoint.normalized_coord.x, 2) + pow(self.normalized_coord.y - otherPoint.normalized_coord.y, 2) + pow(self.normalized_coord.z - otherPoint.normalized_coord.z, 2)
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
