//
//  Functional.swift
//  Graviton
//
//  Created by Ben Lu on 5/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

extension Dictionary where Key: Comparable {
    func keyOrderMap<T>(_ transform: @escaping ((key: Key, value: Value)) throws -> T) rethrows -> [T] {
        return try keys.sorted().map { try transform(($0, self[$0]!)) }
    }
}
