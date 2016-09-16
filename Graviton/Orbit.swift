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
        var argumentOfPeriapsis: Float?
    }

    var shape: ConicSection
    var orientation: Orientation

    init(shape: ConicSection, orientation: Orientation) {
        self.shape = shape
        self.orientation = orientation
        if orientation.inclination != 0 && orientation.longitudeOfAscendingNode == nil {
            fatalError("orbits with inclination should supply longitude of ascending node")
        }
        if shape.eccentricity != 0 && orientation.argumentOfPeriapsis == nil {
            fatalError("non-circular orbit should supply argument of periapsis")
        }
    }
    
    init(semimajorAxis: Float, eccentricity: Float, inclination: Float, longitudeOfAscendingNode: Float?, argumentOfPeriapsis: Float) {
        self.init(shape: ConicSection.from(semimajorAxis: semimajorAxis, eccentricity: eccentricity), orientation: Orientation(inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis))
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
            timeFromPeriapsis: orbitalPeriod != nil ? fmodf(timeElapsed, orbitalPeriod!) : timeElapsed
        )
    }
    
    var orbitalPeriod: Float? {
        guard let a = orbit.shape.semimajorAxis else {
            return nil
        }
        return calculatePeriod(semimajorAxis: a, gravParam: centralBody.gravParam)
    }
    
    var orbit: Orbit {
        didSet {
            propagateStateVectors()
        }
    }
    private(set) var timeElapsed: Float
    
    mutating func setTime(_ time: Float) {
        timeElapsed = time
        meanAnomaly = calculateMeanAnomaly(fromTime: timeElapsed, gravParam: centralBody.gravParam, shape: orbit.shape)!
        propagateStateVectors()
    }
    
    // http://physics.stackexchange.com/questions/191971/hyper-parabolic-kepler-orbits-and-mean-anomaly
    private(set) var meanAnomaly: Float
    
    mutating func setMeanAnomaly(_ m: Float) {
        meanAnomaly = wrapAngle(m)
        timeElapsed = meanAnomaly * sqrt(pow(orbit.shape.semimajorAxis!, 3) / centralBody.gravParam)
        propagateStateVectors()
    }
    
    var position: SCNVector3!
    var velocity: SCNVector3!

    var specificMechanicalEnergy: Float {
        return velocity.dot(velocity) / 2 - centralBody.gravParam / position.length()
    }
    
    var distance: Float {
        return position.length()
    }
    
    // https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
    init(centralBody: CelestialBody, orbit: Orbit, timeElapsed: Float = 0) {
        self.centralBody = centralBody
        self.orbit = orbit
        self.timeElapsed = timeElapsed
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
    init(centralBody: CelestialBody, position: SCNVector3, velocity: SCNVector3) {
        self.centralBody = centralBody
        self.position = position
        self.velocity = velocity
        let angularMomentum = position.cross(velocity)
        let eccentricityVector = velocity.cross(angularMomentum) / centralBody.gravParam - position.normalized()
        let n = SCNVector3(0, 0, 1).cross(angularMomentum)
        let trueAnomaly: Float = {
            if position.dot(velocity) >= 0 {
                return acos(eccentricityVector.dot(position) / (eccentricityVector.length() * position.length()))
            } else {
                return Float(2 * M_PI) - acos(eccentricityVector.dot(position) / (eccentricityVector.length() * position.length()))
            }
        }()
        let inclination = acos(angularMomentum.z / angularMomentum.length())
        let eccentricity = eccentricityVector.length()
        let eccentricAnomaly = 2 * atan(tan(trueAnomaly / 2) / sqrt((1 + eccentricity) / (1 - eccentricity)))
        let longitudeOfAscendingNode: Float = {
            if n.y >= 0 {
                return acos(n.x / n.length())
            } else {
                return Float(M_PI * 2) - acos(n.x / n.length())
            }
        }()
        let argumentOfPeriapsis: Float = {
            if eccentricityVector.z >= 0 {
                return acos(n.dot(eccentricityVector) / (n.length() * eccentricityVector.length()))
            } else {
                return Float(M_PI * 2) - acos(n.dot(eccentricityVector) / (n.length() * eccentricityVector.length()))
            }
        }()
        meanAnomaly = eccentricAnomaly - eccentricity * sin(eccentricAnomaly)
        let semimajorAxis = 1 / (2 / position.length() - pow(velocity.length(), 2) / centralBody.gravParam)
        // won't trigger the didSet observer
        orbit = Orbit(semimajorAxis: semimajorAxis, eccentricity: eccentricity, inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis)
        timeElapsed = wrapAngle(meanAnomaly) * sqrt(pow(semimajorAxis, 3) / centralBody.gravParam)
    }
    
    private mutating func propagateStateVectors() {
        let eccentricAnomaly = calculateEccentricAnomaly(eccentricity: orbit.shape.eccentricity, meanAnomaly: meanAnomaly)
        let trueAnomaly = calculateTrueAnomaly(eccentricity: orbit.shape.eccentricity, eccentricAnomaly: eccentricAnomaly)
        let distance = orbit.shape.semimajorAxis! * (1 - orbit.shape.eccentricity * cos(eccentricAnomaly))

        let p = SCNVector3(x: cos(trueAnomaly), y: sin(trueAnomaly), z: 0) * distance
        let coefficient = sqrt(centralBody.gravParam * orbit.shape.semimajorAxis!) / distance
        let v = SCNVector3(x: -sin(eccentricAnomaly), y: sqrt(1 - pow(orbit.shape.eccentricity, 2)) * cos(eccentricAnomaly), z: 0) * coefficient
        let Ω = orbit.orientation.longitudeOfAscendingNode ?? 0
        let i = orbit.orientation.inclination
        let ω = orbit.orientation.argumentOfPeriapsis ?? 0
        position = SCNVector3(
            x: p.x * (cos(ω) * cos(Ω) - sin(ω) * cos(i) * sin(Ω)) - p.y * (sin(ω) * cos(Ω) + cos(ω) * cos(i) * sin(Ω)),
            y: p.x * (cos(ω) * sin(Ω) + sin(ω) * cos(i) * cos(Ω)) + p.y * (cos(ω) * cos(i) * cos(Ω) - sin(ω) * sin(Ω)),
            z: p.x * (sin(ω) * sin(i)) + p.y * (cos(ω) * sin(i))
        )
        velocity = SCNVector3(
            x: v.x * (cos(ω) * cos(Ω) - sin(ω) * cos(i) * sin(Ω)) - v.y * (sin(ω) * cos(Ω) + cos(ω) * cos(i) * sin(Ω)),
            y: v.x * (cos(ω) * sin(Ω) + sin(ω) * cos(i) * cos(Ω)) + v.y * (cos(ω) * cos(i) * cos(Ω) - sin(ω) * sin(Ω)),
            z: v.x * (sin(ω) * sin(i)) + v.y * (cos(ω) * sin(i))
        )
        
    }
    
}
