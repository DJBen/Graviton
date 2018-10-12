//
//  ObserverRTSViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 7/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil
import Orbits
import UIKit
import XLPagerTabStrip

class ObserverRTSViewController: BaseTableViewController {
    private var rtsSubscriptionIdentifier: SubscriptionUUID!
    lazy var observerInfo = ObserverInfo()

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(handleRefresh(target:)), for: .valueChanged)
            let attributes = [NSAttributedStringKey.foregroundColor: UIColor.lightText]
            refreshControl.attributedTitle = NSAttributedString(string: "Pull to reload RTS info", attributes: attributes)
            return refreshControl
        }()
        clearsSelectionOnViewWillAppear = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "informationCell")
        rtsSubscriptionIdentifier = RiseTransitSetManager.default.subscribe(didLoad: updateRiseTransitSetInfo)
        refreshControl?.addTarget(self, action: #selector(handleRefresh(target:)), for: .valueChanged)
        refreshControl?.beginRefreshing()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshControl?.beginRefreshing()
        handleRefresh(target: refreshControl!)
    }

    deinit {
        RiseTransitSetManager.default.unsubscribe(rtsSubscriptionIdentifier)
    }

    @objc func handleRefresh(target _: UIRefreshControl) {
        RiseTransitSetManager.default.fetch()
    }

    func updateRiseTransitSetInfo(_ rtsInfo: [Naif: RiseTransitSetElevation]) {
        observerInfo.updateRtsInfo(rtsInfo)
        refreshControl?.endRefreshing()
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return ObserverInfo.sections.count
    }

    override func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = HeaderView()
        header.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3031194982)
        header.textLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        header.textLabel.text = ObserverInfo.section(atIndex: section)
        return header
    }

    override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 24
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return observerInfo.riseTransitSetElevationInfo(forSection: section)?.tableRows.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rows = observerInfo.riseTransitSetElevationInfo(forSection: indexPath.section)!.tableRows
        let cell = tableView.dequeueReusableCell(withIdentifier: "informationCell", for: indexPath)
        cell.textLabel?.text = rows[indexPath.row]
        return cell
    }

    override func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt _: IndexPath) {
        cell.backgroundColor = UIColor.black
        cell.textLabel?.textColor = UIColor.white
    }
}

// MARK: - Info provider

extension ObserverRTSViewController: IndicatorInfoProvider {
    func indicatorInfo(for _: PagerTabStripViewController) -> IndicatorInfo {
        return "Rise-Transit-Set"
    }
}
