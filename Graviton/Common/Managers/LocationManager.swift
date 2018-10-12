//
//  LocationManager.swift
//  Graviton
//
//  Created by Sihao Lu on 5/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import UIKit

typealias LocationRequestResultBlock = () -> Void

class LocationManager: LiteSubscriptionManager<CLLocation>, CLLocationManagerDelegate {
    static let `default` = LocationManager()

    var locationOverride: CLLocation? {
        didSet {
            if let loc = content {
                updateAllSubscribers(loc)
                LocationManager.decodeTimeZone(location: loc) { [weak self] timeZone in
                    self?.timeZone = timeZone
                }
            } else {
                timeZone = TimeZone.current
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

    public static func decodeTimeZone(location: CLLocation, completion: @escaping (TimeZone) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            let timeZone: TimeZone
            if let pm = placemarks?.first {
                timeZone = pm.timeZone ?? TimeZone.current
            } else {
                logger.error("Cannot fetch time zone for \(location). \(String(describing: error))")
                timeZone = TimeZone.current
            }
            completion(timeZone)
        }
    }

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

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        guard locationOverride == nil else {
            logger.warning("location updated to \(location) but has been overridden with \(locationOverride!)")
            return
        }
        logger.info("update location to \(location)")
        updateAllSubscribers(location)
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        logger.error(error)
    }
}
