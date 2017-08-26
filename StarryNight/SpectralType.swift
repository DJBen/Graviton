//
//  SpectralType.swift
//  Orbits
//
//  Created by Ben Lu on 2/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import Regex

public struct SpectralType {
    public let type: String
    public let subType: String?
    public let luminosityClass: String?

    /// Spectral peculiarities of the star
    ///
    /// seealso: [Stellar Classification](https://en.wikipedia.org/wiki/Stellar_classification)
    public let peculiarities: String?

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
            subType = match.captures[1]
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

fileprivate func nilIfEmpty(_ str: String?) -> String? {
    if let str = str, str.isEmpty {
        return nil
    }
    return str
}
