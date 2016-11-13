//
//  Orbit.swift
//  Graviton
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

// http://www.braeunig.us/space/orbmech.htm
// http://www.bogan.ca/orbits/kepler/orbteqtn.html
struct Orbit {
    enum ConicSection {
        case circle(r: Float)
        case ellipse(a: Float, e: Float)
        case parabola(pe: Float)
        case hyperbola(a: Float, e: Float)
        
        var semimajorAxis: Float? {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, _): return a
            case .parabola(_): return nil
            case .hyperbola(let a, _): return a
            }
        }
        
        // https://en.wikipedia.org/wiki/Orbital_eccentricity
        var eccentricity: Float {
            switch self {
            case .circle(_): return 0
            case .ellipse(_, let e): return e
            case .parabola(_): return 1
            case .hyperbola(_, let e): return e
            }
        }
        
        var apoapsis: Float? {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 + e)
            case .parabola(_): return nil
            case .hyperbola(let a, let e): return a * (1 + e)
            }
        }
        
        var periapsis: Float {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 - e)
            case .parabola(let pe): return pe
            case .hyperbola(let a, let e): return a * (1 - e)
            }
        }
        
        var semilatusRectum: Float {
            switch self {
            case .circle(let r): return r
            case .ellipse(let a, let e): return a * (1 - pow(e, 2))
            case .parabola(let pe): return 2 * pe
            case .hyperbola(let a, let e): return a * (1 - pow(e, 2))
            }
        }
        
        static func from(semimajorAxis a: Float, eccentricity e: Float) -> ConicSection {
            if a == Float.infinity || e == 1 {
                fatalError("cannot initialize a parabola using this method")
            }
            switch e {
            case 0: return ConicSection.circle(r: a)
            case 0..<1: return ConicSection.ellipse(a: a, e: e)
            default: return ConicSection.hyperbola(a: a, e: e)
            }
        }
        
        static func from(apoapsis ap: Float, periapsis pe: Float) -> ConicSection {
            if ap == Float.infinity {
                fatalError("cannot initialize a parabola using this method")
            }
            return from(semimajorAxis: (ap + pe) / 2, eccentricity: 1 - 2 / ((ap / pe) + 1))
        }
    }
    
    struct Orientation {
        var inclination: Float
        var longitudeOfAscendingNode: Float?
        // https://en.wikipedia.org/wiki/Argument_of_periapsis
        // calculate as if Ω == 0 if orbit is circular
        var argumentOfPeriapsis: Float
    }

    var shape: ConicSection
    var orientation: Orientation

    init(shape: ConicSection, orientation: Orientation) {
        self.shape = shape
        self.orientation = orientation
        let loanMakesSense = abs(fmodf(orientation.inclination, Float(M_PI))) > 1e-6 && abs(fmodf(orientation.inclination, Float(M_PI)) - Float(M_PI)) > 1e-6
        if loanMakesSense && orientation.longitudeOfAscendingNode == nil {
            fatalError("orbits with inclination should supply longitude of ascending node")
        }
    }
    
    init(semimajorAxis: Float, eccentricity: Float, inclination: Float, longitudeOfAscendingNode: Float?, argumentOfPeriapsis: Float) {
        self.init(shape: ConicSection.from(semimajorAxis: semimajorAxis, eccentricity: eccentricity), orientation: Orientation(inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis))
    }
    
    func orbitalPeriod(centralBody: BoundedByGravity) -> Float? {
        guard let a = shape.semimajorAxis else {
            return nil
        }
        return calculatePeriod(semimajorAxis: a, gravParam: centralBody.gravParam)
    }
    
}

struct OrbitalMotion {
    let centralBody: CelestialBody
    
    struct Info {
        let altitude: Float
        let speed: Float
        let periapsisAltitude: Float
        let apoapsisAltitude: Float?
        let timeFromPeriapsis: Float
    }
    
    var info: Info {
        return Info(
            altitude: distance - centralBody.radius,
            speed: velocity.length(),
            periapsisAltitude: orbit.shape.periapsis - centralBody.radius,
            apoapsisAltitude: orbit.shape.apoapsis != nil ? (orbit.shape.apoapsis! - centralBody.radius) : nil,
            // FIXME: will crash for parabola and not right for hyperbola
            timeFromPeriapsis: orbitalPeriod != nil ? fmodf(time, orbitalPeriod!) : time
        )
    }
    
    var orbitalPeriod: Float? {
        return orbit.orbitalPeriod(centralBody: centralBody)
    }
    
    var orbit: Orbit {
        didSet {
            propagateStateVectors()
        }
    }
    
    private(set) var time: Float
    
    mutating func setTime(_ time: Float) {
        self.time = time
        meanAnomaly = calculateMeanAnomaly(fromTime: time, gravParam: centralBody.gravParam, shape: orbit.shape)! + meanAnomalyAtEpoch
        propagateStateVectors()
    }
    
    // http://physics.stackexchange.com/questions/191971/hyper-parabolic-kepler-orbits-and-mean-anomaly
    private(set) var meanAnomaly: Float
    
    let meanAnomalyAtEpoch: Float
    
    mutating func setMeanAnomaly(_ m: Float) {
        meanAnomaly = wrapAngle(m)
        time = meanAnomaly * sqrt(pow(orbit.shape.semimajorAxis!, 3) / centralBody.gravParam)
        propagateStateVectors()
    }
    
    var eccentricAnomaly: Float!
    var trueAnomaly: Float!
    
    var position: SCNVector3!
    var velocity: SCNVector3!

    var specificMechanicalEnergy: Float {
        return velocity.dot(velocity) / 2 - centralBody.gravParam / position.length()
    }
    
    var distance: Float {
        return position.length()
    }
    
    // https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
    
    /// Initialize keplarian orbit from orbital elements
    ///
    /// - parameter centralBody:        The primary that is orbiting
    /// - parameter orbit:              Orbital elements
    /// - parameter meanAnomalyAtEpoch: Mean anomaly at epoch
    /// - parameter timeElapsed:        Time since epoch
    ///
    /// - returns: An orbit motion object
    init(centralBody: CelestialBody, orbit: Orbit, meanAnomalyAtEpoch: Float = 0, timeElapsed: Float) {
        self.centralBody = centralBody
        self.orbit = orbit
        self.time = timeElapsed
        self.meanAnomalyAtEpoch = meanAnomalyAtEpoch
        // FIXME: crash when parabola
        meanAnomaly = calculateMeanAnomaly(fromTime: timeElapsed, gravParam: centralBody.gravParam, shape: orbit.shape)!
        propagateStateVectors()
    }
    
    init(centralBody: CelestialBody, orbit: Orbit, meanAnomaly: Float = 0) {
        // FIXME: crash when parabola
        self.init(centralBody: centralBody, orbit: orbit, timeElapsed: wrapAngle(meanAnomaly) * sqrt(pow(orbit.shape.semimajorAxis!, 3) / centralBody.gravParam))
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
    init(centralBody: CelestialBody, position: SCNVector3, velocity: SCNVector3) {
        self.centralBody = centralBody
        self.position = position
        self.velocity = velocity
        let momentum = position.cross(velocity)
        let eccentricityVector = velocity.cross(momentum) / centralBody.gravParam - position.normalized()
        let n = SCNVector3(0, 0, 1).cross(momentum)
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
        time = wrapAngle(meanAnomaly) * sqrt(pow(semimajorAxis, 3) / centralBody.gravParam)
        meanAnomalyAtEpoch = 0
    }
    
    
    /// Calculate state vectors based on true anomaly.
    /// If eccentric anomaly is not supplied, it will calculated from true anomaly
    /// - parameter trueAnomaly: True anomaly
    ///
    /// - returns: state vector tuple (position, velocity)
    
    func stateVectors(fromTrueAnomaly trueAnomaly: Float, eccentricAnomaly: Float? = nil) -> (SCNVector3, SCNVector3) {
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
        
        let p = SCNVector3(x: cos(trueAnomaly), y: sin(trueAnomaly), z: 0) * distance
        let coefficient = sqrt(centralBody.gravParam * orbit.shape.semimajorAxis!) / distance
        let v = SCNVector3(x: -sinE, y: sqrt(1 - pow(orbit.shape.eccentricity, 2)) * cosE, z: 0) * coefficient
        let Ω = orbit.orientation.longitudeOfAscendingNode ?? 0
        let i = orbit.orientation.inclination
        let ω = orbit.orientation.argumentOfPeriapsis
        let position = SCNVector3(
            x: p.x * (cos(ω) * cos(Ω) - sin(ω) * cos(i) * sin(Ω)) - p.y * (sin(ω) * cos(Ω) + cos(ω) * cos(i) * sin(Ω)),
            y: p.x * (cos(ω) * sin(Ω) + sin(ω) * cos(i) * cos(Ω)) + p.y * (cos(ω) * cos(i) * cos(Ω) - sin(ω) * sin(Ω)),
            z: p.x * (sin(ω) * sin(i)) + p.y * (cos(ω) * sin(i))
        )
        let velocity = SCNVector3(
            x: v.x * (cos(ω) * cos(Ω) - sin(ω) * cos(i) * sin(Ω)) - v.y * (sin(ω) * cos(Ω) + cos(ω) * cos(i) * sin(Ω)),
            y: v.x * (cos(ω) * sin(Ω) + sin(ω) * cos(i) * cos(Ω)) + v.y * (cos(ω) * cos(i) * cos(Ω) - sin(ω) * sin(Ω)),
            z: v.x * (sin(ω) * sin(i)) + v.y * (cos(ω) * sin(i))
        )
        return (position, velocity)
    }
    
    func stateVectors(fromMeanAnomaly meanAnomaly: Float) -> (SCNVector3, SCNVector3) {
        let eccentricAnomaly = calculateEccentricAnomaly(eccentricity: orbit.shape.eccentricity, meanAnomaly: meanAnomaly)
        let trueAnomaly = calculateTrueAnomaly(eccentricity: orbit.shape.eccentricity, eccentricAnomaly: eccentricAnomaly)
        return stateVectors(fromTrueAnomaly: trueAnomaly, eccentricAnomaly: eccentricAnomaly)
    }
    
    private mutating func propagateStateVectors() {
        eccentricAnomaly = calculateEccentricAnomaly(eccentricity: orbit.shape.eccentricity, meanAnomaly: meanAnomaly)
        trueAnomaly = calculateTrueAnomaly(eccentricity: orbit.shape.eccentricity, eccentricAnomaly: eccentricAnomaly)
        let (p, v) = stateVectors(fromTrueAnomaly: trueAnomaly, eccentricAnomaly: eccentricAnomaly)
        position = p
        velocity = v
    }
    
}
