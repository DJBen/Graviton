//
//  DegreeAngle.swift
//  MathUtil
//
//  Created by Sihao Lu on 12/27/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import Foundation

public class DegreeAngle: Angle, CompoundAngle {
    public enum WrapMode {
        case none
        /// Wrap angle within (-180°, 180°].
        case range_180
        /// Wrap angle within [0°, 360°).
        case range0_360

        var wrap: (Double) -> Double {
            switch self {
            case .none:
                return { $0 }
            case .range_180:
                return { (value) in
                    var wrapped = fmod(value, 360)
                    if wrapped < 0.0 {
                        wrapped += 360
                    }
                    if wrapped > 180 {
                        wrapped -= 360
                    }
                    return wrapped
                }
            case .range0_360:
                return { (value) in
                    var wrapped = fmod(value, 360)
                    if wrapped < 0.0 {
                        wrapped += 360
                    }
                    return wrapped
                }
            }
        }
    }

    public override var description: String {
        return "\(wrappedValue)°"
    }

    override class var converter: AngleConverter.Type {
        return DegreeAngleConverter.self
    }

    public var wrapMode: WrapMode = .range0_360

    public override var wrappedValue: Double {
        return wrapMode.wrap(value)
    }

    public var degreeComponent: Double {
        return components[0]
    }

    public var minuteComponent: Double {
        return components[1]
    }

    public var secondComponent: Double {
        return components[2]
    }

    public var inMinutes: Double {
        return wrappedValue * 60
    }

    public var inSeconds: Double {
        return wrappedValue * 3600
    }

    public convenience init(degree: Double = 0, minute: Double = 0, second: Double = 0) {
        let fractionalDegree = degree + minute / 60 + second / 3600
        self.init(fractionalDegree)
    }

    // MARK: - Compound angle

    public var compoundDecimalNumberFormatter: NumberFormatter?

    public var sign: Int {
        return wrappedValue >= 0 ? 1 : -1
    }

    public var components: [Double] {
        let unsignedValue = Double(sign) * wrappedValue
        let (degree, fracMin) = modf(unsignedValue)
        let (minute, secondInMin) = modf(fracMin * 60)
        return [
            degree,
            minute,
            secondInMin * 60
        ]
    }

    public var compoundDescription: String {
        return (sign < 0 ? "-" : "") + "\(Int(components[0]))° \(Int(components[1]))′ \(compoundDecimalNumberFormatter?.string(from: components[2] as NSNumber)! ?? String(components[2]))″"
    }
}

class DegreeAngleConverter: AngleConverter {
    override class func valueFromHour(_ hour: Double) -> Double {
        return hour / 12 * 180
    }

    override class func valueFromRadian(_ radian: Double) -> Double {
        return radian / Double.pi * 180
    }

    override class func valueFromDegree(_ degree: Double) -> Double {
        return degree
    }
}
