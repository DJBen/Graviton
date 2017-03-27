//
//  PlutoPropertyExtractor.swift
//  Graviton
//
//  Created by Sihao Lu on 3/27/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class PlutoPropertyExtractor: PropertyExtractor {
    override var radiusKeys: [String] {
        return ["Radius of Pluto, Rp"]
    }
    
    override var gm: Double? {
        return Double(bodyInfo["GM (planet) km^3/s^2"]!)!
    }
    
    override var radius: Double? {
        guard let km = extractField(.radius) else { return nil }
        let matches = km.matches(for: "([\\d\\.]+) km")
        return Double(matches[0][1])! * 1000
    }
}
