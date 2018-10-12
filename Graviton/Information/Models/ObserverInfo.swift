//
//  ObserverInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 7/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Orbits
import UIKit

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct ObserverInfo {
    static let sections: [Naif] = [.sun, .moon(.luna), .majorBody(.venus), .majorBody(.mercury), .majorBody(.mars), .majorBody(.jupiter), .majorBody(.saturn)]

    static func section(atIndex idx: Int) -> String {
        return String(describing: sections[idx])
    }

    private var obsSubscriptionIdentifier: SubscriptionUUID!
    private var rtsSubscriptionIdentifier: SubscriptionUUID!

    private var rtsInfo: [Naif: RiseTransitSetElevation]?

    func riseTransitSetElevationInfo(forSection section: Int) -> RiseTransitSetElevation? {
        return rtsInfo?[ObserverInfo.sections[section]]
    }

    mutating func updateRtsInfo(_ rtsInfo: [Naif: RiseTransitSetElevation]) {
        for (naif, rts) in rtsInfo {
            if let originalRts = rtsInfo[naif], rts == originalRts {
                continue
            }
            guard ObserverInfo.sections.index(of: naif) != nil else {
                continue
            }
        }
        self.rtsInfo = rtsInfo
    }
}

extension RiseTransitSetElevation {
    var tableRows: [String] {
        return zip(["Rises at ", "Transits at ", "Sets at "], [riseAt, transitAt, setAt]).compactMap { (str, julianDay) -> String? in
            if julianDay == nil { return nil }
            dateFormatter.timeZone = LocationManager.default.timeZone
            return str + dateFormatter.string(from: julianDay!.date)
        }
    }
}
