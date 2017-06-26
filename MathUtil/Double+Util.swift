//
//  Double+Util.swift
//  Graviton
//
//  Created by Sihao Lu on 6/23/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

public extension Double {
    public func cap(to range: ClosedRange<Double>) -> Double {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}
