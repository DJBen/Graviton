//
//  RiseTransitSetInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 5/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import RealmSwift
import SpaceTime

public class RiseTransitSetInfo: ObserverInfo {
    dynamic var azimuth: Double = 0
    dynamic var elevation: Double = 0

    convenience init(naifId: Int, jd: Double, daylightFlag: String, rtsFlag: String, azimuth: Double, elevation: Double) {
        self.init()
        self.naifId = naifId
        self.jd = jd
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
