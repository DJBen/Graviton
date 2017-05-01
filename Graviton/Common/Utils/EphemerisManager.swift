//
//  EphemerisManager.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import Orbits
import SpaceTime

@objc protocol EphemerisUpdateDelegate {
    /// Ephemeris is loaded with new orbital elements
    ///
    /// - Parameter ephemeris: The ephemeris
    @objc optional func ephemerisDidLoad(ephemeris: Ephemeris)
    
    /// Ephemeris is recalculated using the julian date provided
    ///
    /// - Parameter ephemeris: The ephemeris
    @objc optional func ephemerisDidUpdate(ephemeris: Ephemeris)
}

class EphemerisManager {
    private class Subscription {
        let delegate: EphemerisUpdateDelegate
        let mode: RefreshMode
        var ephemeris: Ephemeris?
        var lastUpdateJd: JulianDate?
        
        init(delegate: EphemerisUpdateDelegate, mode: RefreshMode, ephemeris: Ephemeris?) {
            self.delegate = delegate
            self.mode = mode
            self.ephemeris = ephemeris
        }
    }
    
    enum RefreshMode {
        case realtime
        case interval(TimeInterval)
    }

    private var subscriptions = [Subscription]()
    
    static let `default` = EphemerisManager()
    
    private var ephemeris: Ephemeris?
    
    func fetchEphemeris(mode: Horizons.FetchMode = .mixed) {
        Horizons.shared.fetchEphemeris(mode: mode, update: { (ephemeris) -> Void in
            self.ephemeris = ephemeris
            ephemeris.debugPrintReferenceJulianDateInfo()
            for sub in self.subscriptions {
                sub.ephemeris = ephemeris
                if let lastJd = sub.lastUpdateJd {
                    sub.ephemeris?.updateMotion(using: lastJd)
                }
                sub.lastUpdateJd = nil
                sub.delegate.ephemerisDidLoad?(ephemeris: ephemeris)
            }
        })
    }
    
    func subscribe(_ delegate: EphemerisUpdateDelegate, mode: RefreshMode = .realtime) {
        subscriptions.append(Subscription.init(delegate: delegate, mode: mode, ephemeris: self.ephemeris?.copy() as? Ephemeris))
        if let eph = ephemeris {
            delegate.ephemerisDidLoad?(ephemeris: eph)
        }
    }
    
    func unsubscribe(_ delegate: EphemerisUpdateDelegate) {
        subscriptions = subscriptions.filter { $0.delegate !== delegate }
    }
    
    func requestEphemeris(at requestedJd: JulianDate, forObject delegate: EphemerisUpdateDelegate) -> Void {
        var changed = false
        guard let sub = subscriptions.first(where: { $0.delegate === delegate }) else {
            fatalError("object not subscribed")
        }
        guard let eph = sub.ephemeris else { return }
        switch sub.mode {
        case .realtime:
            eph.updateMotion(using: requestedJd)
            sub.ephemeris = eph
            sub.lastUpdateJd = requestedJd
            changed = true
        case .interval(let interval):
            if requestedJd.value - (sub.lastUpdateJd?.value ?? 0.0) >= interval / 86400 {
                eph.updateMotion(using: requestedJd)
                sub.ephemeris = eph
                sub.lastUpdateJd = requestedJd
                changed = true
            }
        }
        if changed {
            print("update ephemeris for delegate \(delegate)")
            eph.debugPrintReferenceJulianDateInfo()
            sub.delegate.ephemerisDidUpdate?(ephemeris: eph)
        }
    }
}
