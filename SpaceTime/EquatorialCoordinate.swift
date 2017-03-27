//
//  EquatorialCoordinate.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil

public struct EquatorialCoordinate {
    public let distance: Double
    
    /// Right ascension in radians
    public let rightAscension: Double
    
    /// Declination measured north or south of the celestial equator, in radians
    public let declination: Double
    
    // http://www.geom.uiuc.edu/docs/reference/CRC-formulas/node42.html
    public init(cartesian v: Vector3) {
        distance = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
        declination = Double.pi / 2 - acos(v.z / distance)
        rightAscension = wrapAngle(atan2(v.y, v.x))
    }
    
    public init(rightAscension: Double, declination: Double, distance: Double) {
        self.rightAscension = rightAscension
        self.declination = declination
        self.distance = distance
    }
}

public extension Vector3 {
    public init(equatorialCoordinate s: EquatorialCoordinate) {
        self.init(
            s.distance * sin(s.rightAscension) * cos(s.declination),
            s.distance * sin(s.rightAscension) * sin(s.declination),
            s.distance * cos(s.rightAscension)
        )
    }
}

public extension EquatorialCoordinate {
    //
    // ra1, dec1: RA, dec coordinates, in radians, for EPOCH1, where the epoch is in years AD.
    // Output: [RA, dec], in radians, precessed to EPOCH2, where the epoch is in years AD.
    //
    // Original comment:
    // Herget precession, see p. 9 of Publ. Cincinnati Obs., No. 24.
    //
    func precessed(from epoch1: Double, to epoch2: Double) -> EquatorialCoordinate {
        let (ra1, dec1) = (rightAscension, declination)
        var cdr, csr: Double
        var x1, x2: [Double]
        var t, st, a, b, c, sina, sinb, sinc, cosa, cosb, cosc, ra2, dec2: Double
        
        cdr = Double.pi / 180.0
        csr = cdr / 3600.0
        a = cos(dec1)
        x1 = [a*cos(ra1), a*sin(ra1), sin(dec1)]
        t = 0.001*(epoch2 - epoch1)
        st = 0.001*(epoch1 - 1900.0)
        a = csr*t*(23042.53 + st*(139.75 + 0.06*st) + t*(30.23 - 0.27*st + 18.0*t))
        b = csr*t*t*(79.27 + 0.66*st + 0.32*t) + a
        c = csr*t*(20046.85 - st*(85.33 + 0.37*st) + t*(-42.67 - 0.37*st - 41.8*t))
        sina = sin(a)
        sinb = sin(b)
        sinc = sin(c)
        cosa = cos(a)
        cosb = cos(b)
        cosc = cos(c)
        var r = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
        r[0][0] = cosa*cosb*cosc - sina*sinb
        r[0][1] = -cosa*sinb - sina*cosb*cosc
        r[0][2] = -cosb*sinc
        r[1][0] = sina*cosb + cosa*sinb*cosc
        r[1][1] = cosa*cosb - sina*sinb*cosc
        r[1][2] = -sinb*sinc
        r[2][0] = cosa*sinc
        r[2][1] = -sina*sinc
        r[2][2] = cosc
        x2 = [0.0, 0.0, 0.0]
        for i in 0..<3 {
            x2[i] = r[i][0]*x1[0] + r[i][1]*x1[1] + r[i][2]*x1[2]
        }
        ra2 = atan2(x2[1], x2[0])
        if (ra2 < 0.0) {
            ra2 += 2.0 * Double.pi
        }
        dec2 = asin(x2[2])
        return EquatorialCoordinate(rightAscension: ra2, declination: dec2, distance: distance)
    }
}
