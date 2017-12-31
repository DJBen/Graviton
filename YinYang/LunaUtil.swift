//
//  LunaUtil.swift
//  YinYang
//
//  Created by Sihao Lu on 12 / 26 / 17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil
import SpaceTime

/// A moon utility struct that performs high precision calculations.
/// Formulas adopted from Jean Meeus, 1991
public struct LunaUtil {
    /// Moon's ecliptic coordinate at specified julian day.
    ///
    /// - Parameter julianDay: Time specified with julian day
    /// - Returns: Moon's ecliptic coordinate at specified julian day
    public static func moonEclipticCoordinate(forJulianDay julianDay: JulianDay) -> EclipticCoordinate {
        let t = julianDay.julianCentury
        let ecc = 1 - 0.002516 * t - 0.0000074 * t * t
        let L´ = moonMeanLongitude(forJulianDay: julianDay)
        let D = moonMeanElongation(forJulianDay: julianDay)
        let M = sunMeanAnomaly(forJulianDay: julianDay)
        let M´ = moonMeanAnomaly(forJulianDay: julianDay)
        let F = moonLatitudeArgument(forJulianDay: julianDay)
        let args = [D, M, M´, F]
        let (Σl, Σr) = mldTerms.map { (terms) -> (Double, Double) in
            let linearTermSum = zip(args, terms).map { $0 * Double($1) }.reduce(DegreeAngle(0), +)
            var Σl = sin(linearTermSum) * Double(terms[4])
            var Σr = cos(linearTermSum) * Double(terms[5])
            if terms[1] != 0 {
                Σl *= pow(ecc, abs(Double(terms[1])))
                Σr *= pow(ecc, abs(Double(terms[1])))
            }
            return (Σl, Σr)
        }.reduce((0.0, 0.0), { ($0.0 + $1.0, $0.1 + $1.1) })
        let Σb = mbTerms.map { (terms) -> (Double) in
            let linearTermSum = zip(args, terms).map { $0 * Double($1) }.reduce(DegreeAngle(0), +)
            var Σb = sin(linearTermSum) * Double(terms[4])
            if terms[1] != 0 {
                Σb *= pow(ecc, abs(Double(terms[1])))
            }
            return Σb
        }.reduce(0, +)
        let a1 = DegreeAngle(119.75 + 131.849 * t)
        let a2 = DegreeAngle(53.09 + 479264.290 * t)
        let a3 = DegreeAngle(313.45 + 481266.484 * t)
        let ΔΣl = 3958 * sin(a1) + 318 * sin(a2) + 1962 * sin(L´ - F)
        var ΔΣb = -2235 * sin(L´)
        ΔΣb += 382 * sin(a3)
        ΔΣb += 175 * sin(a1 - F)
        ΔΣb += 175 * sin(a1 + F)
        ΔΣb += 127 * sin(L´ - M´)
        ΔΣb -= 115 * sin(L´ + M´)
        let longitude = L´ + DegreeAngle((Σl + ΔΣl) / 1e6)
        let latitude = DegreeAngle((Σb + ΔΣb) / 1e6)
        let distance = 385000.56 + Σr / 1000
        return EclipticCoordinate(longitude: longitude, latitude: latitude, distance: distance, julianDay: julianDay)
    }

    static func moonMeanLongitude(forJulianDay julianDay: JulianDay) -> DegreeAngle {
        return polynomial(coefficient: julianDay.julianCentury, terms: 218.3164591, 481267.88134236, -0.0013268, 1.0 / 538841, -1.0 / 65194000)
    }

    static func moonMeanElongation(forJulianDay julianDay: JulianDay) -> DegreeAngle {
        return polynomial(coefficient: julianDay.julianCentury, terms: 297.8502042, 445267.1115168, -0.0016300, 1.0 / 545868, -1.0 / 113065000)
    }

    static func sunMeanAnomaly(forJulianDay julianDay: JulianDay) -> DegreeAngle {
        return polynomial(coefficient: julianDay.julianCentury, terms: 357.5291092, 35999.0502909, -0.0001536, 1.0 / 24490000)
    }

    static func moonMeanAnomaly(forJulianDay julianDay: JulianDay) -> DegreeAngle {
        return polynomial(coefficient: julianDay.julianCentury, terms: 134.9634114, 477198.8676313, 0.0089970, 1.0 / 69699, -1.0 / 14712000)
    }

    static func moonLatitudeArgument(forJulianDay julianDay: JulianDay) -> DegreeAngle {
        return polynomial(coefficient: julianDay.julianCentury, terms: 93.2720993, 483202.0175233, -0.0034029, -1.0 / 3526000, 1.0 / 863310000)
    }
}

private func polynomial<T: Angle>(coefficient t: Double, terms: T...) -> T {
    return terms.enumerated().map { (index, term) -> T in
        return term * pow(t, Double(index))
    }.reduce(T(0), +)
}
