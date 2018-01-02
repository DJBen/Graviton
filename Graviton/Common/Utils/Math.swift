//
//  Math.swift
//  Graviton
//
//  Created by Sihao Lu on 6/15/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil

extension Double {
    func cap(toRange range: Range<Double>) -> Double {
        return min(max(range.lowerBound, self), range.upperBound)
    }
}
