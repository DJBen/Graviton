//
//  Orbit.swift
//  Orbits
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

// http://www.braeunig.us/space/orbmech.htm
// http://www.bogan.ca/orbits/kepler/orbteqtn.html
public struct Orbit {
    public enum ConicSection {
        case circle(r: Float)
        case ellipse(a: Float, e: Float)
        case parabola(pe: Float)
        case hyperbola(a: Float, e: Float)
        
        public var semimajorAxis: Float? {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, _): return a
            case .parabola(_): return nil
            case .hyperbola(let a, _): return a
            }
        }
        
        // https://en.wikipedia.org/wiki/Orbital_eccentricity
        public var eccentricity: Float {
            switch self {
            case .circle(_): return 0
            case .ellipse(_, let e): return e
            case .parabola(_): return 1
            case .hyperbola(_, let e): return e
            }
        }
        
        public var apoapsis: Float? {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 + e)
            case .parabola(_): return nil
            case .hyperbola(let a, let e): return a * (1 + e)
            }
        }
        
        public var periapsis: Float {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 - e)
            case .parabola(let pe): return pe
            case .hyperbola(let a, let e): return a * (1 - e)
            }
        }
        
        public var semilatusRectum: Float {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 - pow(e, 2))
            case .parabola(let pe): return 2 * pe
            case .hyperbola(let a, let e): return a * (1 - pow(e, 2))
            }
        }
        
        public static func from(semimajorAxis a: Float, eccentricity e: Float) -> ConicSection {
            if a == Float.infinity || e == 1 {
                fatalError("cannot initialize a parabola using this method")
            }
            switch e {
            case 0: return ConicSection.circle(r: a)
            case 0..<1: return ConicSection.ellipse(a: a, e: e)
            default: return ConicSection.hyperbola(a: a, e: e)
            }
        }
        
        public static func from(apoapsis ap: Float, periapsis pe: Float) -> ConicSection {
            if ap == Float.infinity {
                fatalError("cannot initialize a parabola using this method")
            }
            return from(semimajorAxis: (ap + pe) / 2, eccentricity: 1 - 2 / ((ap / pe) + 1))
        }
    }
    
    public struct Orientation {
        public var inclination: Float
        public var longitudeOfAscendingNode: Float?
        // https://en.wikipedia.org/wiki/Argument_of_periapsis
        // calculate as if Ω == 0 when orbit is circular
        public var argumentOfPeriapsis: Float
        
        public init(inclination: Float, longitudeOfAscendingNode: Float?, argumentOfPeriapsis: Float) {
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
        let loanMakesSense = abs(fmod(orientation.inclination, Float(M_PI))) > 1e-6 && abs(fmod(orientation.inclination, Float(M_PI)) - Float(M_PI)) > 1e-6
        if loanMakesSense && orientation.longitudeOfAscendingNode == nil {
            fatalError("orbits with inclination should supply longitude of ascending node")
        }
    }
    
    public init(semimajorAxis: Float, eccentricity: Float, inclination: Float, longitudeOfAscendingNode: Float?, argumentOfPeriapsis: Float) {
        self.init(shape: ConicSection.from(semimajorAxis: semimajorAxis, eccentricity: eccentricity), orientation: Orientation(inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis))
    }
    
    public func orbitalPeriod(centralBody: BoundedByGravity) -> Float? {
        guard let a = shape.semimajorAxis else {
            return nil
        }
        return calculatePeriod(semimajorAxis: a, gravParam: centralBody.gravParam)
    }
    
}
