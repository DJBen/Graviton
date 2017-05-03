//
//  PropertyExtractor.swift
//  Graviton
//
//  Created by Sihao Lu on 3/25/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import MathUtil

class PropertyExtractor {
    enum Field {
        case hillSphere
        case rotationPeriod
        case obliquity
        case radius
        case gravParam
    }
    
    let bodyInfo: [String: String]
    
    init(bodyInfo: [String: String]) {
        self.bodyInfo = bodyInfo
    }

    static func extractor(forNaif naif: Int, bodyInfo: [String: String]) -> PropertyExtractor {
        switch Naif(naifId: naif) {
        case .majorBody(let mb):
            if mb != .pluto {
                return PropertyExtractor(bodyInfo: bodyInfo)
            } else {
                return PlutoPropertyExtractor(bodyInfo: bodyInfo)
            }
        default:
            return PropertyExtractor(bodyInfo: bodyInfo)
        }
    }
    
    var hillSphereKeys: [String] {
        return ["Hill's sphere rad. Rp", "Hill's sphere radius", "Hill's sphere rad., Rp"]
    }
    
    var rotationPeriodKeys: [String] {
        return ["Sidereal rot. period", "Sidereal period, hr", "Inferred rot. period", "Orbit period", "Orbital period"]
    }
    
    var obliquityKeys: [String] {
        return ["Obliquity to orbit", "Obliquity to orbit, deg"]
    }
    
    var radiusKeys: [String] {
        return ["Mean radius (km)", "Mean radius, km", "Volumetric mean radius", "Radius (IAU), km"]
    }
    
    func extractField(_ field: Field) -> String? {
        func extractFromKeys(_ keys: [String]) -> String? {
            return keys.reduce(nil) { $0 ?? bodyInfo[$1] }
        }
        switch field {
        case .hillSphere:
            return extractFromKeys(hillSphereKeys)
        case .rotationPeriod:
            return extractFromKeys(rotationPeriodKeys)
        case .obliquity:
            return extractFromKeys(obliquityKeys)
        case .radius:
            return extractFromKeys(radiusKeys)
        default:
            return nil
        }
    }
    
    var radius: Double? {
        guard let km = extractField(.radius) else { return nil }
        if let convertedDouble = Double(km) {
            return convertedDouble * 1000
        }
        let matches = km.matches(for: "([-\\d.]+)(?:(?:\\([\\+-\\.\\d]*\\))|(?:\\+-[\\d\\.]+))")
        guard matches.count > 0 else {
            print("\(km) doesn't match radius regex")
            return nil
        }
        guard matches[0].count > 1 else { return nil }
        return Double(matches[0][1])! * 1000
    }
    
    var hillSphere: Double? {
        if let str = extractField(.hillSphere) {
            return Double(str)!
        }
        return nil
    }
    
    var obliquity: Double? {
        guard let deg = extractField(.obliquity) else { return nil }
        let matches = deg.matches(for: "([-\\d.]+)\\s*(?:deg)?")
        guard matches.count > 0 else { return nil }
        guard matches[0].count > 1 else { return nil }
        return radians(degrees: Double(matches[0][1])!)
    }
    
    func rotationPeriod(naifId: Int, orb: Double) -> Double? {
        let str = extractField(.rotationPeriod)
        if str == nil {
            if naifId == 301 {
                return orb
            }
            return nil
        }
        if str?.lowercased() == "synchronous" {
            return orb
        }
        if let matches = str?.matches(for: "([-\\d.]+)(\\+-[-\\d.]+)?\\s*(hr|d)?") {
            guard matches.count > 0 else { return nil }
            guard matches[0].count > 3 else { return nil }
            guard let result = Double(matches[0][1]) else { return nil }
            if matches[0][3] == "hr" || matches[0][3].isEmpty {
                return result * 3600
            } else if matches[0][3] == "d" {
                return result * 24 * 3600
            } else {
                return nil
            }
        }
        return nil
    }
    
    var gm: Double? {
        let regex = "GM(?:,| \\()(10\\^(\\d+))?\\s*(km\\^3 s\\^-2|km\\^3\\/s\\^2)\\)?"
        // match 2 - exponent or nil (1)
        var exponent: Double = 0
        let gmKeys = bodyInfo.keys.filter { (key) -> Bool in
            let matches = key.matches(for: regex)
            return matches.isEmpty == false
        }
        guard let gmKey = gmKeys.first else { return nil }
        let matches = gmKey.matches(for: regex)
        if matches[0][2].lengthOfBytes(using: .utf8) > 0 {
            exponent = Double(matches[0][2])!
        }
        if let str = bodyInfo[gmKey], let result = Double(str.replacingOccurrences(of: ",", with: "")) {
            return result * pow(10, exponent)
        } else {
            return nil
        }
    }
}
