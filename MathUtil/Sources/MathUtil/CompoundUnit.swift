
//
//  CompoundUnit.swift
//  MathUtil
//
//  Created by Sihao Lu on 8/5/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import Foundation

public class CompoundUnit: CustomStringConvertible {
    /// Sign bit, can be 1 or -1
    public let sign: Int
    public let values: [Double]
    public let conversion: Double
    public var decimalNumberFormatter: NumberFormatter?

    public var value: Double {
        return Double(sign) * values.enumerated().map { $1 / pow(self.conversion, Double($0)) }.reduce(0, +)
    }

    public init(value: Double) {
        fatalError("Not implemented")
    }

    init(sign: Int, values: [Double], conversion: Double) {
        self.sign = sign
        self.values = values
        self.conversion = conversion
    }

    public var description: String {
        fatalError("Not implemented")
    }
}

@available(*, deprecated)
public class HourMinuteSecond: CompoundUnit {

    /// Initialize from degrees value
    ///
    /// - Parameter value: A degree value with decimals
    public override init(value: Double) {
        let wrapped = degrees(radians: wrapAngle(radians(degrees: value)))
        let (hour, remainderMin) = modf(wrapped / 360 * 24)
        let (min, sec) = modf(remainderMin * 60)
        super.init(sign: 1, values: [hour, min, sec * 60], conversion: 60)
    }

    public override var value: Double {
        return super.value * (360 / 24)
    }

    public override var description: String {
        return "\(Int(values[0]))h \(Int(values[1]))m \(decimalNumberFormatter?.string(from: values[2] as NSNumber)! ?? String(values[2]))s"
    }
}

@available(*, deprecated)
public class DegreeMinuteSecond: CompoundUnit {

    /// Initialize from degree value
    ///
    /// - Parameter value: A degree value with decimals
    public override init(value: Double) {
        let (degree, remainderMin) = modf(value)
        let (min, sec) = modf(remainderMin * 60)
        let sign: Double = degree >= 0 && min >= 0 && sec >= 0 ? 1 : -1
        super.init(sign: Int(sign), values: [sign * degree, sign * min, sign * sec * 60], conversion: 60)
    }

    public override var description: String {
        return (sign < 0 ? "-" : "") + "\(Int(values[0]))° \(Int(values[1]))′ \(decimalNumberFormatter?.string(from: values[2] as NSNumber)! ?? String(values[2]))″"
    }
}
