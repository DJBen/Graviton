//
//  Functional.swift
//  Graviton
//
//  Created by Ben Lu on 4/21/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

func nullable<T>(_ block: @escaping (T) -> T) -> ((T?) -> T?) {
    return { (value: T?) -> T? in
        guard let v = value else { return nil }
        return block(v)
    }
}

func pairs<K, V>(fromDict dict: [K: V]) -> [(K, V)] {
    var pairs = [(K, V)]()
    dict.forEach { pairs.append(($0.key, $0.value)) }
    return pairs
}
