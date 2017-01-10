//
//  SphericalCoordinate.swift
//  Graviton
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SceneKit

public struct SphericalCoordinate {
    public let distance: Double
    public let rightAscension: Double
    public let declination: Double
    
    // http://www.geom.uiuc.edu/docs/reference/CRC-formulas/node42.html
    public init(cartesian v: SCNVector3) {
        distance = sqrt(Double(v.x * v.x + v.y * v.y + v.z * v.z))
        rightAscension = acos(Double(v.z) / distance)
        declination = atan2(Double(v.y), Double(v.x))
    }
    
    public init(rightAscension: Double, declination: Double, distance: Double) {
        self.rightAscension = rightAscension
        self.declination = declination
        self.distance = distance
    }
    
    func rotated(northPoleRA ra: Double, northPoleDE de: Double) -> SphericalCoordinate {
        // TODO: used for martian celestial pole
        return self
    }
}

public extension SCNVector3 {
    public init(sphericalCoordinate s: SphericalCoordinate) {
        self.init(
            s.distance * sin(s.rightAscension) * cos(s.declination),
            s.distance * sin(s.rightAscension) * sin(s.declination),
            s.distance * cos(s.rightAscension)
        )
    }
}
