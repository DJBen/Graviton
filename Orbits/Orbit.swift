//
//  Orbit.swift
//  Orbits
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SpaceTime

// http://www.braeunig.us/space/orbmech.htm
// http://www.bogan.ca/orbits/kepler/orbteqtn.html
public struct Orbit {
    public enum ConicSection {
        case circle(r: Double)
        case ellipse(a: Double, e: Double)
        case parabola(pe: Double)
        case hyperbola(a: Double, e: Double)
        
        public var semimajorAxis: Double? {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, _): return a
            case .parabola(_): return nil
            case .hyperbola(let a, _): return a
            }
        }
        
        // https://en.wikipedia.org/wiki/Orbital_eccentricity
        public var eccentricity: Double {
            switch self {
            case .circle(_): return 0
            case .ellipse(_, let e): return e
            case .parabola(_): return 1
            case .hyperbola(_, let e): return e
            }
        }
        
        public var apoapsis: Double? {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 + e)
            case .parabola(_): return nil
            case .hyperbola(let a, let e): return a * (1 + e)
            }
        }
        
        public var periapsis: Double {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 - e)
            case .parabola(let pe): return pe
            case .hyperbola(let a, let e): return a * (1 - e)
            }
        }
        
        public var semilatusRectum: Double {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 - pow(e, 2))
            case .parabola(let pe): return 2 * pe
            case .hyperbola(let a, let e): return a * (1 - pow(e, 2))
            }
        }
        
        public static func from(semimajorAxis a: Double, eccentricity e: Double) -> ConicSection {
            if a == Double.infinity || e == 1 {
                fatalError("cannot initialize a parabola using this method")
            }
            switch e {
            case 0: return ConicSection.circle(r: a)
            case 0..<1: return ConicSection.ellipse(a: a, e: e)
            default: return ConicSection.hyperbola(a: a, e: e)
            }
        }
        
        public static func from(apoapsis ap: Double, periapsis pe: Double) -> ConicSection {
            if ap == Double.infinity {
                fatalError("cannot initialize a parabola using this method")
            }
            return from(semimajorAxis: (ap + pe) / 2, eccentricity: 1 - 2 / ((ap / pe) + 1))
        }
    }
    
    public struct Orientation {
        public var inclination: Double
        public var longitudeOfAscendingNode: Double?
        // https://en.wikipedia.org/wiki/Argument_of_periapsis
        // calculate as if Ω == 0 when orbit is circular
        public var argumentOfPeriapsis: Double
        
        public init(inclination: Double, longitudeOfAscendingNode: Double?, argumentOfPeriapsis: Double) {
            self.inclination = inclination
            self.longitudeOfAscendingNode = longitudeOfAscendingNode
            self.argumentOfPeriapsis = argumentOfPeriapsis
        }
    }

    public var shape: ConicSection
    public var orientation: Orientation

    public init(shape: ConicSection, orientation: Orientation) {
        self.shape = shape
        self.orientation = orientation
        let loanMakesSense = abs(fmod(orientation.inclination, Double(M_PI))) > 1e-6 && abs(fmod(orientation.inclination, Double(M_PI)) - Double(M_PI)) > 1e-6
        if loanMakesSense && orientation.longitudeOfAscendingNode == nil {
            fatalError("orbits with inclination should supply longitude of ascending node")
        }
    }
    
    public init(semimajorAxis: Double, eccentricity: Double, inclination: Double, longitudeOfAscendingNode: Double?, argumentOfPeriapsis: Double) {
        self.init(shape: ConicSection.from(semimajorAxis: semimajorAxis, eccentricity: eccentricity), orientation: Orientation(inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis))
    }
    
    public func orbitalPeriod(centralBody: BoundedByGravity) -> Double? {
        guard let a = shape.semimajorAxis else { return nil }
        return Double(M_PI) * 2 * sqrt(pow(a, 3) / centralBody.gravParam)
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
    switch shape {
    case .circle(let a), .ellipse(let a, _), .hyperbola(let a, _):
        return wrapAngle(time * sqrt(gravParam / pow(a, 3)))
    case .parabola(_):
        return nil
    }
}

func calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Double) -> Double {
    return 2 * atan2(sqrt(1 + eccentricity) * sin(eccentricAnomaly / 2), sqrt(1 - eccentricity) * cos(eccentricAnomaly / 2))
}

