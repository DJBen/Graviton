//
//  ObserverInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 1/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import Foundation

public struct ObserverInfo {
    public let location: CLLocationCoordinate2D
    public let time: Date
    
    public init(location: CLLocationCoordinate2D = CLLocationCoordinate2D(), time: Date = Date()) {
        self.location = location
        self.time = time
    }
    
    /// local sidereal time in radians
    public var localSiderealTimeAngle: Float {
        let hours = location.longitude / 15
        let siderealTime = time.greenwichMeanSiderealTime + hours
        return wrapAngle(Float((siderealTime / 12 * M_PI)))
    }
    
}


