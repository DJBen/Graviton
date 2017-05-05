//
//  Orbit.swift
//  Orbits
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import MathUtil

// http://www.braeunig.us/space/orbmech.htm
// http://www.bogan.ca/orbits/kepler/orbteqtn.html

public struct Orbit: CustomStringConvertible, Equatable {
    public struct ConicSection: Equatable {
        public enum `Type` {
            case circle
            case ellipse
            case parabola
            case hyperbola
        }

        public var type: Type {
            if eccentricity == 0 {
                return .circle
            } else if eccentricity < 1 {
                return .ellipse
            } else if eccentricity == 1 {
                return .parabola
            } else {
                return .hyperbola
            }
        }

        public let semimajorAxis: Double

        // https://en.wikipedia.org/wiki/Orbital_eccentricity
        public let eccentricity: Double

        public var apoapsis: Double {
            return semimajorAxis * (1 + eccentricity)
        }

        public var periapsis: Double {
            return semimajorAxis * (1 - eccentricity)
        }

        public var semilatusRectum: Double {
            return semimajorAxis * (1 - pow(eccentricity, 2))
        }

        public init(semimajorAxis a: Double, eccentricity e: Double) {
            if a == Double.infinity || e == 1 {
                fatalError("cannot initialize a parabola using this method")
            }
            semimajorAxis = a
            eccentricity = e
        }

        public init(apoapsis ap: Double, periapsis pe: Double) {
            if ap == Double.infinity {
                fatalError("cannot initialize a parabola using this method")
            }
            self.init(semimajorAxis: (ap + pe) / 2, eccentricity: 1 - 2 / ((ap / pe) + 1))
        }

        public static func ==(lhs: ConicSection, rhs: ConicSection) -> Bool {
            return lhs.semimajorAxis ~= rhs.semimajorAxis && lhs.eccentricity ~= rhs.eccentricity
        }
    }

    public struct Orientation: Equatable {
        public var inclination: Double
        public var longitudeOfAscendingNode: Double
        // https://en.wikipedia.org/wiki/Argument_of_periapsis
        // calculate as if Ω == 0 when orbit is circular
        public var argumentOfPeriapsis: Double

        public init(inclination: Double, longitudeOfAscendingNode: Double, argumentOfPeriapsis: Double) {
            self.inclination = inclination
            self.longitudeOfAscendingNode = longitudeOfAscendingNode
            self.argumentOfPeriapsis = argumentOfPeriapsis
        }

        public static func ==(lhs: Orientation, rhs: Orientation) -> Bool {
            return lhs.argumentOfPeriapsis ~= rhs.argumentOfPeriapsis && lhs.inclination ~= rhs.inclination && lhs.longitudeOfAscendingNode ~= rhs.longitudeOfAscendingNode
        }
    }

    public var shape: ConicSection
    public var orientation: Orientation

    // r(t) = Rz(−Ω)Rx(−i)Rz(−ω)o(t)

    // Rz(−Ω)
    public var loANTransform: Quaternion {
        return Quaternion(axisAngle: Vector4(0, 0, 1, orientation.longitudeOfAscendingNode))
    }
    // Rx(−i)
    public var inclinationTransform: Quaternion {
        return Quaternion(axisAngle: Vector4(1, 0, 0, orientation.inclination))
    }
    // Rz(−ω)
    public var argumentOfPeriapsisTransform: Quaternion {
        return Quaternion(axisAngle: Vector4(0, 0, 1, orientation.argumentOfPeriapsis))
    }
    public var orientationTransform: Quaternion {
        return loANTransform * inclinationTransform * argumentOfPeriapsisTransform
    }

    public var description: String {
        return "{ a: \(shape.semimajorAxis), e: \(shape.eccentricity), i: \(orientation.inclination), om: \(orientation.longitudeOfAscendingNode), w: \(orientation.argumentOfPeriapsis) }"
    }

    public init(shape: ConicSection, orientation: Orientation) {
        self.shape = shape
        self.orientation = orientation
    }

    public init(semimajorAxis: Double, eccentricity: Double, inclination: Double, longitudeOfAscendingNode: Double, argumentOfPeriapsis: Double) {
        self.init(shape: ConicSection(semimajorAxis: semimajorAxis, eccentricity: eccentricity), orientation: Orientation(inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis))
    }

    public func orbitalPeriod(gm: Double) -> Double? {
        let a = shape.semimajorAxis
        return Double(Double.pi) * 2 * sqrt(pow(a, 3) / gm)
    }

    // MARK: - Equatable
    public static func ==(lhs: Orbit, rhs: Orbit) -> Bool {
        return lhs.shape == rhs.shape && lhs.orientation == rhs.orientation
    }
}

/// Calculate mean anomaly from time
///
/// - Parameters:
///   - time: time since JD2000 in seconds
///   - gravParam: gravity parameter
///   - shape: shape of orbit
/// - Returns: mean anomaly of current orbit motion

func calculateMeanAnomaly(Δt time: Double, gravParam: Double, shape: Orbit.ConicSection) -> Double? {
    let a = shape.semimajorAxis
    return wrapAngle(time * sqrt(gravParam / pow(a, 3)))
}

func calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Double) -> Double {
    return 2 * atan2(sqrt(1 + eccentricity) * sin(eccentricAnomaly / 2), sqrt(1 - eccentricity) * cos(eccentricAnomaly / 2))
}
