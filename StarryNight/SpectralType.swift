//
//  SpectralType.swift
//  Orbits
//
//  Created by Ben Lu on 2/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import Regex
import SQLite

fileprivate let spectralTable = Table("spectral")
fileprivate let spectralTypeColumn = Expression<String>("SpT")
fileprivate let tempColumn = Expression<Double>("Teff")

public struct SpectralType {
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
        let fractionSubtype = "\(type)\(subType != nil ? String(format: "%.1f", subType!) : String())%"
        let integerSubtype = "\(type)\(subType != nil ? String(Int(subType!)) : String())%"
        if let row = try! db.pluck(spectralTable.select(tempColumn).where(spectralTypeColumn.like(fractionSubtype))) {
            return row[tempColumn] + 273.15
        } else if let row = try! db.pluck(spectralTable.select(tempColumn).where(spectralTypeColumn.like(integerSubtype))) {
            return row[tempColumn] + 273.15
        }
        fatalError()
    }

    public init?(_ str: String) {
        if str.isEmpty {
            return nil
        }
        // some spectral type may have ambiguity e.g. G8III/IV
        // will remove anything after /
        let unambiguousType = String(str.characters.prefix(while: { $0 != "/" }))
        switch unambiguousType {
        case Regex("^(\\w)(\\d(?:\\.\\d)?)?((?:IV|Iab|Ia\\+?|Ib|I+|V)(?:-(?:IV|Iab|Ia\\+?|Ib|I+|V))?)?(.*)"):
            let match = Regex.lastMatch!
            type = match.captures[0]!
            subType = doubleOrEmpty(match.captures[1])
            luminosityClass = match.captures[2]
            peculiarities = nilIfEmpty(match.captures[3])
            // do not recognize extended spectral types
            if ["O", "B", "A", "F", "G", "K", "M"].contains(type) == false {
                return nil
            }
        default:
            return nil
        }
    }
}

fileprivate func doubleOrEmpty(_ str: String?) -> Double? {
    if let str = str, let dblValue = Double(str) {
        return dblValue
    }
    return nil
}

fileprivate func nilIfEmpty(_ str: String?) -> String? {
    if let str = str, str.isEmpty {
        return nil
    }
    return str
}
