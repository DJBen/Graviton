//
//  VectorMath+CoreGraphics.swift
//  Graviton
//
//  Created by Ben Lu on 2/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation

fileprivate func transform(v: CGVector, transform: (CGFloat) -> CGFloat) -> CGVector {
    return CGVector(dx: transform(v.dx), dy: transform(v.dy))
}

public func *(v: CGVector, s: CGFloat) -> CGVector {
    return transform(v: v) { $0 * s }
}

public func /(v: CGVector, s: CGFloat) -> CGVector {
    return transform(v: v) { $0 / s }
}

public func *(p: CGSize, s: CGFloat) -> CGSize {
    return CGSize(width: p.width * s, height: p.height * s)
}

public func +(p: CGPoint, v: CGVector) -> CGPoint {
    return CGPoint(x: p.x + v.dx, y: p.y + v.dy)
}

public func -(p: CGPoint, p2: CGPoint) -> CGVector {
    return CGVector(dx: p.x - p2.x, dy: p.y - p2.y)
}

public func -(p: CGPoint, v: CGVector) -> CGPoint {
    return p + (-v)
}

public prefix func -(p: CGPoint) -> CGPoint {
    return CGPoint(x: -p.x, y: -p.y)
}

public prefix func -(v: CGVector) -> CGVector {
    return transform(v: v, transform: -)
}

extension CGVector {
    public var length: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
}
