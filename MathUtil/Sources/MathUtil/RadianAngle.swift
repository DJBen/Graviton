//
//  RadianAngle.swift
//  MathUtil
//
//  Created by Sihao Lu on 12/27/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import Foundation

public class RadianAngle: Angle {
    public enum WrapMode {
        case none
        /// Wrap angle within (-π, π].
        case range_π
        /// Wrap angle within [0, 2π).
        case range0_2π

        var wrap: (Double) -> Double {
            switch self {
            case .none:
                return { $0 }
            case .range_π:
                return { (value) in
                    let twoPi = Double.pi * 2
                    var wrapped = fmod(value, twoPi)
                    if wrapped < 0.0 {
                        wrapped += twoPi
                    }
                    if wrapped > Double.pi {
                        wrapped -= twoPi
                    }
                    return wrapped
                }
            case .range0_2π:
                return { (value) in
                    let twoPi = Double.pi * 2
                    var wrapped = fmod(value, twoPi)
                    if wrapped < 0.0 {
                        wrapped += twoPi
                    }
                    return wrapped
                }
            }
        }
    }

    override class var converter: AngleConverter.Type {
        return RadianAngleConverter.self
    }

    public var wrapMode: WrapMode = .range0_2π

    public override var wrappedValue: Double {
        return wrapMode.wrap(value)
    }
    
    // MARK: - Protocol conformances
    public static func ==(lhs: RadianAngle, rhs: RadianAngle) -> Bool {
        let mode = WrapMode.range0_2π
        return mode.wrap(lhs.value) == mode.wrap(rhs.value)
    }

    public override var description: String {
        return "\(wrappedValue) rad"
    }
}

class RadianAngleConverter: AngleConverter {
    override class func valueFromHour(_ hour: Double) -> Double {
        return hour / 12 * Double.pi
    }

    override class func valueFromRadian(_ radian: Double) -> Double {
        return radian
    }

    override class func valueFromDegree(_ degree: Double) -> Double {
        return degree / 180 * Double.pi
    }
}
