//
//  Parser.swift
//  Horizons
//
//  Created by Ben Lu on 10/4/16.
//
//

import Foundation
import Orbits

public struct Parser {
    
    // The csv is ordered as follows:
    // JDTDB, Calendar Date (TDB), EC, QR, IN, OM, W, Tp, N, MA, TA, A, AD, PR
    //
    // Ecliptic and Mean Equinox of Reference Epoch
    // Reference epoch: J2000.0
    // XY-plane: plane of the Earth's orbit at the reference epoch
    // Note: obliquity of 84381.448 arcseconds wrt ICRF equator (IAU76)
    // X-axis  : out along ascending node of instantaneous plane of the Earth's
    // orbit and the Earth's mean equator at the reference epoch
    // Z-axis  : perpendicular to the xy-plane in the directional (+ or -) sense
    // of Earth's north pole at the reference epoch.
    //
    // Symbol meaning:
    //
    // JDTDB  Julian Day Number, Barycentric Dynamical Time
    // EC     Eccentricity, e
    // QR     Periapsis distance, q (km)
    // IN     Inclination w.r.t XY-plane, i (degrees)
    // OM     Longitude of Ascending Node, OMEGA, (degrees)
    // W      Argument of Perifocus, w (degrees)
    // Tp     Time of periapsis (Julian Day Number)
    // N      Mean motion, n (degrees/sec)
    // MA     Mean anomaly, M (degrees)
    // TA     True anomaly, nu (degrees)
    // A      Semi-major axis, a (km)
    // AD     Apoapsis distance (km)
    // PR     Sidereal orbit period (sec)
    
    /// parse orbital elements in csv format from JPL Horizons telnet server
    /// - parameter csv: the string contains csv
    
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        // julian date guarantees AD
        formatter.dateFormat = "yyyy-MMM-dd HH:mm:ss.SSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en-US")
        return formatter
    }
    
    // FIXME: mass and radius are 0
    public static func parse(list: [String: String]) -> Ephemeris? {
        var jd: Double?
        let bodies = list.flatMap { (naifId, csv) -> CelestialBody? in
            guard let parsed = Parser.parse(csv: csv) else {
                return nil
            }
            // hack
            let body = CelestialBody(name: naifId, mass: 0, radius: 0)
            body.motion = parsed.motion
            jd = parsed.julianDate
            return body
        }
        if jd == nil {
            return nil
        }
        return Ephemeris(julianDate: JulianDate(value: jd!), celestialBodies: bodies)
    }
    
    public static func parse(csv: String) -> (motion: OrbitalMotion, julianDate: Double)? {
        let components = csv.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }.filter { $0.isEmpty == false }
        guard components.count == 14 else {
            return nil
        }
        
//        let dateString = components[1].substring(from: components[1].index(components[1].startIndex, offsetBy: 5))
        if /*let date = Parser.dateFormatter.date(from: dateString),*/
            let JDN = Double(components[0]),
            let ec = Float(components[2]),
            let semimajorAxis = Float(components[11]),
            let inclinationDeg = Float(components[4]),
            let loanDeg = Float(components[5]),
            let aopDeg = Float(components[6]),
            let meanAnomalyDeg = Float(components[9]) {
            let inclination = radians(from: inclinationDeg)
            let meanAnomaly = radians(from: meanAnomalyDeg)
            let loan = radians(from: loanDeg)
            let aop = radians(from: aopDeg)
            let orbit = Orbit(semimajorAxis: semimajorAxis * 1000, eccentricity: ec, inclination: inclination, longitudeOfAscendingNode: loan, argumentOfPeriapsis: aop)
            let motion = OrbitalMotion(centralBody: CelestialBody.sun, orbit: orbit, meanAnomalyAtEpoch: meanAnomaly, timeElapsed: 0)
            return (motion: motion, julianDate: JDN)
        }
        // because of perturbations, we use the curreent JDTDB as epoch
        
        return nil
    }
}

fileprivate func radians(from degrees: Float) -> Float {
    return degrees / 180 * Float(M_PI)
}

