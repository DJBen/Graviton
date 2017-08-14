//
//  Assertions.swift
//  Graviton
//
//  Created by Sihao Lu on 8/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation

public func assertMainThread(_ file: StaticString = #file, line: UInt = #line) {
    assert(Thread.isMainThread, "Code at \(file):\(line) must run on main thread!")
}
