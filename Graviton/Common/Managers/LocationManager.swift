//
//  LocationManager.swift
//  Graviton
//
//  Created by Sihao Lu on 5/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import CoreLocation

typealias LocationRequestResultBlock = () -> Void

class LocationManager: LiteSubscriptionManager<CLLocation>, CLLocationManagerDelegate {

    static let `default` = LocationManager()

    var locationOverride: CLLocation? {
        didSet {
            if let loc = content {
                updateAllSubscribers(loc)
            }
        }
    }

    var timeZone: TimeZone = TimeZone.current
    override var content: CLLocation? {
        return locationOverride ?? locationManager.location
    }

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000
        manager.pausesLocationUpdatesAutomatically = true
        return manager
    }()

    func startLocationService() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func stopLocationService() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        guard locationOverride == nil else {
            print("location updated to \(location) but has been overridden with \(locationOverride!)")
            return
        }
        print("update location to \(location)")
        updateAllSubscribers(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
