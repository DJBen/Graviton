//
//  SpectralType.swift
//  Orbits
//
//  Created by Ben Lu on 2/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SQLite
import Regex

public struct SpectralType: CustomStringConvertible {
    public let rawType: String
    public var description: String {
        return rawType
    }

    public let type: String
    public let subType: Double?
    public let luminosityClass: String?

    /// Spectral peculiarities of the star
    ///
    /// seealso: [Stellar Classification](https://en.wikipedia.org/wiki/Stellar_classification)
    public let peculiarities: String?

    private var shortenedSpectralType: String {
        return "\(type)\(subType != nil ? String(subType!) : String())\(luminosityClass ?? String())"
    }

    /// The effective temperature
    public var temperature: Double {
        guard let subType = subType else {
            return 0
        }

        let fractionSubtype = "\(type)\(subType != nil ? String(format: "%.1f", subType) : String())%"
        let integerSubtype = "\(type)\(subType != nil ? String(Int(subType)) : String())%"
        if let row = try? StarryNight.db.pluck(
            StarryNight.Spectral.table.select(StarryNight.Spectral.temp).where(StarryNight.Spectral.spectralType.like(fractionSubtype))
        ) {
            return row[StarryNight.Spectral.temp] + 273.15
        } else if let row = try? StarryNight.db.pluck(
            StarryNight.Spectral.table.select(StarryNight.Spectral.temp).where(StarryNight.Spectral.spectralType.like(integerSubtype))
        ) {
            return row[StarryNight.Spectral.temp] + 273.15
        }
        // This is rare but may happen
        return 0
    }

    public init?(_ str: String) {
        if str.isEmpty {
            return nil
        }
        self.rawType = str
        // some spectral type may have ambiguity e.g. G8III/IV
        // will remove anything after /
        let unambiguousType = String(str.prefix(while: { $0 != "/" }))
        switch unambiguousType {
        case Regex("^(\\w)(\\d(?:\\.\\d)?)?((?:IV|Iab|Ia\\+?|Ib|I+|V)(?:-(?:IV|Iab|Ia\\+?|Ib|I+|V))?)?(.*)"):
            // do not recognize extended spectral types
            if let match = Regex.lastMatch, let type = match.captures[0], ["O", "B", "A", "F", "G", "K", "M"].contains(type) {
                self.type = type
                subType = doubleOrEmpty(match.captures[1])
                luminosityClass = match.captures[2]
                peculiarities = nilIfEmpty(match.captures[3])
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

private func doubleOrEmpty(_ str: String?) -> Double? {
    if let str = str, let dblValue = Double(str) {
        return dblValue
    }
    return nil
}

private func nilIfEmpty(_ str: String?) -> String? {
    if let str = str, str.isEmpty {
        return nil
    }
    return str
}
