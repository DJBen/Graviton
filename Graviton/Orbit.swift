//
//  Orbit.swift
//  Graviton
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

// http://www.braeunig.us/space/orbmech.htm
struct Orbit {
    struct Shape {
        var semimajorAxis: Float
        var eccentricity: Float
        // https://en.wikipedia.org/wiki/Orbital_eccentricity
        var apoapsis: Float {
            get {
                return semimajorAxis * (1 + eccentricity)
            }
            set {
                semimajorAxis = (periapsis + newValue) / 2
                eccentricity = 1 - 2 / ((newValue / periapsis) + 1)
            }
        }
        var periapsis: Float {
            get {
                return semimajorAxis * (1 - eccentricity)
            }
            set {
                semimajorAxis = (apoapsis + newValue) / 2
                eccentricity = 1 - 2 / ((apoapsis / newValue) + 1)
            }
        }
        
        init(semimajorAxis a: Float, eccentricity e: Float) {
            self.semimajorAxis = a
            self.eccentricity = e
        }
        
        init(apoapsis ap: Float, periapsis pe: Float) {
            self.init(semimajorAxis: (ap + pe) / 2, eccentricity: 1 - 2 / ((ap / pe) + 1))
        }
    }
    
    struct Orientation {
        var inclination: Float
        var longitudeOfAscendingNode: Float?
        var argumentOfPeriapsis: Float?
    }

    var shape: Shape
    var orientation: Orientation

    init(shape: Shape, orientation: Orientation) {
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
        self.init(shape: Shape(semimajorAxis: semimajorAxis, eccentricity: eccentricity), orientation: Orientation(inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis))
    }
    
}

struct OrbitalMotion {
    let gravParam: Float
    let orbit: Orbit
    
    var timeElapsed: Float = 0 {
        didSet {
            // time consuming, we only recalculate when mean anomaly is changed
            eccentricAnomaly = calculateEccentricAnomaly(eccentricity: orbit.shape.eccentricity, meanAnomaly: meanAnomaly)
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
    
    var orbitalPeriod: Float {
        return Float(M_PI) * 2 * sqrt(pow(orbit.shape.semimajorAxis, 3) / gravParam)
    }
    
    var meanAnomaly: Float {
        get {
            return calculateMeanAnomaly(fromTime: timeElapsed, gravParam: gravParam, semimajorAxis: orbit.shape.semimajorAxis)
        }
        set {
            timeElapsed = wrapAngle(newValue) / Float(M_PI * 2) * orbitalPeriod
        }
    }
    
    private(set) var eccentricAnomaly: Float = 0
    
    var trueAnomaly: Float {
        return calculateTrueAnomaly(eccentricity: orbit.shape.eccentricity, eccentricAnomaly: eccentricAnomaly)
    }
    
    var distance: Float {
        return orbit.shape.semimajorAxis * (1 - orbit.shape.eccentricity * cos(eccentricAnomaly))
    }
    
    private var positionInOrbitalFrame: SCNVector3 {
        return SCNVector3(x: sin(trueAnomaly), y: cos(trueAnomaly), z: 0) * distance
    }

    private var velocityInOrbitalFrame: SCNVector3 {
        let coefficient = sqrt(gravParam * orbit.shape.semimajorAxis) / distance
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
    
    // e⃗ = ((v^2 − μ/r)r⃗ − (r⃗ ⋅ v⃗ )v⃗) / μ
    var eccentricityVector: SCNVector3 {
        return (position * (velocity.dot(velocity) - gravParam / position.length()) - velocity * position.dot(velocity)) / gravParam
    }
    
    // https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
    init(centralBody: Body, orbit: Orbit, timeElapsed: Float = 0) {
        self.init(centralBody: centralBody, orbit: orbit, meanAnomaly: calculateMeanAnomaly(fromTime: timeElapsed, gravParam: centralBody.gravParam, semimajorAxis: orbit.shape.semimajorAxis))
    }
    
    init(centralBody: Body, orbit: Orbit, meanAnomaly: Float = 0) {
        if orbit.shape.eccentricity >= 1 {
            fatalError("must be circular or elliptical orbit")
        }
        self.gravParam = centralBody.gravParam
        self.orbit = orbit
        self.meanAnomaly = meanAnomaly
    }
    
    // https://space.stackexchange.com/questions/1904/how-to-programmatically-calculate-orbital-elements-using-position-velocity-vecto?newreg=70344ca3afc847acb4f105c7194ff719
//    init(centralBody: Body, position: SCNVector3, velocity: SCNVector3) {
//        
//    }
    
}
