//
//  BayerFlamsteed.swift
//  Graviton
//
//  Created by Ben Lu on 6/29/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import Regex

// superscripts from 1 to 9
fileprivate let superscripts = ["", "\u{00b9}", "\u{00b2}", "\u{00b3}", "\u{2074}", "\u{2075}", "\u{2076}", "\u{2077}", "\u{2078}", "\u{2079}"]

struct BayerFlamsteed: CustomStringConvertible {
    enum DesignationType {
        case bayer
        case flamsteed
        case bayerFlamsteed
    }

    var description: String {
        switch type {
        case .bayer:
            return "\(greekLetter!) \(constellation.genitive)"
        case .flamsteed:
            return "\(flamsteed!)\(superscriptedBinaryNumber) \(constellation.genitive)"
        case .bayerFlamsteed:
            return "\(flamsteed!) \(greekLetter!)\(superscriptedBinaryNumber) \(constellation.genitive)"
        }
    }

    var superscriptedBinaryNumber: String {
        if let num = binaryNumber {
            return superscripts[num]
        } else {
            return ""
        }
    }

    let type: DesignationType
    let flamsteed: Int?
    let greekLetter: GreekLetter?
    let binaryNumber: Int?
    let constellation: Constellation

    init?(_ str: String) {
        switch str {
        case Regex("(\\d+)?\\s*(\\w{2,3})?\\s*(\\d)?(\\w{2,3})"):
            let match = Regex.lastMatch!
            if let flamsteedNumber = match.captures[0] {
                flamsteed = Int(flamsteedNumber)!
                if let bayerGreek = match.captures[1] {
                    type = .bayerFlamsteed
                    greekLetter = GreekLetter(shortEnglish: bayerGreek)!
                } else {
                    type = .flamsteed
                    greekLetter = nil
                }
            } else if let bayerGreek = match.captures[1] {
                type = .bayer
                greekLetter = GreekLetter(shortEnglish: bayerGreek)!
                flamsteed = nil
            } else {
                fatalError()
            }
            let con = match.captures[3]!
            constellation = Constellation.iau(con)!
            if let bnStr = match.captures[2], let bnInt = Int(bnStr) {
                binaryNumber = bnInt
            } else {
                binaryNumber = nil
            }
        default:
            return nil
        }
    }
}

// http://www.unicode.org/charts/PDF/U0370.pdf
struct GreekLetter: CustomStringConvertible {
    private static let greekAlphabetEnglish = [
        "alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta", "iota", "kappa", "lambda", "mu", "nu", "xi", "omikron", "pi", "rho", "sigma", "tau", "upsilon", "phi", "chi", "psi", "omega"
    ]

    private static func indexFromShortEnglish(_ english: String) -> Int? {
        let threeOrEnd = min(english.lengthOfBytes(using: .utf8), 3)
        let threeLetter = english.lowercased().substring(to: english.index(english.startIndex, offsetBy: threeOrEnd))
        guard let index = greekAlphabetEnglish.index(where: { (string) -> Bool in
            let threeOrEnd = min(string.lengthOfBytes(using: .utf8), 3)
            return string.substring(to: string.index(string.startIndex, offsetBy: threeOrEnd)) == threeLetter
        }) else {
            return nil
        }
        return index
    }

    static func at(index: Int) -> String {
        // eliminate out-of-bound error
        _ = greekAlphabetEnglish[index]
        var rawValue = UnicodeScalar("α")!.value + UInt32(index)
        // offset duplicate sigmas
        if rawValue >= UnicodeScalar("ς")!.value {
            rawValue += 1
        }
        let character = Character(UnicodeScalar(rawValue)!)
        return String(character)
    }

    let index: Int

    init(index: Int) {
        self.index = index
    }

    init?(shortEnglish: String) {
        if let index = GreekLetter.indexFromShortEnglish(shortEnglish) {
            self.index = index
        } else {
            return nil
        }
    }

    var description: String {
        return GreekLetter.at(index: self.index)
    }
}
