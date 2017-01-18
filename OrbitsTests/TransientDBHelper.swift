//
//  TransientDBHelper.swift
//  Graviton
//
//  Created by Sihao Lu on 1/18/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SQLite
@testable import Orbits

class TransientDBHelper: DBHelper {
    override class func setupDatabaseHelper() -> DBHelper {
        let cb = try! Connection()
        let ob = try! Connection()
        let helper = DBHelper(celestialBodies: cb, orbitalMotions: ob)
        helper.prepareTables()
        return helper
    }
}
