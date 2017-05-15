//
//  RiseTransitSetInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 5/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import RealmSwift
import SpaceTime
import CoreLocation

public class RiseTransitSetInfo: ObserverInfo {
    public dynamic var azimuth: Double = 0
    public dynamic var elevation: Double = 0

    convenience init(naifId: Int, jd: Double, location: CLLocation, daylightFlag: String, rtsFlag: String, azimuth: Double, elevation: Double) {
        self.init()
        self.naifId = naifId
        self.jd = jd
        self.location = location
        self.daylightFlag = daylightFlag
        self.rtsFlag = rtsFlag
        self.azimuth = azimuth
        self.elevation = elevation
    }
}

extension Collection where Iterator.Element == RiseTransitSetInfo {
    func save() {
        let realm = try! Realm()
        try! realm.write {
            realm.add(self)
        }
    }
}
