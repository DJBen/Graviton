//
//  swift
//  SpaceTime
//
//  Created by Ben Lu on 9/15/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

/// wrap longitude in degrees into [-180, 180)
@available(*, deprecated, message: "use -[DegreeAngle wrappedValue] with `wrapMode` set to `range_180`.")
public func wrapLongitude(_ longitude: Double) -> Double {
    let wrapped = fmod(longitude, 360)
    return wrapped < 180 ? wrapped : wrapped - 360
}

/// wrap angle in radians into [0, 2π)
@available(*, deprecated, message: "use -[RadianAngle wrappedValue].")
public func wrapAngle(_ angle: Double) -> Double {
    let twoPi = Double.pi * 2
    var wrapped = fmod(angle, twoPi)
    if wrapped < 0.0 {
        wrapped += twoPi
    }
    return wrapped
}

@available(*, deprecated, message: "use -[HourAngle wrappedValue].")
public func wrapHour(_ hour: Double) -> Double {
    let wrapped = fmod(hour, 24)
    return wrapped < 0 ? wrapped + 24 : wrapped
}

@available(*, deprecated, message: "use `HourAngle(radianAngle:)`.")
public func hours(radians: Double) -> Double {
    return radians / Double.pi * 12
}

@available(*, deprecated, message: "use `RadianAngle(degreeAngle:)`.")
public func radians(degrees: Double) -> Double {
    return degrees / 180 * Double.pi
}

@available(*, deprecated, message: "use `RadianAngle(degreeAngle:)`.")
public func radians(degrees: Double, minutes: Double, seconds: Double = 0) -> Double {
    return radians(degrees: degrees + minutes / 60 + seconds / 3600)
}

@available(*, deprecated, message: "use `RadianAngle(hourAngle:)`.")
public func radians(hours: Double) -> Double {
    return hours / 12 * Double.pi
}

@available(*, deprecated, message: "use `RadianAngle(hourAngle:)`.")
public func radians(hours: Double, minutes: Double, seconds: Double = 0) -> Double {
    let h = hourFrac(hours: hours, minutes: minutes, seconds: seconds)
    return h / 12 * Double.pi
}

@available(*, deprecated, message: "use `DegreeAngle(degree:minute:second:)`.")
public func degrees(degrees: Double, minutes: Double, seconds: Double = 0) -> Double {
    return degrees + minutes / 60 + seconds / 3600
}

@available(*, deprecated, message: "use `DegreeAngle(radianAngle:)`.")
public func degrees(radians: Double) -> Double {
    return radians / Double.pi * 180
}

@available(*, deprecated, message: "use `HourAngle(hour:minute:second:)`.")
public func hourFrac(hours: Double, minutes: Double, seconds: Double = 0) -> Double {
    return hours + minutes / 60 + seconds / 3600
}
