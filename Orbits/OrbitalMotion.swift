//
//  OrbitalMotion.swift
//  Orbits
//
//  Created by Sihao Lu on 12/29/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import MathUtil

public class OrbitalMotion: NSCopying {
    
    public let gm: Double
    
    public var orbitalPeriod: Double? {
        return orbit.orbitalPeriod(gm: gm)
    }
    
    public var orbit: Orbit {
        didSet {
            propagateStateVectors()
        }
    }
    
    /// Phase
    ///
    /// - meanAnomaly: Mean anomaly in radians
    /// - timeSincePeriapsis: Time of periapsis passage in seconds
    /// - julianDate: Current Julian day time. This option requires `referenceJulianDayTime` to be set
    public enum Phase: Equatable {
        case meanAnomaly(Double)
        case timeSincePeriapsis(Double)
        case julianDate(Double)
        
        public static func ==(lhs: Phase, rhs: Phase) -> Bool {
            switch lhs {
            case .meanAnomaly(let ma):
                guard case .meanAnomaly(let ma2) = rhs else { return false }
                return ma ~= ma2
            case .timeSincePeriapsis(let tsp):
                guard case .timeSincePeriapsis(let tsp2) = rhs else { return false }
                return tsp ~= tsp2
            case .julianDate(let jd):
                guard case .julianDate(let jd2) = rhs else { return false }
                return jd ~= jd2
            }
        }
    }
    
    public var phase: Phase {
        didSet {
            switch phase {
            case .meanAnomaly(let ma):
                meanAnomaly = ma
            case .timeSincePeriapsis(let tp):
                meanAnomaly = calculateMeanAnomaly(Δt: tp, gravParam: gm, shape: orbit.shape)!
            case .julianDate(let jd):
                meanAnomaly = calculateMeanAnomaly(Δt: (jd - unwrappedTimeOfPeriapsisPassage) * 86400, gravParam: gm, shape: orbit.shape)!
            }
            propagateStateVectors()
        }
    }
    
    public func setMeanAnomaly(_ ma: Double) {
        guard case .meanAnomaly(_) = phase else {
            fatalError("phase is not in mean anomaly mode")
        }
        phase = .meanAnomaly(ma)
    }
    
    /// the julian date of orbital motion (moment)
    public var julianDate: Double? {
        get {
            guard case let .julianDate(jd) = phase else { return nil }
            return jd
        }
        set {
            guard case .julianDate(_) = phase else {
                fatalError("phase is not in julian date mode")
            }
            guard let newJd = newValue else {
                fatalError("Julian date cannot be nil")
            }
            self.phase = .julianDate(newJd)
        }
    }
    
    public var timeSincePeriapsis: Double? {
        get {
            guard case let .timeSincePeriapsis(tp) = phase else { return nil }
            return tp
        }
        set {
            guard case .timeSincePeriapsis(_) = phase else {
                fatalError("phase is not in Tp mode")
            }
            guard let newTp = newValue else {
                fatalError("Tp cannot be nil")
            }
            self.phase = .timeSincePeriapsis(newTp)
        }
    }
    
    public var timeOfPeriapsisPassage: Double?
    
    private var unwrappedTimeOfPeriapsisPassage: Double {
        if let t = timeOfPeriapsisPassage {
            return t
        } else {
            fatalError("timeOfPeriapsisPassage must be set when using Phase.julianDate")
        }
    }
    
    // http://physics.stackexchange.com/questions/191971/hyper-parabolic-kepler-orbits-and-mean-anomaly
    public private(set) var meanAnomaly: Double!
    
    public private(set) var eccentricAnomaly: Double!
    /// True anomaly; range = [0, 2π)
    public private(set) var trueAnomaly: Double!
    
    public var position: Vector3!
    public var velocity: Vector3!
    
    public var specificMechanicalEnergy: Double {
        return velocity.dot(velocity) / 2 - gm / position.length
    }
    
    public var distance: Double {
        return position.length
    }
    
    // https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
    
    
    /// Initialize keplarian orbit from orbital elements
    ///
    /// - Parameters:
    ///   - gm: The system gm
    ///   - orbit: Orbital elements
    ///   - phase: Phase descriptor
    init(orbit: Orbit, gm: Double, phase: Phase) {
        self.gm = gm
        self.orbit = orbit
        self.phase = phase
    }
    
    public convenience init(orbit: Orbit, gm: Double, meanAnomaly: Double) {
        self.init(orbit: orbit, gm: gm, phase: .meanAnomaly(meanAnomaly))
    }
    
    public convenience init(orbit: Orbit, gm: Double, timeSincePeriapsis: Double = 0) {
        self.init(orbit: orbit, gm: gm, phase: .timeSincePeriapsis(timeSincePeriapsis))
    }
    
    // https://downloads.rene-schwarz.com/download/M002-Cartesian_State_Vectors_to_Keplerian_Orbit_Elements.pdf
    // https://space.stackexchange.com/questions/1904/how-to-programmatically-calculate-orbital-elements-using-position-velocity-vecto?newreg=70344ca3afc847acb4f105c7194ff719
    
    /// Initialize keplarian orbit from state vectors.
    ///
    /// - parameter centerBody: The primary that is orbiting
    /// - parameter position:    Position vector
    /// - parameter velocity:    Velocity vector
    ///
    /// - returns: An orbit motion object
    public init(gm: Double, position: Vector3, velocity: Vector3) {
        self.gm = gm
        self.position = position
        self.velocity = velocity
        let momentum = position.cross(velocity)
        let eccentricityVector = velocity.cross(momentum) / gm - position.normalized()
        let n = Vector3(0, 0, 1).cross(momentum)
        trueAnomaly = {
            if position.dot(velocity) >= 0 {
                return acos(eccentricityVector.dot(position) / (eccentricityVector.length * position.length))
            } else {
                return Double(2 * Double.pi) - acos(eccentricityVector.dot(position) / (eccentricityVector.length * position.length))
            }
        }()
        trueAnomaly = trueAnomaly.isNaN ? 0 : trueAnomaly
        let inclination = acos(Double(momentum.z) / momentum.length)
        let eccentricity = eccentricityVector.length
        eccentricAnomaly = 2 * atan(tan(trueAnomaly / 2) / sqrt((1 + eccentricity) / (1 - eccentricity)))
        var longitudeOfAscendingNode: Double = {
            if n.y >= 0 {
                return acos(Double(n.x) / n.length)
            } else {
                return Double(Double.pi * 2) - acos(Double(n.x) / n.length)
            }
        }()
        if longitudeOfAscendingNode.isNaN {
            longitudeOfAscendingNode = 0
        }
        var argumentOfPeriapsis: Double = {
            if eccentricityVector.z >= 0 {
                return acos(n.dot(eccentricityVector) / (n.length * eccentricityVector.length))
            } else {
                return Double(Double.pi * 2) - acos(n.dot(eccentricityVector) / (n.length * eccentricityVector.length))
            }
        }()
        if argumentOfPeriapsis.isNaN {
            argumentOfPeriapsis = atan2(Double(eccentricityVector.y), Double(eccentricityVector.x))
        }
        meanAnomaly = eccentricAnomaly - eccentricity * sin(eccentricAnomaly)
        let semimajorAxis = 1 / (2 / position.length - pow(velocity.length, 2) / gm)
        // won't trigger the didSet observer
        orbit = Orbit(semimajorAxis: semimajorAxis, eccentricity: eccentricity, inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis)
        phase = .meanAnomaly(0)
    }

    /// Calculate state vectors without rotation.
    /// If eccentric anomaly is not supplied, it will be calculated from true anomaly
    /// - parameter trueAnomaly: True anomaly
    ///
    /// - returns: state vector tuple (position, velocity) without transforming by inclination, LoAN and AoP

    public func unrotatedStateVectors(fromTrueAnomaly trueAnomaly: Double, eccentricAnomaly: Double? = nil) -> (Vector3, Vector3) {
        let sinE: Double
        let cosE: Double
        if let ecc = eccentricAnomaly {
            sinE = sin(ecc)
            cosE = cos(ecc)
        } else {
            // https://en.wikipedia.org/wiki/Eccentric_anomaly
            let e = orbit.shape.eccentricity
            cosE = (e + cos(trueAnomaly)) / (1 + e * cos(trueAnomaly))
            sinE = sqrt(1 - pow(e, 2)) * sin(trueAnomaly) / (1 + e * cos(trueAnomaly))
        }
        let distance = orbit.shape.semimajorAxis * (1 - orbit.shape.eccentricity * cosE)
        let p = Vector3(cos(trueAnomaly), sin(trueAnomaly), 0) * distance
        let coefficient = sqrt(gm * orbit.shape.semimajorAxis) / distance
        let v = Vector3(-sinE, sqrt(1 - pow(orbit.shape.eccentricity, 2)) * cosE, 0) * coefficient
        return (p, v)
    }
    
    /// Calculate state vectors.
    /// If eccentric anomaly is not supplied, it will be calculated from true anomaly
    /// - parameter trueAnomaly: True anomaly
    ///
    /// - returns: state vector tuple (position, velocity)
    
    public func stateVectors(fromTrueAnomaly trueAnomaly: Double, eccentricAnomaly: Double? = nil) -> (Vector3, Vector3) {
        let (p, v) = unrotatedStateVectors(fromTrueAnomaly: trueAnomaly, eccentricAnomaly: eccentricAnomaly)
        let position = p * orbit.orientationTransform
        let velocity = v * orbit.orientationTransform
        return (position, velocity)
    }
    
    public func stateVectors(fromMeanAnomaly meanAnomaly: Double) -> (Vector3, Vector3) {
        let eccentricAnomaly = solveInverseKepler(eccentricity: orbit.shape.eccentricity, meanAnomaly: meanAnomaly)
        let trueAnomaly = calculateTrueAnomaly(eccentricity: orbit.shape.eccentricity, eccentricAnomaly: eccentricAnomaly)
        return stateVectors(fromTrueAnomaly: trueAnomaly, eccentricAnomaly: eccentricAnomaly)
    }
    
    private func propagateStateVectors() {
        eccentricAnomaly = solveInverseKepler(eccentricity: orbit.shape.eccentricity, meanAnomaly: meanAnomaly)
        trueAnomaly = calculateTrueAnomaly(eccentricity: orbit.shape.eccentricity, eccentricAnomaly: eccentricAnomaly)
        let (p, v) = stateVectors(fromTrueAnomaly: trueAnomaly, eccentricAnomaly: eccentricAnomaly)
        position = p
        velocity = v
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        return OrbitalMotion(orbit: orbit, gm: gm, phase: phase)
    }
}
