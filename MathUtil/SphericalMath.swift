//
//  swift
//  SpaceTime
//
//  Created by Ben Lu on 9/15/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

/// wrap longitude in degrees into [-180, 180)
public func wrapLongitude(_ longitude: Double) -> Double {
    let wrapped = fmod(longitude, 360)
    return wrapped < 180 ? wrapped : wrapped - 360
}

/// wrap angle in radians into [0, 2π)
public func wrapAngle(_ angle: Double) -> Double {
    let twoPi = Double.pi * 2
    var wrapped = fmod(angle, twoPi)
    if wrapped < 0.0 {
        wrapped += twoPi
    }
    return wrapped
}

public func hours(radians: Double) -> Double {
    return radians / Double.pi * 12
}

public func radians(degrees: Double) -> Double {
    return degrees / 180 * Double.pi
}

public func radians(degrees: Double, minutes: Double, seconds: Double = 0) -> Double {
    return radians(degrees: degrees + minutes / 60 + seconds / 3600)
}

public func radians(hours: Double) -> Double {
    return hours / 12 * Double.pi
}

public func radians(hours: Double, minutes: Double, seconds: Double = 0) -> Double {
    let h = hourFrac(hours: hours, minutes: minutes, seconds: seconds)
    return h / 12 * Double.pi
}

public func degrees(degrees: Double, minutes: Double, seconds: Double = 0) -> Double {
    return degrees + minutes / 60 + seconds / 3600
}

public func degrees(radians: Double) -> Double {
    return radians / Double.pi * 180
}

public func hourFrac(hours: Double, minutes: Double, seconds: Double = 0) -> Double {
    return hours + minutes / 60 + seconds / 3600
}
