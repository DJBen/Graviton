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
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positiveSuffix = " m/s"
        formatter.negativeSuffix = " m/s"
        formatter.positivePrefix = "Vel: "
        formatter.negativePrefix = "Vel: "
        return formatter
    }()
    
    // format distance to km
    static var distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.positiveSuffix = " km"
        formatter.negativeSuffix = " km"
        formatter.positivePrefix = "Alt: "
        formatter.negativePrefix = "Alt: "
        return formatter
    }()
}

extension Body {
    public var velocityString: String? {
        guard let velocity = motion?.velocity.length else { return nil }
        return Formatters.velocityFormatter.string(from: NSNumber(value: velocity))
    }
    
    public var distanceString: String? {
        guard let distance = motion?.distance else { return nil }
        return Formatters.distanceFormatter.string(from: NSNumber(value: distance / 1000))
    }
}
