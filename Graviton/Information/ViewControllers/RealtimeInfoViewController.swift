//
//  RealtimeInfoViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 11/24/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil
import SpaceTime
import UIKit
import XLPagerTabStrip

class RealtimeInfoViewController: BaseTableViewController {
    var locationSubscriptionId: SubscriptionUUID!

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = false
        let displayLink = CADisplayLink(target: self, selector: #selector(screenUpdate))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
        locationSubscriptionId = LocationManager.default.subscribe { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    deinit {
        LocationManager.default.unsubscribe(locationSubscriptionId)
    }

    @objc func screenUpdate() {
        let date = Date()
        let julianDay = JulianDay(date: date)
        let jdValue = julianDay.value as NSNumber

        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            cell.detailTextLabel?.text = Formatters.fullUtcDateFormatter.string(from: date)
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) {
            cell.detailTextLabel?.text = Formatters.julianDayFormatter.string(from: jdValue)
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) {
            let sidTime = SiderealTime(julianDay: julianDay)
            cell.detailTextLabel?.text = String(describing: sidTime)
        }
        if let location = LocationManager.default.content {
            let locTime = ObserverLocationTime(location: location, timestamp: julianDay)
            let sidTime = SiderealTime(observerLocationTime: locTime)

            if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: 0)) {
                cell.detailTextLabel?.text = String(describing: sidTime)
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 4, section: 0)) {
                cell.detailTextLabel?.text = String(describing: sidTime.offsetFromGreenwichMeanSiderealTime)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return LocationManager.default.content == nil ? 3 : 5
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        actionController.addAction(UIAlertAction(title: "Copy to clipboard", style: .default, handler: { [weak self] _ in
            UIPasteboard.general.string = cell.detailTextLabel?.text
            self?.tableView.deselectRow(at: indexPath, animated: true)
        }))
        actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            self?.tableView.deselectRow(at: indexPath, animated: true)
        }))
        present(actionController, animated: true, completion: nil)
    }

    override func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt _: IndexPath) {
        cell.backgroundColor = UIColor.black
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.lightText
    }
}

// MARK: - Info provider

extension RealtimeInfoViewController: IndicatorInfoProvider {
    func indicatorInfo(for _: PagerTabStripViewController) -> IndicatorInfo {
        return "Astronomy Info"
    }
}
