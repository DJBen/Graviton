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

public func get_matches(angle: Double, angle_delta: Double) -> [StarAngle]? {
    let query = StarryNight.StarAngles.table.filter(StarryNight.StarAngles.angle < angle + angle_delta/2 && StarryNight.StarAngles.angle > angle - angle_delta/2)
    do {
        let rows = try StarryNight.db.prepare(query)
        let star_angles = rows.compactMap { StarAngle(row: $0) }
        return star_angles
    } catch {
        print("SQLite operation failed: \(error)")
        return nil
    }
}

public struct StarAngle {
    public let star1: Star
    public let star2: Star
    public let angle: Double
    
    public init(row: Row) {
        self.star1 = Star.hr(try! row.get(StarryNight.StarAngles.star1Hr)!)!
        self.star2 = Star.hr(try! row.get(StarryNight.StarAngles.star2Hr)!)!
        self.angle = try! row.get(StarryNight.StarAngles.angle)
    }
}
