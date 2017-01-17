//
//  swift
//  SpaceTime
//
//  Created by Ben Lu on 9/15/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

/// wrap angle into [0, 2π)
public func wrapAngle(_ angle: Double) -> Double {
    let twoPi = M_PI * 2
    var wrapped = fmod(angle, twoPi)
    if wrapped < 0.0 {
        wrapped += twoPi
    }
    return wrapped
}

public func radians(degrees: Double) -> Double {
    return degrees / 180 * Double(M_PI)
}

public func radians(degrees: Double, minutes: Double, seconds: Double = 0) -> Double {
    return radians(degrees: degrees + minutes / 60 + seconds / 3600)
}

public func radians(hours: Double, minutes: Double = 0, seconds: Double = 0) -> Double {
    let h = hourFrac(hours: hours, minutes: minutes, seconds: seconds)
    return h / 12 * M_PI
}

public func degrees(degrees: Double, minutes: Double, seconds: Double = 0) -> Double {
    return degrees + minutes / 60 + seconds / 3600
}

public func hourFrac(hours: Double, minutes: Double, seconds: Double = 0) -> Double {
    return hours + minutes / 60 + seconds / 3600
}
