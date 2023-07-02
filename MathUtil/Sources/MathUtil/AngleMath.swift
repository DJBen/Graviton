//
//  AngleMath.swift
//  MathUtil
//
//  Created by Sihao Lu on 12/27/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import Foundation

public prefix func -<T: Angle>(angle: T) -> T {
    return T.init(-angle.value)
}

public func +<T: Angle>(lhs: T, rhs: T) -> T {
    return T.init(lhs.value + rhs.value)
}

public func -<T: Angle>(lhs: T, rhs: T) -> T {
    return T.init(lhs.value - rhs.value)
}

public func *<T: Angle>(angle: T, constant: Double) -> T {
    return T.init(angle.value * constant)
}

public func /<T: Angle>(angle: T, constant: Double) -> T {
    return T.init(angle.value / constant)
}

public func +=<T: Angle>(lhs: inout T, rhs: T) {
    lhs.value += rhs.value
}

public func -=<T: Angle>(lhs: inout T, rhs: T) {
    lhs.value -= rhs.value
}

public func *=<T: Angle>(lhs: inout T, constant: Double) {
    lhs.value *= constant
}

public func /=<T: Angle>(lhs: inout T, constant: Double) {
    lhs.value /= constant
}

public func sin(_ angle: Angle) -> Double {
    return sin(RadianAngle.converter.valueFromAngle(angle))
}

public func cos(_ angle: Angle) -> Double {
    return cos(RadianAngle.converter.valueFromAngle(angle))
}

public func sinh(_ angle: Angle) -> Double {
    return sinh(RadianAngle.converter.valueFromAngle(angle))
}

public func cosh(_ angle: Angle) -> Double {
    return cosh(RadianAngle.converter.valueFromAngle(angle))
}

public func tan(_ angle: Angle) -> Double {
    return tan(RadianAngle.converter.valueFromAngle(angle))
}

public func tanh(_ angle: Angle) -> Double {
    return tanh(RadianAngle.converter.valueFromAngle(angle))
}
