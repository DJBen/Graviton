//
//  StarryNight.swift
//  Graviton
//
//  Created by Sihao Lu on 8/12/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SwiftyBeaver
import SQLite

let logger = SwiftyBeaver.self
let db = try! Connection(Bundle(identifier: "com.Square.sihao.StarryNight")!.path(forResource: "stars", ofType: "sqlite3")!)
