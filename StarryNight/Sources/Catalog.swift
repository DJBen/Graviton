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

/// Search database for star pairs that have the given pairwise angle (within +/- `angleDelta/2` tolerance)
public func getMatches(angle: Double, angleDelta: Double) -> [Star:Set<Star>]? {
    let query = StarryNight.StarAngles.table.filter(
        StarryNight.StarAngles.angle < angle + angleDelta/2 &&
        StarryNight.StarAngles.angle > angle - angleDelta/2
    )
    do {
        let rows = try StarryNight.db.prepare(query)
        var starAngles: [Star:Set<Star>] = [:]
        
        for row in rows {
            let star1 = Star.hr(try! row.get(StarryNight.StarAngles.star1Hr)!)!
            let star2 = Star.hr(try! row.get(StarryNight.StarAngles.star2Hr)!)!
            let angle = try! row.get(StarryNight.StarAngles.angle)
            if starAngles[star1] == nil {
                starAngles[star1] = Set()
            }
            starAngles[star1]?.insert(star2)
        }
        return starAngles
    } catch {
        print("SQLite operation failed: \(error)")
        return nil
    }
}
