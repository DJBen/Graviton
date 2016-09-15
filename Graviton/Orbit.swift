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
                eccentricity = 1 - (2 / (newValue / periapsis) + 1)
            }
        }
        var periapsis: Float {
            get {
                return semimajorAxis * (1 - eccentricity)
            }
            set {
                semimajorAxis = (apoapsis + newValue) / 2
                eccentricity = 1 - (2 / (apoapsis / newValue) + 1)
            }
        }
        
        init(semimajorAxis a: Float, eccentricity e: Float) {
            self.semimajorAxis = a
            self.eccentricity = e
        }
        
        init(apoapsis ap: Float, periapsis pe: Float) {
            self.init(semimajorAxis: 0, eccentricity: 0)
            self.apoapsis = ap
            self.periapsis = pe
        }
    }
    
    struct Orientation {
        var inclination: Float
        var longitudeOfAscendingNode: Float?
        var argumentOfPeriapsis: Float
    }

    var shape: Shape
    var orientation: Orientation
    
//    var bodyPosition: SCNVector3
//    var bodyVelocity: SCNVector3
//    
//    var specificMechanicalEnergy: Float {
//        return bodyVelocity.dot(bodyVelocity) / 2 - gravitationParameter / bodyPosition.length()
//    }
//    
//    var eccentricityVector: SCNVector3 {
//        return (bodyPosition * (bodyVelocity.dot(bodyVelocity) - gravitationParameter / bodyPosition.length()) - bodyVelocity * bodyPosition.dot(bodyVelocity)) / gravitationParameter
//    }
    
//     https://downloads.rene-schwarz.com/download/M001-Keplerian_Orbit_Elements_to_Cartesian_State_Vectors.pdf
    
    init(shape: Shape, orientation: Orientation) {
        self.shape = shape
        self.orientation = orientation
    }
    
    init(semimajorAxis: Float, eccentricity: Float, inclination: Float, longitudeOfAscendingNode: Float?, argumentOfPeriapsis: Float) {
        self.init(shape: Shape(semimajorAxis: semimajorAxis, eccentricity: eccentricity), orientation: Orientation(inclination: inclination, longitudeOfAscendingNode: longitudeOfAscendingNode, argumentOfPeriapsis: argumentOfPeriapsis))
    }
    
//    // https://space.stackexchange.com/questions/1904/how-to-programmatically-calculate-orbital-elements-using-position-velocity-vecto?newreg=70344ca3afc847acb4f105c7194ff719
//    init(position: SCNVector3, velocity: SCNVector3) {
//        let angularMomentum = position.cross(velocity)
//        // e⃗ = ((v^2 − μ/r)r⃗ − (r⃗ ⋅ v⃗ )v⃗) / μ
//        let eccentricityVector = (position * (velocity.dot(velocity) - gravitationParameter / position.length()) - velocity * position.dot(velocity)) / gravitationParameter
//    }
}
