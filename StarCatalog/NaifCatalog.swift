//
//  NaifCatalog.swift
//  Graviton
//
//  Created by Sihao Lu on 1/9/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SQLite

public class NaifCatalog {
    private static let databasePath = Bundle(for: NaifCatalog.self).path(forResource: "naif", ofType: "sqlite3")!
    private static var db: Connection = {
        return try! Connection(NaifCatalog.databasePath)
    }()
    
    public static func name(forNaif naif: Int) -> String? {
        let table = Table("naif_codes")
        let id = Expression<Int64>("naif_id")
        let name = Expression<String>("body_name")
        let query = table.select(name).filter(id == Int64(naif)).limit(1)
        guard let row = try! db.pluck(query) else {
            return nil
        }
        return row[name]
    }
}
