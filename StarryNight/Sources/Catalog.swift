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

public class StarCatalog {
    public var star_angles: [StarAngle] = [];
    
    public init() {
        do {
            let rows = try StarryNight.db.prepare(StarryNight.StarAngles.table)
            self.star_angles = rows.compactMap { StarAngle(row: $0) }
        } catch {
            print("SQLite operation failed: \(error)")
        }
    }
}

public struct StarAngle {
    public let star1Hr: Int
    public let star2Hr: Int
    public let cosine_dist: Double
    
    public init(row: Row) {
        self.star1Hr = try! row.get(StarryNight.StarAngles.star1Hr)!
        self.star2Hr = try! row.get(StarryNight.StarAngles.star2Hr)!
        self.cosine_dist = try! row.get(StarryNight.StarAngles.cosine_dist)
    }
}
