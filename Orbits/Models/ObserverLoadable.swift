//
//  ObserverLoadable.swift
//  Graviton
//
//  Created by Ben Lu on 5/9/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SpaceTime

protocol ObserverLoadable {
    static func load(naifId: Int, optimalJulianDate julianDate: JulianDate, site: ObserverSite, timeZone: TimeZone) -> Self?
    var naif: Naif { get }
}
