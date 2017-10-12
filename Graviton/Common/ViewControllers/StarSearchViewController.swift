//
//  StarSearchViewController.swift
//  StarryNight
//
//  Created by Sihao Lu on 9/18/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import StarryNight

protocol StarSearchViewControllerDelegate: NSObjectProtocol {
    func starSearchViewController(_ viewController: StarSearchViewController, didSelectStar star: Star)
}

class StarSearchViewController: UITableViewController {

    private enum SearchScope {
        case all
    }

    weak var delegate: StarSearchViewControllerDelegate?

    lazy var searchController = UISearchController(searchResultsController: nil)

    private var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    private var isFiltering: Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty || searchBarScopeIsFiltering)
    }

    private lazy var allStars: [Star] = Star.magitudeLessThan(Constants.Observer.maximumDisplayMagnitude)
    private var filteredStars: [Star] = []
    private var currentContent: [Star] {
        return isFiltering ? filteredStars : allStars
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBlurredBackground()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "starCell")
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        navigationController?.navigationBar.barStyle = .black
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        title = "Star Search"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(sender:)))
    }

    override var prefersStatusBarHidden: Bool {
        return Device.isiPhoneX == false
    }

    @objc func doneButtonTapped(sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentContent.count
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.white
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "starCell", for: indexPath)
        cell.textLabel?.text = String(describing: currentContent[indexPath.row].identity)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.starSearchViewController(self, didSelectStar: currentContent[indexPath.row])
    }

    private func filterStars(forSearchText searchText: String, scope: SearchScope = .all) {
        filteredStars = Star.matches(name: searchText)
        tableView.reloadData()
    }
}

extension StarSearchViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    }
}

extension StarSearchViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterStars(forSearchText: searchController.searchBar.text!, scope: .all)
    }
}
