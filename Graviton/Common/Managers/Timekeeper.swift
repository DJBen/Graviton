//
//  Timekeeper.swift
//  Graviton
//
//  Created by Sihao Lu on 6/17/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpaceTime

class Timekeeper: LiteSubscriptionManager<JulianDate> {
    static var now: Date {
        return Date()
    }

    static var julianDateNow: JulianDate {
        return JulianDate.now
    }

    static let `default`: Timekeeper = Timekeeper()

    override var content: JulianDate? {
        return warpedJulianDate
    }

    private var warpedJulianDate: JulianDate?

    var warpedDate: Date? {
        return warpedJulianDate?.date
    }

    var isWarping: Bool {
        return warpedJulianDate != nil && !(recentWarpSpeed ~= 0)
    }

    var differenceToRealtime: TimeInterval {
        return JulianDate.now - (warpedJulianDate ?? JulianDate.now)
    }

    var recentWarpSpeed: Double = 0

    /// Warp the time.
    ///
    /// Example: when shift is -10, the result date is warped back 10 seconds.
    /// - Parameter shift: The shift in seconds.
    func warp(by shift: Double?) {
        guard let shift = shift else {
            recentWarpSpeed = 0
            updateAllSubscribers(warpedJulianDate ?? JulianDate.now)
            return
        }
        recentWarpSpeed = shift
        if let warpedJd = warpedJulianDate {
            warpedJulianDate = warpedJd + shift
        } else {
            warpedJulianDate = JulianDate.now + shift
        }
        updateAllSubscribers(warpedJulianDate!)
    }

    func reset() {
        warpedJulianDate = nil
        updateAllSubscribers(JulianDate.now)
        recentWarpSpeed = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "warpReset"), object: self)
    }
}
