//
//  Timekeeper.swift
//  Graviton
//
//  Created by Sihao Lu on 6/17/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SpaceTime
import UIKit

class Timekeeper: LiteSubscriptionManager<JulianDay> {
    static var now: Date {
        return Date()
    }

    static var julianDayNow: JulianDay {
        return JulianDay.now
    }

    static let `default`: Timekeeper = Timekeeper()

    override var content: JulianDay? {
        return warpedJulianDay
    }

    private var warpedJulianDay: JulianDay?

    var warpedDate: Date? {
        return warpedJulianDay?.date
    }

    /// Whether is in time warp mode
    var isWarpActive: Bool = false

    var isWarping: Bool {
        return warpedJulianDay != nil && !(recentWarpSpeed ~= 0)
    }

    var differenceToRealtime: TimeInterval {
        return JulianDay.now - (warpedJulianDay ?? JulianDay.now)
    }

    var recentWarpSpeed: Double = 0

    /// Warp the time.
    ///
    /// Example: when shift is -10, the result date is warped back 10 seconds.
    /// - Parameter shift: The shift in seconds.
    func warp(by shift: Double?) {
        guard let shift = shift else {
            recentWarpSpeed = 0
            updateAllSubscribers(warpedJulianDay ?? JulianDay.now)
            return
        }
        recentWarpSpeed = shift
        if let warpedJd = warpedJulianDay {
            warpedJulianDay = warpedJd + shift
        } else {
            warpedJulianDay = JulianDay.now + shift
        }
        updateAllSubscribers(warpedJulianDay!)
    }

    func reset() {
        warpedJulianDay = nil
        updateAllSubscribers(JulianDay.now)
        recentWarpSpeed = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "warpReset"), object: self)
    }
}
