//
//  Formatters.swift
//  Graviton
//
//  Created by Sihao Lu on 1/9/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SceneKit

public struct Formatters {
    
    // format velocity to m/s
    static var velocityFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 7
        formatter.maximumSignificantDigits = 7
        formatter.positiveSuffix = " m/s"
        formatter.negativeSuffix = " m/s"
        return formatter
    }()
}

extension Body {
    public var velocityString: String? {
        guard let velocity = motion?.velocity.length else {
            return nil
        }
        return Formatters.velocityFormatter.string(from: NSNumber(value: velocity))
    }
}
