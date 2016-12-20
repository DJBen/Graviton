//
//  EphemerisParser.swift
//  Horizons
//
//  Created by Ben Lu on 10/4/16.
//
//

import Foundation
import Orbits

public struct ResponseValidator {
    public enum Result {
        case ok(String)
        case busy
    }
    
    public static func parse(content: String) -> Result {
        if content.contains("Blocked Concurrent Request") {
            return .busy
        } else {
            return .ok(content)
        }
    }
}

public struct ResponseParser {
    public static func parse(content: String) -> EphemerisResult? {
        let ephemerisRegex = "\\$\\$SOE\\s*(([^,]*,\\s*)*)\\s*\\$\\$EOE"
        let regex = try! NSRegularExpression(pattern: ephemerisRegex)
        let results = regex.matches(in: content, range: NSRange(location: 0, length: (content as NSString).length))
        guard results.count > 0 else {
            return nil
        }
        let range = results[0].rangeAt(1)
        let matched = (content as NSString).substring(with: range)
        return EphemerisParser.parse(csv: matched)
    }
}

public typealias EphemerisResult = (motion: OrbitalMotion, julianDate: Double)

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
        var jd: Double?
        let bodies = list.flatMap { (naifId, csv) -> CelestialBody? in
            guard let parsed = EphemerisParser.parse(csv: csv) else {
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
        
        if let JDN = Double(components[0]), let ec = Float(components[2]), let semimajorAxis = Float(components[11]), let inclinationDeg = Float(components[4]), let loanDeg = Float(components[5]), let aopDeg = Float(components[6]), let tp = Float(components[7]) {
            let inclination = radians(from: inclinationDeg)
            let loan = radians(from: loanDeg)
            let aop = radians(from: aopDeg)
            let orbit = Orbit(semimajorAxis: semimajorAxis * 1000, eccentricity: ec, inclination: inclination, longitudeOfAscendingNode: loan, argumentOfPeriapsis: aop)
            let motion = OrbitalMotion(centralBody: CelestialBody.sun, orbit: orbit, timeOfPeriapsisPassage: tp, JDN: Float(JDN))
            return (motion: motion, julianDate: JDN)
        }
        
        return nil
    }
}

fileprivate func radians(from degrees: Float) -> Float {
    return degrees / 180 * Float(M_PI)
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

