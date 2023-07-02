//
//  CompoundAngle.swift
//  MathUtil
//
//  Created by Sihao Lu on 12/27/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import Foundation

public protocol CompoundAngle {
    var sign: Int { get }
    var components: [Double] { get }
    var compoundDescription: String { get }
    var compoundDecimalNumberFormatter: NumberFormatter? { get set }
}
