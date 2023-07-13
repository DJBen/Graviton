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

public class Catalog {
    let kvector: KVector<(Star, Star)>
    
    init() {
        let start = Date()
        let query = StarryNight.StarAngles.table
        do {
            let rows = try StarryNight.db.prepare(query)
            var angles: [(Double, (Star, Star))] = []
            for row in rows {
                // TODO: not load everything
//                let star1 = MinimalStar(hr: try! row.get(StarryNight.StarAngles.star1Hr)!)
//                let star2 = MinimalStar(hr: try! row.get(StarryNight.StarAngles.star2Hr)!)
                let star1 = Star.hr(try! row.get(StarryNight.StarAngles.star1Hr)!)!
                let star2 = Star.hr(try! row.get(StarryNight.StarAngles.star2Hr)!)!
                let angle = try! row.get(StarryNight.StarAngles.angle)
                angles.append((angle, (star1, star2)))
            }
            self.kvector = KVector(data: &angles)
        } catch {
            print("SQLite operation failed: \(error)")
            var data: [(Double, (Star, Star))] = []
            self.kvector = KVector(data: &data)
        }
        let end = Date()
        let dt = end.timeIntervalSince(start)
        print("catalog time \(dt)")
    }
    
    public func getMatches(angle: Double, angleDelta: Double) -> [Star:Set<Star>] {
        let res = self.kvector.getData(lower: angle - angleDelta, upper: angle + angleDelta)
        
        var starAngles: [Star:Set<Star>] = [:]
        for (_, (star1, star2)) in res {
            // Insert for both stars as it could be queried either way
            if starAngles[star1] == nil {
                starAngles[star1] = Set()
            }
            starAngles[star1]!.insert(star2)
            
            if starAngles[star2] == nil {
                starAngles[star2] = Set()
            }
            starAngles[star2]!.insert(star1)
        }
        return starAngles
    }
}

public func getAllStarAngles(lower: Double, upper: Double) -> [(Double, (Star, Star))] {
    var actual: [(Double, (Star, Star))] = []
    let query = StarryNight.StarAngles.table.filter(
        StarryNight.StarAngles.angle < upper &&
        StarryNight.StarAngles.angle > lower
    )
    let rows = try! StarryNight.db.prepare(query)
    for row in rows {
//        let star1 = MinimalStar(hr: try! row.get(StarryNight.StarAngles.star1Hr)!)
//        let star2 = MinimalStar(hr: try! row.get(StarryNight.StarAngles.star2Hr)!)
        let star1 = Star.hr(try! row.get(StarryNight.StarAngles.star1Hr)!)!
        let star2 = Star.hr(try! row.get(StarryNight.StarAngles.star2Hr)!)!
        let angle = try! row.get(StarryNight.StarAngles.angle)
        actual.append((angle, (star1, star2)))
    }
    return actual
}

//public struct MinimalStar {
//    let hr: Int
//    let coordinate: Vector3
//
//    init(hr: Int) {
//        let query = StarryNight.Stars.table.filter(StarryNight.Stars.dbHr == hr)
//        let row = try! StarryNight.db.pluck(query)!
//        self.hr = hr
//        self.coordinate = Vector3(try! row.get(StarryNight.Stars.dbX), try! row.get(StarryNight.Stars.dbY), try! row.get(StarryNight.Stars.dbZ))
//    }
//}

/// Search database for star pairs that have the given pairwise angle (within +/- `angleDelta` tolerance)
public func getMatches(angle: Double, angleDelta: Double) -> [Star:Set<Star>]? {
    let query = StarryNight.StarAngles.table.filter(
        StarryNight.StarAngles.angle < angle + angleDelta &&
        StarryNight.StarAngles.angle > angle - angleDelta
    )
    do {
        let start = Date()
        let rows = try StarryNight.db.prepare(query)
        let end = Date()
        let dt = end.timeIntervalSince(start)
        print("prepare \(dt)")
        var starAngles: [Star:Set<Star>] = [:]
        
        var allQueries: Double = 0
        for row in rows {
            let start = Date()
            let star1 = Star.hr(try! row.get(StarryNight.StarAngles.star1Hr)!)!
            let star2 = Star.hr(try! row.get(StarryNight.StarAngles.star2Hr)!)!
            let end = Date()
            allQueries += end.timeIntervalSince(start)
            
            // Insert for both stars as it could be queried either way
            if starAngles[star1] == nil {
                starAngles[star1] = Set()
            }
            starAngles[star1]?.insert(star2)
            
            if starAngles[star2] == nil {
                starAngles[star2] = Set()
            }
            starAngles[star2]?.insert(star1)
        }
        print("prepareAQ \(allQueries)")
        return starAngles
    } catch {
        print("SQLite operation failed: \(error)")
        return nil
    }
}
