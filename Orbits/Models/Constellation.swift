//
//  Constellation.swift
//  Orbits
//
//  Created by Ben Lu on 2/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SQLite

fileprivate let db = try! Connection(Bundle(for: DBHelper.self).path(forResource: "stars", ofType: "sqlite3")!)
fileprivate let constel = Table("constellations")
fileprivate let dbName = Expression<String>("constellation")
fileprivate let dbIAUName = Expression<String>("iau")
fileprivate let dbGenitive = Expression<String>("genitive")

public struct Constellation {
    public let name: String
    public let iAUName: String
    public let genitive: String
    
    private init(name: String, iAUName: String, genitive: String) {
        self.name = name
        self.iAUName = iAUName
        self.genitive = genitive
    }
    
    public static func named(_ name: String) -> Constellation? {
        let query = constel.select(dbName, dbIAUName, dbGenitive).filter(dbName == name)
        if let row = try! db.pluck(query) {
            return Constellation(name: row.get(dbName), iAUName: row.get(dbIAUName), genitive: row.get(dbGenitive))
        }
        return nil
    }
    
    public static func iau(_ iau: String) -> Constellation? {
        let query = constel.select(dbName, dbIAUName, dbGenitive).filter(dbIAUName == iau)
        if let row = try! db.pluck(query) {
            return Constellation(name: row.get(dbName), iAUName: row.get(dbIAUName), genitive: row.get(dbGenitive))
        }
        return nil
    }
}


