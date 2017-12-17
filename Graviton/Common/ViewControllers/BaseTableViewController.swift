//
//  BaseTableViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/10/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {
    private static let resizingMask: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight]

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.separatorColor = Constants.Menu.separatorColor
        tableView.backgroundColor = UIColor.clear

        navigationController?.navigationBar.barStyle = .black
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        fatalError()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError()
    }
}
