//
//  InformationViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 7/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import Orbits
import MathUtil

class InformationViewController: UITableViewController {

    private var rtsSubscriptionIdentifier: SubscriptionUUID!
    lazy var observerInfo = ObserverInfo()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        rtsSubscriptionIdentifier = RiseTransitSetManager.default.subscribe(didLoad: updateRiseTransitSetInfo)
    }

    deinit {
        RiseTransitSetManager.default.unsubscribe(rtsSubscriptionIdentifier)
    }

    func updateRiseTransitSetInfo(_ rtsInfo: [Naif: RiseTransitSetElevation]) {
        observerInfo.updateRtsInfo(rtsInfo)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return ObserverInfo.sections.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ObserverInfo.section(atIndex: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return observerInfo.riseTransitSetElevationInfo(forSection: section)?.tableRows.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rows = observerInfo.riseTransitSetElevationInfo(forSection: indexPath.section)!.tableRows
        let cell = tableView.dequeueReusableCell(withIdentifier: "informationCell", for: indexPath)
        cell.textLabel?.text = rows[indexPath.row]
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
