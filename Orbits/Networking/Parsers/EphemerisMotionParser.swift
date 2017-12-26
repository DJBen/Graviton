//
//  EphemerisParser.swift
//  StarCatalog
//
//  Created by Sihao Lu on 12/23/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SpaceTime
import MathUtil

public final class EphemerisMotionParser: CommonParser, Parser {
    public typealias Result = [OrbitalMotion]

    public static let `default` = EphemerisMotionParser()

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

    private func parseEphemerisLine(naifId: Int, gm: Double, line: String, save: Bool) -> OrbitalMotion? {
        let components = line.components(separatedBy: ",").map { $0.trimmed() }.filter { $0.isEmpty == false }
        guard components.count == 14 else { return nil }
        if let jd = Double(components[0]), let ec = Double(components[2]), let semimajorAxis = Double(components[11]), let inclinationDeg = Double(components[4]), let loanDeg = Double(components[5]), let aopDeg = Double(components[6]), let tp = Double(components[7]) {
            let inclination = radians(degrees: inclinationDeg)
            let loan = radians(degrees: loanDeg)
            let aop = radians(degrees: aopDeg)
            let orbit = Orbit(semimajorAxis: semimajorAxis * 1000, eccentricity: ec, inclination: inclination, longitudeOfAscendingNode: loan, argumentOfPeriapsis: aop)
            let motion = OrbitalMotionMoment(orbit: orbit, gm: gm, julianDay: JulianDay(jd), timeOfPeriapsisPassage: JulianDay(tp))
            if save {
                motion.save(forBodyId: naifId)
                logger.info("motion of \(naifId) @ epoch \(jd) (\(components[1])) saved")
            }
            return motion
        }
        return nil
    }

    private func breakEphemerisIntoLines(content: String) -> [String] {
        guard let start = content.range(of: "$$SOE")?.upperBound,
            let end = content.range(of: "$$EOE")?.lowerBound else { fatalError() }
        let str = content[start..<end]
        return str.components(separatedBy: "\n").filter { $0.trimmed().isEmpty == false }
    }

    public func parse(content: String) -> [OrbitalMotion] {
        return parse(content: content, save: false)
    }

    public func parse(content: String, save: Bool = false) -> [OrbitalMotion] {
        func systemGM(_ str: String?) -> Double {
            let regex = "([-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?)\\s*(km\\^3 s\\^-2|km\\^3\\/s\\^2)"
            let matches = str!.matches(for: regex)
            return Double(matches[0][1])! * 10e8
        }
        let systemInfo = parseLineBasedContent(content)
        let systemGm = systemGM(systemInfo["Keplerian GM"]?.0 ?? systemInfo["System GM"]?.0)
        let lines = breakEphemerisIntoLines(content: content)
        guard let naifId = extractNameId(systemInfo["Target body name"])?.1 else { fatalError() }
        return lines.flatMap { self.parseEphemerisLine(naifId: naifId, gm: systemGm, line: $0, save: save) }
    }
}
