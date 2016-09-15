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
    var orbit: Orbit!
    
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
    
    var gravParam: Float {
        return centralBody.gravParam
    }
    
    var timeElapsed: Float = 0 {
        didSet {
            // time consuming, we only recalculate when mean anomaly is changed
            eccentricAnomaly = calculateEccentricAnomaly(eccentricity: orbit.shape.eccentricity, meanAnomaly: meanAnomaly!)
            // r(t) = Rz(−Ω)Rx(−i)Rz(−ω)o(t)
            // r ̇(t) = Rz(−Ω)Rx(−i)Rz(−ω)o ̇(t)
            var transform = SCNMatrix4Identity
            if let Ω = orbit.orientation.longitudeOfAscendingNode {
                transform = SCNMatrix4MakeRotation(-Ω, 0, 0, 1)
            }
            transform = SCNMatrix4Mult(transform, SCNMatrix4MakeRotation(-orbit.orientation.inclination, 1, 0, 0))
            if let ω = orbit.orientation.argumentOfPeriapsis {
                transform = SCNMatrix4Mult(transform, SCNMatrix4MakeRotation(-ω, 0, 0, 1))
            }
            let p = positionInOrbitalFrame
            let v = velocityInOrbitalFrame
            
            let pIOP_f4 = SCNVector4ToFloat4(SCNQuaternion(p.x, p.y, p.z, 1))
            let vIOP_f4 = SCNVector4ToFloat4(SCNQuaternion(v.x, v.y, v.z, 1))
            let finalTransform = SCNMatrix4ToMat4(transform)
            let p4 = matrix_multiply(finalTransform, pIOP_f4)
            let v4 = matrix_multiply(finalTransform, vIOP_f4)
            position = SCNVector3(x: p4.x, y: p4.y, z: p4.z)
            velocity = SCNVector3(x: v4.x, y: v4.y, z: v4.z)
        }
    }
    
    var orbitalPeriod: Float? {
        guard let a = orbit.shape.semimajorAxis else {
            return nil
        }
        return Float(M_PI) * 2 * sqrt(pow(a, 3) / gravParam)
    }
    
    // http://physics.stackexchange.com/questions/191971/hyper-parabolic-kepler-orbits-and-mean-anomaly
    var meanAnomaly: Float? {
        get {
            // FIXME: crash when parabola
            return calculateMeanAnomaly(fromTime: timeElapsed, gravParam: gravParam, shape: orbit.shape)
        }
        set {
            timeElapsed = wrapAngle(newValue!) / Float(M_PI * 2) * orbitalPeriod!
        }
    }
    
    private(set) var eccentricAnomaly: Float = 0
    
    var trueAnomaly: Float {
        return calculateTrueAnomaly(eccentricity: orbit.shape.eccentricity, eccentricAnomaly: eccentricAnomaly)
    }
    
    var distance: Float {
        // FIXME: crash when parabola
        return orbit.shape.semimajorAxis! * (1 - orbit.shape.eccentricity * cos(eccentricAnomaly))
    }
    
    private var positionInOrbitalFrame: SCNVector3 {
        return SCNVector3(x: sin(trueAnomaly), y: cos(trueAnomaly), z: 0) * distance
    }

    private var velocityInOrbitalFrame: SCNVector3 {
        let coefficient = sqrt(gravParam * orbit.shape.semimajorAxis!) / distance
        return SCNVector3(x: -sin(eccentricAnomaly), y: sqrt(1 - pow(orbit.shape.eccentricity, 2)) * cos(eccentricAnomaly), z: 0) * coefficient
    }
    
    var position: SCNVector3 = SCNVector3Zero
    var velocity: SCNVector3 = SCNVector3Zero
    
    var angularMomentum: SCNVector3 {
        return position.cross(velocity)
    }
    
    var specificMechanicalEnergy: Float {
        return velocity.dot(velocity) / 2 - gravParam / position.length()
    }
    
    var eccentricityVector: SCNVector3 {
        return velocity.cross(angularMomentum) / gravParam - position.normalized()
    }
    
    // https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
    init(centralBody: CelestialBody, orbit: Orbit, timeElapsed: Float = 0) {
        // FIXME: crash when parabola
        self.init(centralBody: centralBody, orbit: orbit, meanAnomaly: calculateMeanAnomaly(fromTime: timeElapsed, gravParam: centralBody.gravParam, shape: orbit.shape)!)
    }
    
    init(centralBody: CelestialBody, orbit: Orbit, meanAnomaly: Float = 0) {
        if orbit.shape.eccentricity >= 1 {
            fatalError("must be circular or elliptical orbit")
        }
        self.centralBody = centralBody
        self.orbit = orbit
        self.meanAnomaly = meanAnomaly
    }
    
    // https://downloads.rene-schwarz.com/download/M002-Cartesian_State_Vectors_to_Keplerian_Orbit_Elements.pdf
    // https://space.stackexchange.com/questions/1904/how-to-programmatically-calculate-orbital-elements-using-position-velocity-vecto?newreg=70344ca3afc847acb4f105c7194ff719
//    init(centralBody: CelestialBody, position: SCNVector3, velocity: SCNVector3) {
//        self.centralBody = centralBody
//        self.position = position
//        self.velocity = velocity
//        if eccentricityVector.length() != 1 {
//            
//        } else {
//            let semimajorAxis = Float.infinity
//        }
//    }
    
}
