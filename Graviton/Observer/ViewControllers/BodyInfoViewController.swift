//
//  BodyInfoViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 7/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import StarryNight
import Orbits
import SpaceTime
import MathUtil
import XLPagerTabStrip

class BodyInfoViewController: UITableViewController, IndicatorInfoProvider {

    var target: BodyInfoTarget!
    var ephemerisId: SubscriptionUUID!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "infoCell")
    }

    // MARK: - Info provider

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        switch target! {
        case .star:
            return "Star Info"
        case .nearbyBody:
            return "Body Info"
        }
    }

    private func rowForPositionSection(_ row: Int) -> Int {
        if case .nearbyBody = target! {
            return row
        }
        if row < 2 {
            return row
        }
        return row - (LocationAndTimeManager.default.observerInfo == nil ? 2 : 0)
    }

    private func relativeCoordinate(forNearbyBody body: Body) -> EquatorialCoordinate {
        let ephemeris = EphemerisManager.default.content(for: ephemerisId)!
        let earth = ephemeris[.majorBody(.earth)]!
        return EquatorialCoordinate(cartesian: (body.heliocentricPosition! - earth.heliocentricPosition!).oblique(by: earth.obliquity))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return target.numberOfSections
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch target! {
        case .star:
            return ["Position", "Designations", "Physical Properties"][section]
        case .nearbyBody:
            return ["Position", "Physical Properties"][section]
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return target.numberOfRows(in: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "infoCell")
        configureSharedPosition(forCell: cell, atIndexPath: indexPath)
        switch target! {
        case let .star(star):
            switch (indexPath.section, indexPath.row) {
            case (1, _):
                cell.textLabel?.text = star.identity.contentAtRow(indexPath.row).0
                cell.detailTextLabel?.text = star.identity.contentAtRow(indexPath.row).1
            case (0, rowForPositionSection(4)):
                cell.textLabel?.text = "Constellation"
                cell.detailTextLabel?.text = star.identity.constellation.name
            case (0, rowForPositionSection(5)):
                cell.textLabel?.text = "Distance from Sun"
                let formatter = Formatters.scientificNotationFormatter
                var distanceStr = formatter.string(from: star.physicalInfo.distance as NSNumber)!
                if star.physicalInfo.distance >= 10e6 {
                    distanceStr = "> \(distanceStr) pc"
                } else {
                    distanceStr = "\(distanceStr) pc"
                }
                cell.detailTextLabel?.text = distanceStr
            case (2, 0):
                cell.textLabel?.text = "Visual Magnitude"
                cell.detailTextLabel?.text = stringify(star.physicalInfo.apparentMagnitude)
            case (2, 1):
                cell.textLabel?.text = "Absolute Magnitude"
                cell.detailTextLabel?.text = stringify(star.physicalInfo.absoluteMagnitude)
            case (2, 2):
                cell.textLabel?.text = "Spectral Type"
                cell.detailTextLabel?.text = stringify(star.physicalInfo.spectralType)
            case (2, 3):
                cell.textLabel?.text = "Luminosity (x Sun)"
                cell.detailTextLabel?.text = Formatters.scientificNotationFormatter.string(from: star.physicalInfo.luminosity as NSNumber)
            default:
                break
            }
        case let .nearbyBody(nb):
            let celestialBody = nb as! CelestialBody
            let coord = relativeCoordinate(forNearbyBody: nb)
            switch (indexPath.section, indexPath.row) {
            case (0, rowForPositionSection(4)):
                cell.textLabel?.text = "Constellation"
                cell.detailTextLabel?.text = coord.constellation.name
            case (1, 0):
                cell.textLabel?.text = "Mass (kg)"
                cell.detailTextLabel?.text = Formatters.scientificNotationFormatter.string(from: celestialBody.mass as NSNumber)
            case (1, 1):
                cell.textLabel?.text = "Radius (km)"
                cell.detailTextLabel?.text = Formatters.scientificNotationFormatter.string(from: celestialBody.radius / 1000 as NSNumber)
            case (1, 2):
                cell.textLabel?.text = "Rotation Period (h)"
                cell.detailTextLabel?.text = Formatters.scientificNotationFormatter.string(from: celestialBody.rotationPeriod / 3600 as NSNumber)
            default:
                break
            }
        }
        return cell
    }

    private func configureSharedPosition(forCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        let coord: EquatorialCoordinate
        switch target! {
        case let .star(star):
            coord = EquatorialCoordinate(cartesian: star.physicalInfo.coordinate)
        case let .nearbyBody(nb):
            coord = relativeCoordinate(forNearbyBody: nb)
        }
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "Right Ascension"
            let hms = HourMinuteSecond(value: degrees(radians: coord.rightAscension))
            hms.decimalNumberFormatter = Formatters.integerFormatter
            cell.detailTextLabel?.text = String(describing: hms)
        case (0, 1):
            cell.textLabel?.text = "Declination"
            let dms = DegreeMinuteSecond(value: degrees(radians: coord.declination))
            dms.decimalNumberFormatter = Formatters.integerFormatter
            cell.detailTextLabel?.text = String(describing: dms)
        case (0, rowForPositionSection(2)):
            cell.textLabel?.text = "Azimuth"
            let hori = HorizontalCoordinate(equatorialCoordinate: coord, observerInfo: LocationAndTimeManager.default.observerInfo!)
            let dms = DegreeMinuteSecond(value: degrees(radians: hori.azimuth))
            dms.decimalNumberFormatter = Formatters.integerFormatter
            cell.detailTextLabel?.text = String(describing: dms)
        case (0, rowForPositionSection(3)):
            cell.textLabel?.text = "Altitude"
            let hori = HorizontalCoordinate(equatorialCoordinate: coord, observerInfo: LocationAndTimeManager.default.observerInfo!)
            let dms = DegreeMinuteSecond(value: degrees(radians: hori.altitude))
            dms.decimalNumberFormatter = Formatters.integerFormatter
            cell.detailTextLabel?.text = String(describing: dms)
        default:
            break
        }
    }
}

extension BodyInfoTarget {
    var numberOfSections: Int {
        switch self {
        case .star:
            return 3
        case .nearbyBody:
            return 2
        }
    }

    func numberOfRows(in section: Int) -> Int {
        switch self {
        case let .star(star):
            switch section {
            case 1: // Identity
                var identityCount = 0
                if star.identity.properName != nil { identityCount += 1 }
                if star.identity.hipId != nil { identityCount += 1 }
                if star.identity.hrId != nil { identityCount += 1 }
                if star.identity.gl != nil { identityCount += 1 }
                if star.identity.rawBfDesignation != nil { identityCount += 1 }
                if star.identity.hdId != nil { identityCount += 1 }
                return identityCount
            case 0: // Position
                return 6
            case 2: // Physical Properties
                return 4
            default:
                return 0
            }
        case .nearbyBody:
            switch section {
            case 0: // Positions
                return 5
            case 1: // Physical Properties
                return 3
            default:
                return 0
            }
        }
    }
}

extension Star.Identity {
    func contentAtRow(_ row: Int) -> (String, String) {
        return zip(["Proper Name", "Bayer-Flamsteed", "Gliese catalog", "Harvard Revised", "Henry Draper", "Hipparcos catalog"], [properName, bayerFlamsteedDesignation, gl, stringify(hrId), stringify(hdId), stringify(hipId)])
            .filter { $1 != nil }
            .map { ($0, $1!) }[row]
    }
}

fileprivate func stringify(_ str: CustomStringConvertible?) -> String? {
    if str == nil { return nil }
    return String(describing: str!)
}
