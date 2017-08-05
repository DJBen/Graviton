//
//  CityManager.swift
//  Graviton
//
//  Created by Sihao Lu on 8/2/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SQLite
import CoreLocation

fileprivate let conn = try! Connection(Bundle.main.path(forResource: "cities", ofType: "sqlite3")!)
fileprivate let cities = Table("cities")

fileprivate let citiesLat = Expression<Double>("lat")
fileprivate let citiesLng = Expression<Double>("lng")
fileprivate let citiesName = Expression<String>("city")
fileprivate let citiesPop = Expression<Double>("pop")
fileprivate let citiesCountry = Expression<String>("country")
fileprivate let citiesProvince = Expression<String?>("province")
fileprivate let citiesIso2 = Expression<String>("iso2")
fileprivate let citiesIso3 = Expression<String>("iso3")

struct City: Equatable {
    let coordinate: CLLocationCoordinate2D
    let name: String
    let country: String
    let province: String?
    let iso2: String
    let iso3: String

    static func ==(lhs: City, rhs: City) -> Bool {
        return lhs.name == rhs.name && lhs.province == rhs.province && lhs.country == rhs.country
    }
}

class CityManager {
    static let `default` = CityManager()

    /// User chosen currently located city. Can be `nil` to use GPS data.
    var currentlyLocatedCity: City? {
        didSet {
            if let city = currentlyLocatedCity {
                let location = CLLocation.init(latitude: city.coordinate.latitude, longitude: city.coordinate.longitude)
                LocationManager.default.locationOverride = location

            } else {
                LocationManager.default.locationOverride = nil
            }
        }
    }

    var locationDescription: String {
        if let city = currentlyLocatedCity {
            return city.name
        }
        return "Current Location"
    }

    var locationDetailDescription: String {
        if let city = currentlyLocatedCity {
            return city.country
        }
        if let coordinate = LocationManager.default.content?.coordinate {
            let coordFormatter = CoordinateFormatter()
            return coordFormatter.string(for: coordinate)!
        }
        return "Unknown"
    }

    static func fetchCities(minimumPopulation: Double = 100_000) -> [City] {
        let query = cities.select(citiesLat, citiesLng, citiesName, citiesCountry, citiesProvince, citiesIso2, citiesIso3).filter(citiesPop >= minimumPopulation).order(citiesName)
        return try! conn.prepare(query).map { (row) -> City in
            return City(coordinate: CLLocationCoordinate2D.init(latitude: row.get(citiesLat), longitude: row.get(citiesLng)), name: row.get(citiesName), country: row.get(citiesCountry), province: row.get(citiesProvince), iso2: row.get(citiesIso2), iso3: row.get(citiesIso3))
        }
    }
}
