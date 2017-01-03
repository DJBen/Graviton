//
//  OrbitalMotion.swift
//  Orbits
//
//  Created by Sihao Lu on 12/29/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit
import SQLite

public class OrbitalMotion {
    
    public struct Info {
        public let altitude: Float
        public let speed: Float
        public let periapsisAltitude: Float
        public let apoapsisAltitude: Float?
    }
    
    public let centralBody: CelestialBody
    
    public var info: Info {
        return Info(
            altitude: distance - centralBody.radius,
            speed: velocity.length(),
            periapsisAltitude: orbit.shape.periapsis - centralBody.radius,
            apoapsisAltitude: orbit.shape.apoapsis != nil ? (orbit.shape.apoapsis! - centralBody.radius) : nil
        )
    }
    
    public var orbitalPeriod: Float? {
        return orbit.orbitalPeriod(centralBody: centralBody)
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
    public enum Phase {
        case meanAnomaly(Float)
        case timeSincePeriapsis(Float)
        case julianDate(Float)
    }
    
    public var phase: Phase {
        didSet {
            switch phase {
            case .meanAnomaly(let ma):
                meanAnomaly = ma
            case .timeSincePeriapsis(let tp):
                meanAnomaly = calculateMeanAnomaly(Δt: tp, gravParam: centralBody.gravParam, shape: orbit.shape)!
            case .julianDate(let jd):
                meanAnomaly = calculateMeanAnomaly(Δt: (jd - safeTimeOfPeriapsisPassage()) * 86400, gravParam: centralBody.gravParam, shape: orbit.shape)!
            }
            propagateStateVectors()
        }
    }
    
    public func setMeanAnomaly(_ ma: Float) {
        guard case .meanAnomaly(_) = phase else {
            fatalError("phase is not in mean anomaly mode")
        }
        phase = .meanAnomaly(ma)
    }
    
    public var julianDate: Float? {
        get {
            guard case let .julianDate(jd) = phase else {
                return nil
            }
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
    
    public var timeSincePeriapsis: Float? {
        get {
            guard case let .timeSincePeriapsis(tp) = phase else {
                return nil
            }
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
    
    public var timeOfPeriapsisPassage: Float?
    
    private func safeTimeOfPeriapsisPassage() -> Float {
        if let r = timeOfPeriapsisPassage {
            return r
        } else {
            fatalError("timeOfPeriapsisPassage must be set when using Phase.julianDate")
        }
    }
    
    // http://physics.stackexchange.com/questions/191971/hyper-parabolic-kepler-orbits-and-mean-anomaly
    public private(set) var meanAnomaly: Float!
    
    public private(set) var eccentricAnomaly: Float!
    public private(set) var trueAnomaly: Float!
    
    public var position: SCNVector3!
    public var velocity: SCNVector3!
    
    public var specificMechanicalEnergy: Float {
        return velocity.dot(velocity) / 2 - centralBody.gravParam / position.length()
    }
    
    public var distance: Float {
        return position.length()
    }
    
    // https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
    
    
    /// Initialize keplarian orbit from orbital elements
    ///
    /// - Parameters:
    ///   - centralBody: The primary that is orbiting
    ///   - orbit: Orbital elements
    ///   - phase: Phase descriptor
    init(centralBody: CelestialBody, orbit: Orbit, phase: Phase) {
        self.centralBody = centralBody
        self.orbit = orbit
        self.phase = phase
    }
    
    // Convenient constructors
    public convenience init(centralBody: CelestialBody, orbit: Orbit, meanAnomaly: Float) {
        self.init(centralBody: centralBody, orbit: orbit, phase: .meanAnomaly(meanAnomaly))
    }
    
    public convenience init(centralBody: CelestialBody, orbit: Orbit, timeSincePeriapsis: Float = 0) {
        self.init(centralBody: centralBody, orbit: orbit, phase: .timeSincePeriapsis(timeSincePeriapsis))
    }
    
    // https://downloads.rene-schwarz.com/download/M002-Cartesian_State_Vectors_to_Keplerian_Orbit_Elements.pdf
    // https://space.stackexchange.com/questions/1904/how-to-programmatically-calculate-orbital-elements-using-position-velocity-vecto?newreg=70344ca3afc847acb4f105c7194ff719
    
    /// Initialize keplarian orbit from state vectors.
    ///
    /// - parameter centralBody: The primary that is orbiting
    /// - parameter position:    Position vector
    /// - parameter velocity:    Velocity vector
    ///
    /// - returns: An orbit motion object
    public init(centralBody: CelestialBody, position: SCNVector3, velocity: SCNVector3) {
        self.centralBody = centralBody
        self.position = position
        self.velocity = velocity
        let momentum = position.cross(velocity)
        let eccentricityVector = velocity.cross(momentum) / centralBody.gravParam - position.normalized()
        let n = SCNVector3Make(0, 0, 1).cross(momentum)
        trueAnomaly = {
            if position.dot(velocity) >= 0 {
                return acos(eccentricityVector.dot(position) / (eccentricityVector.length() * position.length()))
            } else {
                return Float(2 * M_PI) - acos(eccentricityVector.dot(position) / (eccentricityVector.length() * position.length()))
            }
        }()
        trueAnomaly = trueAnomaly.isNaN ? 0 : trueAnomaly
        let inclination = acos(momentum.z / momentum.length())
        let eccentricity = eccentricityVector.length()
        eccentricAnomaly = 2 * atan(tan(trueAnomaly / 2) / sqrt((1 + eccentricity) / (1 - eccentricity)))
        var longitudeOfAscendingNode: Float? = {
            if n.y >= 0 {
                return acos(n.x / n.length())
            } else {
                return Float(M_PI * 2) - acos(n.x / n.length())
            }
        }()
        if longitudeOfAscendingNode!.isNaN {
            longitudeOfAscendingNode = nil
        }
        var argumentOfPeriapsis: Float = {
            if eccentricityVector.z >= 0 {
                return acos(n.dot(eccentricityVector) / (n.length() * eccentricityVector.length()))
            } else {
                return Float(M_PI * 2) - acos(n.dot(eccentricityVector) / (n.length() * eccentricityVector.length()))
            }
        }()
        if argumentOfPeriapsis.isNaN {
            argumentOfPeriapsis = atan2(eccentricityVector.y, eccentricityVector.x)
        }
        meanAnomaly = eccentricAnomaly - eccentricity * sin(eccentricAnomaly)
        let semimajorAxis = 1 / (2 / position.length() - pow(velocity.length(), 2) / centralBody.gravParam)
        // won't trigger the didSet observer
        orbit = Orbit(semimajorAxis: semimajorAxis, eccentricity: eccentricity, inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis)
        phase = .meanAnomaly(0)
    }
    
    
    /// Calculate state vectors based on true anomaly.
    /// If eccentric anomaly is not supplied, it will calculated from true anomaly
    /// - parameter trueAnomaly: True anomaly
    ///
    /// - returns: state vector tuple (position, velocity)
    
    public func stateVectors(fromTrueAnomaly trueAnomaly: Float, eccentricAnomaly: Float? = nil) -> (SCNVector3, SCNVector3) {
        let sinE: Float
        let cosE: Float
        if let ecc = eccentricAnomaly {
            sinE = sin(ecc)
            cosE = cos(ecc)
        } else {
            // https://en.wikipedia.org/wiki/Eccentric_anomaly
            let e = orbit.shape.eccentricity
            cosE = (e + cos(trueAnomaly)) / (1 + e * cos(trueAnomaly))
            sinE = sqrt(1 - pow(e, 2)) * sin(trueAnomaly) / (1 + e * cos(trueAnomaly))
        }
        
        let distance = orbit.shape.semimajorAxis! * (1 - orbit.shape.eccentricity * cosE)
        
        let p = SCNVector3Make(cos(trueAnomaly), sin(trueAnomaly), 0) * distance
        let coefficient = sqrt(centralBody.gravParam * orbit.shape.semimajorAxis!) / distance
        let v = SCNVector3Make(-sinE, sqrt(1 - pow(orbit.shape.eccentricity, 2)) * cosE, 0) * coefficient
        let Ω = orbit.orientation.longitudeOfAscendingNode ?? 0
        let i = orbit.orientation.inclination
        let ω = orbit.orientation.argumentOfPeriapsis
        let position = SCNVector3Make(
            p.x * (cos(ω) * cos(Ω) - sin(ω) * cos(i) * sin(Ω)) - p.y * (sin(ω) * cos(Ω) + cos(ω) * cos(i) * sin(Ω)),
            p.x * (cos(ω) * sin(Ω) + sin(ω) * cos(i) * cos(Ω)) + p.y * (cos(ω) * cos(i) * cos(Ω) - sin(ω) * sin(Ω)),
            p.x * (sin(ω) * sin(i)) + p.y * (cos(ω) * sin(i))
        )
        let velocity = SCNVector3Make(
            v.x * (cos(ω) * cos(Ω) - sin(ω) * cos(i) * sin(Ω)) - v.y * (sin(ω) * cos(Ω) + cos(ω) * cos(i) * sin(Ω)),
            v.x * (cos(ω) * sin(Ω) + sin(ω) * cos(i) * cos(Ω)) + v.y * (cos(ω) * cos(i) * cos(Ω) - sin(ω) * sin(Ω)),
            v.x * (sin(ω) * sin(i)) + v.y * (cos(ω) * sin(i))
        )
        return (position, velocity)
    }
    
    public func stateVectors(fromMeanAnomaly meanAnomaly: Float) -> (SCNVector3, SCNVector3) {
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
}
