//
//  StarSearchViewController.swift
//  StarryNight
//
//  Created by Sihao Lu on 9/18/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import StarryNight
import Orbits

protocol ObserveTargetSearchViewControllerDelegate: NSObjectProtocol {
    func observeTargetViewController(_ viewController: ObserveTargetSearchViewController, didSelectTarget target: ObserveTarget)
}

class ObserveTargetSearchViewController: UITableViewController {

    private enum SearchScope {
        case all
    }

    weak var delegate: ObserveTargetSearchViewControllerDelegate?

    var ephemerisSubscriptionId: SubscriptionUUID!

    lazy var searchController = UISearchController(searchResultsController: nil)

    private var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    private var isFiltering: Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty || searchBarScopeIsFiltering)
    }

    private var nearbyBodies: [ObserveTarget] {
        if let ephemeris = EphemerisManager.default.content(for: ephemerisSubscriptionId) {
            return [.sun, .moon(.luna), .majorBody(.venus), .majorBody(.mercury), .majorBody(.mars), .majorBody(.jupiter), .majorBody(.saturn)].map { ObserveTarget.nearbyBody(ephemeris[$0]!) }
        } else {
            return []
        }
    }

    private lazy var allTargets: [ObserveTarget] = {
        let allStars = Star.magitudeLessThan(Constants.Observer.maximumDisplayMagnitude)
        return allStars.map { ObserveTarget.star($0) } + nearbyBodies
    }()

    private var filteredTargets: [ObserveTarget] = []
    private var currentContent: [ObserveTarget] {
        return isFiltering ? filteredTargets : allTargets
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
        title = "Celestial Objects"
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
        let content = currentContent[indexPath.row]
        switch content {
        case .star(let star):
            cell.textLabel?.text = String(describing: star.identity)
        case .nearbyBody(let body):
            cell.textLabel?.text = body.name
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.observeTargetViewController(self, didSelectTarget: currentContent[indexPath.row])
    }

    private func filterTargets(forSearchText searchText: String, scope: SearchScope = .all) {
        let filteredStars = Star.matches(name: searchText).map { ObserveTarget.star($0) }
        let filteredNearbyTargets = nearbyBodies.filter { (target) -> Bool in
            if case let .nearbyBody(body) = target {
                return body.name.lowercased().contains(searchText.lowercased())
            }
            return false
        }
        filteredTargets = filteredStars + filteredNearbyTargets
        tableView.reloadData()
    }
}

extension ObserveTargetSearchViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    }
}

extension ObserveTargetSearchViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterTargets(forSearchText: searchController.searchBar.text!, scope: .all)
    }
}
