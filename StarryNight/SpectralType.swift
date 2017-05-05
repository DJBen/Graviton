//
//  SpectralType.swift
//  Orbits
//
//  Created by Ben Lu on 2/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation

public struct SpectralType {
    public let spectralClass: String

    public init?(_ str: String) {
        if str.isEmpty {
            return nil
        }
        if let first = str.characters.first, ["O", "B", "A", "F", "G", "K", "M"].contains(String(first)) {
            spectralClass = String(first)
        } else {
            return nil
        }
    }
}

fileprivate extension String {
    func firstMatches(for regex: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range) }.first
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return nil
        }
    }
}
