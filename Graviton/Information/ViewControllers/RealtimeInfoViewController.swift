//
//  RealtimeInfoViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 11/24/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import MathUtil
import SpaceTime
import XLPagerTabStrip

class RealtimeInfoViewController: UITableViewController {

    var locationSubscriptionId: SubscriptionUUID!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        let displayLink = CADisplayLink(target: self, selector: #selector(screenUpdate))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
        locationSubscriptionId = LocationManager.default.subscribe { (_) in
            self.tableView.reloadData()
        }
    }

    deinit {
        LocationManager.default.unsubscribe(locationSubscriptionId)
    }

    @objc func screenUpdate() {
        let date = Date()
        let julianDate = JulianDate(date: date)
        let jdValue = julianDate.value as NSNumber

        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            cell.detailTextLabel?.text = Formatters.fullUtcDateFormatter.string(from: date)
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) {
            cell.detailTextLabel?.text = Formatters.julianDateFormatter.string(from: jdValue)
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) {
            let sidTime = SiderealTime.init(julianDate: julianDate)
            cell.detailTextLabel?.text = String(describing: sidTime)
        }
        if let location = LocationManager.default.content {
            let locTime = LocationAndTime(location: location, timestamp: julianDate)
            let sidTime = SiderealTime.init(locationAndTime: locTime)

            if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: 0)) {
                cell.detailTextLabel?.text = String(describing: sidTime)
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 4, section: 0)) {
                cell.detailTextLabel?.text = String(describing: sidTime.offsetFromGreenwichMeanSiderealTime)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationManager.default.content == nil ? 3 : 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "realtimeInfoCell")
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Current UTC Date"
        case 1:
            cell.textLabel?.text = "Current Julian Date"
        case 2:
            cell.textLabel?.text = "Greenwich Sidereal Time"
        case 3:
            cell.textLabel?.text = "Local Sidereal Time"
        case 4:
            cell.textLabel?.text = "LST-GST Offset"
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        let actionController = UIAlertController(title: cell.textLabel?.text, message: cell.detailTextLabel?.text, preferredStyle: .actionSheet)
        actionController.addAction(UIAlertAction(title: "Copy to clipboard", style: .default, handler: { (_) in
            UIPasteboard.general.string = cell.detailTextLabel?.text
            self.tableView.deselectRow(at: indexPath, animated: true)
        }))
        actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.tableView.deselectRow(at: indexPath, animated: true)
        }))
        present(actionController, animated: true, completion: nil)
    }
}

// MARK: - Info provider

extension RealtimeInfoViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return "Astronomy Info"
    }
}
