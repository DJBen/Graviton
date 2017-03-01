//
//  EquatorialCoordinate+Lookup.swift
//  Graviton
//
//  Created by Sihao Lu on 3/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpaceTime
import SQLite
import MathUtil

fileprivate let db = try! Connection(Bundle(identifier: "com.Square.sihao.StarryNight")!.path(forResource: "stars", ofType: "sqlite3")!)
fileprivate let borders = Table("con_border_simple")
fileprivate let dbBorderCon = Expression<String>("con")
fileprivate let dbLowRa = Expression<Double>("low_ra")
fileprivate let dbHighRa = Expression<Double>("high_ra")
fileprivate let dbLowDec = Expression<Double>("low_dec")

public extension EquatorialCoordinate {
    public var constellation: Constellation {
        let precessed = self.precessed(from: 2000, to: 1850)
        let raHours = hours(radians: precessed.rightAscension)
        let decDegrees = degrees(radians: precessed.declination)
        let query = borders.filter(dbLowRa <= raHours && dbHighRa > raHours && dbLowDec <= decDegrees).order(dbLowDec.desc).limit(1)
        let row = try! db.pluck(query)!
        return Constellation.iau(row.get(dbBorderCon))!
    }
}
