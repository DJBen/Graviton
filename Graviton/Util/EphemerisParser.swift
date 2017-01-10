//
//  EphemerisParser.swift
//  Graviton
//
//  Created by Sihao Lu on 12/23/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Orbits
import SpaceTime

public struct EphemerisParser {
    
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
        let bodies = list.flatMap { (naifId, csv) -> CelestialBody? in
            guard let motion = EphemerisParser.parse(csv: csv) else {
                return nil
            }
            // hack
            let body = CelestialBody(naifId: Int(naifId)!, mass: 0, radius: 0)
            body.motion = motion
            return body
        }
        return Ephemeris(celestialBodies: bodies)
    }
    
    public static func parse(csv: String) -> OrbitalMotion? {
        let components = csv.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }.filter { $0.isEmpty == false }
        
        guard components.count == 14 || components.count == 28 else {
            return nil
        }
        
        if let jd = Double(components[0]), let ec = Double(components[2]), let semimajorAxis = Double(components[11]), let inclinationDeg = Double(components[4]), let loanDeg = Double(components[5]), let aopDeg = Double(components[6]), let tp = Double(components[7]) {
            let inclination = radians(degrees: inclinationDeg)
            let loan = radians(degrees: loanDeg)
            let aop = radians(degrees: aopDeg)
            let orbit = Orbit(semimajorAxis: semimajorAxis * 1000, eccentricity: ec, inclination: inclination, longitudeOfAscendingNode: loan, argumentOfPeriapsis: aop)
            let motion = OrbitalMotionMoment(centralBody: Sun.sol, orbit: orbit, julianDate: jd, timeOfPeriapsisPassage: tp)
            return motion
        }
        
        return nil
    }
}

fileprivate extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range) }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
