//
//  ObserverLocationMenuController.swift
//  Graviton
//
//  Created by Sihao Lu on 8/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

fileprivate let cityCellId = "cityCell"

class ObserverLocationMenuController: MenuController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {

    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController:  nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.textField?.textColor = UIColor.white
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        return searchController
    }()

    let cities: [City] = CityManager.fetchCities()
    var citySubset: [City]?
    var dataSource: [City] {
        return citySubset ?? cities
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_icon_target"), style: .plain, target: self, action: #selector(requestUsingLocationService))
        self.navigationItem.searchController = searchController
    }

    @objc func requestUsingLocationService() {
        CityManager.default.currentlyLocatedCity = nil
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        (cell as! MenuLocationCell).textLabelLeftInset = 21
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let city = dataSource[indexPath.row]
        let cell = MenuLocationCell(style: .subtitle, reuseIdentifier: cityCellId)
        cell.textLabel?.text = city.name
        let detail: String
        if city.iso3 == "USA" {
            detail = "\(city.country), \(city.provinceAbbreviation!)"
        } else {
            detail = city.country
        }
        if let currentCity = CityManager.default.currentlyLocatedCity, city == currentCity {
            cell.accessoryType = .checkmark
            cell.setSelected(true, animated: false)
        } else {
            cell.accessoryType = .none
            cell.setSelected(false, animated: false)
        }
        cell.detailTextLabel?.text = detail
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = dataSource[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)!
        cell.accessoryType = .checkmark
        CityManager.default.currentlyLocatedCity = city
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    // MARK: - Search controller delegate

    func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text {
            citySubset = CityManager.fetchCities(withNameContaining: searchString)
        }
        tableView.reloadData()
    }

}
