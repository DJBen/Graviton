//
//  Angle.swift
//  MathUtil
//
//  Created by Sihao Lu on 12/27/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

public class Angle: Equatable, CustomStringConvertible, ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public internal(set) var value: Double

    public var wrappedValue: Double {
        fatalError("This instance variable should be subclassed")
    }

    class var converter: AngleConverter.Type {
        return AngleConverter.self
    }

    public required init(floatLiteral: FloatLiteralType) {
        self.value = floatLiteral
    }

    public required init(_ value: Double) {
        self.value = value
    }

    public convenience init(degreeAngle: DegreeAngle) {
        let converter = type(of: self).converter
        self.init(converter.valueFromDegree(degreeAngle.value))
    }

    public convenience init(radianAngle: RadianAngle) {
        let converter = type(of: self).converter
        self.init(converter.valueFromRadian(radianAngle.value))
    }

    public convenience init(hourAngle: HourAngle) {
        let converter = type(of: self).converter
        self.init(converter.valueFromHour(hourAngle.value))
    }

    // MARK: - Protocol conformances
    public static func ==(lhs: Angle, rhs: Angle) -> Bool {
        return lhs.value == rhs.value
    }

    public var description: String {
        fatalError("This instance variable should be subclassed")
    }
}

class AngleConverter {
    class func valueFromHour(_ hour: Double) -> Double {
        fatalError("This method should be subclassed")
    }

    class func valueFromRadian(_ radian: Double) -> Double {
        fatalError("This method should be subclassed")
    }

    class func valueFromDegree(_ degree: Double) -> Double {
        fatalError("This method should be subclassed")
    }

    class func valueFromAngle(_ angle: Angle) -> Double {
        if angle is RadianAngle {
            return valueFromRadian(angle.value)
        } else if angle is DegreeAngle {
            return valueFromDegree(angle.value)
        } else if angle is HourAngle {
            return valueFromHour(angle.value)
        } else {
            fatalError("Base abstract class Angle is not accepted")
        }
    }
}
