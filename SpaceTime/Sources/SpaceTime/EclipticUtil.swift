//
//  EclipticUtil.swift
//  SpaceTime
//
//  Created by Sihao Lu on 12/26/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import Foundation
import MathUtil

public struct EclipticUtil {
    public enum Accuracy {
        case low
        case high
    }

    /// *True*, or apparent obliquity of ecliptic except when referring against the
    /// standard equinox of J2000 and B1950.
    ///
    /// If referred against the standard equinox of J2000.0, the value of obliquity
    /// of ecliptic ε = 23°26′21″.448 = 23°.4392911 is used.
    /// For the standard equinox of B1950.0, we have ε_1950 = 23°.4457889.
    ///
    /// - Parameters:
    ///   - julianDay: The julian day.
    ///   - accuracy: The desired accuracy.
    /// - Returns: *True*, or apparent obliquity of ecliptic, or obliquity at epoch of
    /// the standard equinoxes of J2000 and B1950 when `julianDay` are set to such
    /// values.
    public static func obliquityOfEcliptic(julianDay: JulianDay, accuracy: Accuracy = .high) -> DegreeAngle {
        let ε: DegreeAngle
        if julianDay == .J2000 {
            ε = DegreeAngle(23.4392911)
        } else if julianDay == .B1950 {
            ε = DegreeAngle(23.4457889)
        } else {
            ε = EclipticUtil.trueObliquityOfEcliptic(julianDay: julianDay)
        }
        return ε
    }

    /// Mean obliquity of the ecliptic.
    ///
    /// - Parameters:
    ///   - julianDay: The julian day.
    ///   - accuracy: The desired accuracy. For low accuracy,
    /// the error is 1 arcsecond over period of 2000 years
    /// and 10 arcsecond over period of 4000 years;
    /// for high accuracy, 0.01 arcsecond over period of 1000 years
    /// and few seconds of arc after 10000 years.
    /// - Returns: The mean obliquity of ecliptic.
    /// - note: High accuracy formula is only valid over a 10000 year period on either side of J2000.0.
    public static func meanObliquityOfEcliptic(julianDay: JulianDay, accuracy: Accuracy = .high) -> DegreeAngle {
        let t = julianDay.julianCentury
        if accuracy == .low {
            let d = DegreeAngle(degree: 23, minute: 26, second: 21.448)
            let c = -DegreeAngle(degree: 0, minute: 0, second: 46.815)
            let b = -DegreeAngle(degree: 0, minute: 0, second: 0.00059)
            let a = DegreeAngle(degree: 0, minute: 0, second: 0.001813)
            return polynomial(coefficient: t, terms: [d, c, b, a])
        } else {
            let u = t / 100
            let terms = [
                84381.448,
                -4680.93,
                -1.55,
                1999.25,
                -51.38,
                -249.67,
                -39.05,
                7.12,
                27.87,
                5.79,
                2.45
            ].map { DegreeAngle(degree: 0, minute: 0, second: $0) }
            return polynomial(coefficient: u, terms: terms)
        }
    }

    public static var currentMeanObliquityOfEcliptic: DegreeAngle {
        return meanObliquityOfEcliptic(julianDay: JulianDay.now)
    }

    /// True obliquity of the ecliptic.
    ///
    /// - Parameters:
    ///   - julianDay: The julian day.
    ///   - accuracy: The desired accuracy.
    /// - Returns: The true obliquity of ecliptic.
    public static func trueObliquityOfEcliptic(julianDay: JulianDay, accuracy: Accuracy = .high) -> DegreeAngle {
        return EclipticUtil.meanObliquityOfEcliptic(julianDay: julianDay, accuracy: accuracy) + EclipticUtil.obliquityNutation(julianDay: julianDay, accuracy: accuracy)
    }

    static func meanElongationOfTheMoonFromTheSum(julianDay: JulianDay) -> DegreeAngle {
        let terms = [297.85036, 445267.111480, -0.0019142, 1.0 / 189474].map { DegreeAngle($0) }
        return polynomial(coefficient: julianDay.julianCentury, terms: terms)
    }

    static func meanAnomalyOfTheSun(julianDay: JulianDay) -> DegreeAngle {
        let terms = [357.52772, 35999.050340, -0.0001603, -1.0 / 300000].map { DegreeAngle($0) }
        return polynomial(coefficient: julianDay.julianCentury, terms: terms)
    }

    static func meanAnomalyOfTheMoon(julianDay: JulianDay) -> DegreeAngle {
        let terms = [134.96298, 477198.867398, 0.0086972, 1.0 / 56250].map { DegreeAngle($0) }
        return polynomial(coefficient: julianDay.julianCentury, terms: terms)
    }

    static func moonArgumentOfLatitude(julianDay: JulianDay) -> DegreeAngle {
        let terms = [93.27191, 483202.017538, -0.0036825, 1.0 / 327270].map { DegreeAngle($0) }
        return polynomial(coefficient: julianDay.julianCentury, terms: terms)
    }

    static func loANOfMoonMeanOrbitOnEcliptic(julianDay: JulianDay) -> DegreeAngle {
        let terms = [125.04452, -1934.136261, 0.0020708, 1.0 / 450000].map { DegreeAngle($0) }
        return polynomial(coefficient: julianDay.julianCentury, terms: terms)
    }

    public static func longitudeNutation(julianDay: JulianDay, accuracy: Accuracy = .high) -> DegreeAngle {
        return longitudeAndObliquityNutation(julianDay: julianDay, accuracy: accuracy).0
    }

    public static func obliquityNutation(julianDay: JulianDay, accuracy: Accuracy = .high) -> DegreeAngle {
        return longitudeAndObliquityNutation(julianDay: julianDay, accuracy: accuracy).1
    }

    /// Longitude and obliquity nutations
    ///
    /// - Parameters:
    ///   - julianDay: The Julian day.
    ///   - accuracy: The desired accuracy. For low accuracy, the errors are 0.5 arcsec
    /// for Δψ and 0.1 arcsec for Δε. For high accuracy, the error is 0.0003 arcsec.
    /// - Returns: longitude and obliquity nutations.
    public static func longitudeAndObliquityNutation(julianDay: JulianDay, accuracy: Accuracy = .high) -> (DegreeAngle, DegreeAngle) {
        if accuracy == .low {
            let meanLongitudeOfSun = DegreeAngle(280.4665) + DegreeAngle(36000.7698) * julianDay.julianCentury
            let meanLongitudeOfMoon = DegreeAngle(218.3165) + DegreeAngle(481267.8813) * julianDay.julianCentury
            let Ω = loANOfMoonMeanOrbitOnEcliptic(julianDay: julianDay)
            let (L, L´) = (meanLongitudeOfSun, meanLongitudeOfMoon)
            var Δψ = DegreeAngle(degree: 0, minute: 0, second: -17.2) * sin(Ω)
            Δψ -= DegreeAngle(degree: 0, minute: 0, second: 1.32) * sin(L * 2)
            Δψ -= DegreeAngle(degree: 0, minute: 0, second: 0.23) * sin(L´ * 2)
            Δψ += DegreeAngle(degree: 0, minute: 0, second: 0.21) * sin(Ω * 2)
            var Δε = DegreeAngle(degree: 0, minute: 0, second: 9.2) * cos(Ω)
            Δε += DegreeAngle(degree: 0, minute: 0, second: 0.57) * cos(L * 2)
            Δε += DegreeAngle(degree: 0, minute: 0, second: 0.1) * cos(L´ * 2)
            Δε -= DegreeAngle(degree: 0, minute: 0, second: 0.09) * cos(Ω * 2)
            Δψ.wrapMode = .range_180
            Δε.wrapMode = .range_180
            return (Δψ, Δε)
        } else {
            let params: [DegreeAngle] = [meanElongationOfTheMoonFromTheSum, meanAnomalyOfTheSun, meanAnomalyOfTheMoon, moonArgumentOfLatitude, loANOfMoonMeanOrbitOnEcliptic].map { $0(julianDay) }
            let args = argumentMultiples.map { zip($0, params).map { $1 * Double($0) }.reduce(DegreeAngle(0), +) }
            let (ΔψTenthOfMicroArcsec, ΔεTenthOfMicroArcsec) = zip(args, peTerms).map { (arg, peTerm) -> (Double, Double) in
                let ΔψTerm = sin(arg) * (peTerm[0] + peTerm[1] * julianDay.julianCentury)
                let ΔεTerm = cos(arg) * (peTerm[2] + peTerm[3] * julianDay.julianCentury)
                return (ΔψTerm, ΔεTerm)
            }.reduce((0, 0)) { ($0.0 + $1.0, $0.1 + $1.1) }
            let (Δψ, Δε) = (DegreeAngle(degree: 0, minute: 0, second: ΔψTenthOfMicroArcsec / 10e3), DegreeAngle(degree: 0, minute: 0, second: ΔεTenthOfMicroArcsec / 10e3))
            Δψ.wrapMode = .range_180
            Δε.wrapMode = .range_180
            return (Δψ, Δε)
        }
    }
}

private func polynomial<T: Angle>(coefficient t: Double, terms: [T]) -> T {
    return terms.enumerated().map { (index, term) -> T in
        return term * pow(t, Double(index))
    }.reduce(T(0), +)
}

private let argumentMultiples: [[Int]] = [
    [0, 0, 0, 0, 1],
    [-2, 0, 0, 2, 2],
    [0, 0, 0, 2, 2],
    [0, 0, 0, 0, 2],
    [0, 1, 0, 0, 0],
    [0, 0, 1, 0, 0],
    [-2, 1, 0, 2, 2],
    [0, 0, 0, 2, 1],
    [0, 0, 1, 2, 2],
    [-2, -1, 0, 2, 2],
    [-2, 0, 1, 0, 0],
    [-2, 0, 0, 2, 1],
    [0, 0, -1, 2, 2],
    [2, 0, 0, 0, 0],
    [0, 0, 1, 0, 1],
    [2, 0, -1, 2, 2],
    [0, 0, -1, 0, 1],
    [0, 0, 1, 2, 1],
    [-2, 0, 2, 0, 0],
    [0, 0, -2, 2, 1],
    [2, 0, 0, 2, 2],
    [0, 0, 2, 2, 2],
    [0, 0, 2, 0, 0],
    [-2, 0, 1, 2, 2],
    [0, 0, 0, 2, 0],
    [-2, 0, 0, 2, 0],
    [0, 0, -1, 2, 1],
    [0, 2, 0, 0, 0],
    [2, 0, -1, 0, 1],
    [-2, 2, 0, 2, 2],
    [0, 1, 0, 0, 1],
    [-2, 0, 1, 0, 1],
    [0, -1, 0, 0, 1],
    [0, 0, 2, -2, 0],
    [2, 0, -1, 2, 1],
    [2, 0, 1, 2, 2],
    [0, 1, 0, 2, 2],
    [-2, 1, 1, 0, 0],
    [0, -1, 0, 2, 2],
    [2, 0, 0, 2, 1],
    [2, 0, 1, 0, 0],
    [-2, 0, 2, 2, 2],
    [-2, 0, 1, 2, 1],
    [2, 0, -2, 0, 1],
    [2, 0, 0, 0, 1],
    [0, -1, 1, 0, 0],
    [-2, -1, 0, 2, 1],
    [-2, 0, 0, 0, 1],
    [0, 0, 2, 2, 1],
    [-2, 0, 2, 0, 1],
    [-2, 1, 0, 2, 1],
    [0, 0, 1, -2, 0],
    [-1, 0, 1, 0, 0],
    [-2, 1, 0, 0, 0],
    [1, 0, 0, 0, 0],
    [0, 0, 1, 2, 0],
    [0, 0, -2, 2, 2],
    [-1, -1, 1, 0, 0],
    [0, 1, 1, 0, 0],
    [0, -1, 1, 2, 2],
    [2, -1, -1, 2, 2],
    [0, 0, 3, 2, 2],
    [2, -1, 0, 2, 2],
]

private let peTerms: [[Double]] = [
    [-171996, -174.2, 92025, 8.9],
    [-13187, -1.6, 5736, -3.1],
    [-2274, -0.2, 977, -0.5],
    [2062, 0.2, -895, 0.5],
    [1426, -3.4, 54, -0.1],
    [712, 0.1, -7, 0],
    [-517, 1.2, 224, -0.6],
    [-386, -0.4, 200, 0],
    [-301, 0, 129, -0.1],
    [217, -0.5, -95, 0.3],
    [-158, 0, 0, 0],
    [129, 0.1, -70, 0],
    [123, 0, -53, 0],
    [63, 0, 0, 0],
    [63, 0.1, -33, 0],
    [-59, 0, 26, 0],
    [-58, -0.1, 32, 0],
    [-51, 0, 27, 0],
    [48, 0, 0, 0],
    [46, 0, -24, 0],
    [-38, 0, 16, 0],
    [-31, 0, 13, 0],
    [29, 0, 0, 0],
    [29, 0, -12, 0],
    [26, 0, 0, 0],
    [-22, 0, 0, 0],
    [21, 0, -10, 0],
    [17, -0.1, 0, 0],
    [16, 0, -8, 0],
    [-16, 0.1, 7, 0],
    [-15, 0, 9, 0],
    [-13, 0, 7, 0],
    [-12, 0, 6, 0],
    [11, 0, 0, 0],
    [-10, 0, 5, 0],
    [-8, 0, 3, 0],
    [7, 0, -3, 0],
    [-7, 0, 0, 0],
    [-7, 0, 3, 0],
    [-7, 0, 3, 0],
    [6, 0, 0, 0],
    [6, 0, -3, 0],
    [6, 0, -3, 0],
    [-6, 0, 3, 0],
    [-6, 0, 3, 0],
    [5, 0, 0, 0],
    [-5, 0, 3, 0],
    [-5, 0, 3, 0],
    [-5, 0, 3, 0],
    [4, 0, 0, 0],
    [4, 0, 0, 0],
    [4, 0, 0, 0],
    [-4, 0, 0, 0],
    [-4, 0, 0, 0],
    [-4, 0, 0, 0],
    [3, 0, 0, 0],
    [-3, 0, 0, 0],
    [-3, 0, 0, 0],
    [-3, 0, 0, 0],
    [-3, 0, 0, 0],
    [-3, 0, 0, 0],
    [-3, 0, 0, 0],
    [-3, 0, 0, 0],
]
