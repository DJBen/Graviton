//
//  swift
//  SpaceTime
//
//  Created by Ben Lu on 9/15/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

/// wrap angle into [0, 2π)
public func wrapAngle(_ angle: Float) -> Float {
    let twoPi = Float(M_PI * 2)
    var wrapped = fmod(angle, twoPi)
    if wrapped < 0.0 {
        wrapped += twoPi
    }
    return wrapped
}

public func radians(degrees: Float) -> Float {
    return degrees / 180 * Float(M_PI)
}

public func radians(degrees: Float, minutes: Float, seconds: Float = 0) -> Float {
    return radians(degrees: degrees + minutes / 60 + seconds / 3600)
}

public func radians(hours: Float, minutes: Float = 0, seconds: Float = 0) -> Float {
    let h = hourFrac(hours: hours, minutes: minutes, seconds: seconds)
    return h / 12 * Float(M_PI)
}

public func degrees(degrees: Float, minutes: Float, seconds: Float = 0) -> Float {
    return degrees + minutes / 60 + seconds / 3600
}

public func hourFrac(hours: Float, minutes: Float, seconds: Float = 0) -> Float {
    return hours + minutes / 60 + seconds / 3600
}
