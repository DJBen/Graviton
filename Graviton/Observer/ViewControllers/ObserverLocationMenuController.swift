//
//  ObserverLocationMenuController.swift
//  Graviton
//
//  Created by Sihao Lu on 8/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

fileprivate let cityCellId = "cityCell"

class ObserverLocationMenuController: MenuController {

    lazy var cities: [City] = CityManager.fetchCities()

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: use icon to replace bar button item
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Use GPS", style: .plain, target: self, action: #selector(requestUsingLocationService))
    }

    func requestUsingLocationService() {
        CityManager.default.currentlyLocatedCity = nil
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let city = cities[indexPath.row]
        let cell = MenuLocationCell(style: .subtitle, reuseIdentifier: cityCellId)
        cell.textLabel?.text = city.name
        cell.detailTextLabel?.text = city.country
        if let currentCity = CityManager.default.currentlyLocatedCity, city == currentCity {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = cities[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)!
        cell.accessoryType = .checkmark
        CityManager.default.currentlyLocatedCity = city
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
