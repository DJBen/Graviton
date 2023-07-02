//
//  Easing.swift
//  Graviton
//
//  Created by Ben Lu on 2/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation

// http://gizma.com/easing/
public struct Easing {
    public enum EasingFunction {
        case linear
        case quadraticEaseIn
        case quadraticEaseOut
        case quadraticEaseInOut
        case cubicEaseIn
        case cubicEaseOut
        case cubicEaseInOut

        var function: (Double, Double, Double) -> Double {
            switch self {
            case .linear:
                return linearTween
            case .quadraticEaseIn:
                return easeInQuad
            case .cubicEaseIn:
                return easeInCubic
            case .quadraticEaseOut:
                return easeOutQuadratic
            case .cubicEaseOut:
                return easeOutCubic
            case .quadraticEaseInOut:
                return easeInOutQuadratic
            case .cubicEaseInOut:
                return easeInOutCubic
            }
        }
    }

    public let startValue: Double
    public let endValue: Double
    public let easingMethod: EasingFunction

    public init(easingMethod: EasingFunction = .linear, startValue: Double, endValue: Double) {
        self.easingMethod = easingMethod
        self.startValue = startValue
        self.endValue = endValue
    }

    /// Calculate the interpolated value in between the start and end points
    ///
    /// - Parameter progress: The progress between 0 and 1
    /// - Returns: The interpolated value using current easing function
    public func value(at progress: Double) -> Double {
        let percent = clamp(progress, minValue: 0, maxValue: 1)
        return easingMethod.function(startValue, endValue, percent)
    }
}

public func clamp<T: Comparable>(_ v: T, minValue: T, maxValue: T) -> T {
    return min(max(v, minValue), maxValue)
}

fileprivate func polynormialEaseIn(startValue: Double, endValue: Double, progress: Double, exp: Double) -> Double {
    let c = endValue - startValue
    return c * pow(progress, exp) + startValue
}

fileprivate func linearTween(startValue: Double, endValue: Double, progress: Double) -> Double {
    return polynormialEaseIn(startValue: startValue, endValue: endValue, progress: progress, exp: 1)
}

fileprivate func easeInQuad(startValue: Double, endValue: Double, progress: Double) -> Double {
    return polynormialEaseIn(startValue: startValue, endValue: endValue, progress: progress, exp: 2)
}

fileprivate func easeInCubic(startValue: Double, endValue: Double, progress: Double) -> Double {
    return polynormialEaseIn(startValue: startValue, endValue: endValue, progress: progress, exp: 3)
}

fileprivate func easeOutQuadratic(startValue: Double, endValue: Double, progress: Double) -> Double {
    let c = endValue - startValue
    return -c * progress * (progress - 2) + startValue
}

fileprivate func easeOutCubic(startValue: Double, endValue: Double, progress: Double) -> Double {
    let c = endValue - startValue
    let p = progress - 1
    return c * (p * p * p + 1) + startValue
}

fileprivate func easeInOutQuadratic(startValue: Double, endValue: Double, progress: Double) -> Double {
    let c = endValue - startValue
    var t = progress * 2
    if t < 1 {
        return c / 2 * t * t + startValue
    }
    t -= 1
    return -c / 2 * (t * (t - 2) - 1) + startValue
}

fileprivate func easeInOutCubic(startValue: Double, endValue: Double, progress: Double) -> Double {
    let c = endValue - startValue
    var t = progress * 2
    if t < 1 {
        return c / 2 * t * t * t + startValue
    }
    t -= 2
    return c / 2 * (t * t * t + 2) + startValue
}
