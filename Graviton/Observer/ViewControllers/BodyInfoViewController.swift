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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return BodyInfoTarget.numberOfSections
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Identity", "Position", "Physical Properties"][section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return target.numberOfRows(in: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "infoCell")
        switch target! {
        case let .star(star):
            switch (indexPath.section, indexPath.row) {
            case (0, _):
                cell.textLabel?.text = star.identity.contentAtRow(indexPath.row).0
                cell.detailTextLabel?.text = star.identity.contentAtRow(indexPath.row).1
            case (1, 0):
                cell.textLabel?.text = "Right Ascension"
                let coord = EquatorialCoordinate(cartesian: star.physicalInfo.coordinate)
                let hms = HourMinuteSecond(value: degrees(radians: coord.rightAscension))
                hms.decimalNumberFormatter = Formatters.twoDecimalPointFormatter
                cell.detailTextLabel?.text = String(describing: hms)
            case (1, 1):
                cell.textLabel?.text = "Declination"
                let coord = EquatorialCoordinate(cartesian: star.physicalInfo.coordinate)
                let dms = DegreeMinuteSecond(value: degrees(radians: coord.declination))
                dms.decimalNumberFormatter = Formatters.twoDecimalPointFormatter
                cell.detailTextLabel?.text = String(describing: dms)
            case (1, 2):
                cell.textLabel?.text = "Constellation"
                cell.detailTextLabel?.text = star.identity.constellation.name
            case (2, 0):
                cell.textLabel?.text = "Apparent Magnitude"
                cell.detailTextLabel?.text = stringify(star.physicalInfo.magnitude)
            case (2, 1):
                cell.textLabel?.text = "Spectral Type"
                cell.detailTextLabel?.text = stringify(star.physicalInfo.spectralType)
            default:
                break
            }
        case let .nearbyBody(nb):
            break
        }
        return cell
    }
}

extension BodyInfoTarget {
    static let numberOfSections = 3
    func numberOfRows(in section: Int) -> Int {
        switch self {
        case let .star(star):
            switch section {
            case 0: // Identity
                var identityCount = 0
                if star.identity.properName != nil { identityCount += 1 }
                if star.identity.hipId != nil { identityCount += 1 }
                if star.identity.hrId != nil { identityCount += 1 }
                if star.identity.gl != nil { identityCount += 1 }
                if star.identity.rawBfDesignation != nil { identityCount += 1 }
                if star.identity.hdId != nil { identityCount += 1 }
                return identityCount
            case 1: // Position
                return 3
            case 2: // Physical Properties
                return 2
            default:
                return 0
            }
        case .nearbyBody:
            return 0
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
