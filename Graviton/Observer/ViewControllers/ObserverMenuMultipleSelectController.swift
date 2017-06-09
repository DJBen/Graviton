//
//  ObserverMenuMultipleSelectController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/10/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

fileprivate let checkableCellId = "checkableCell"
class ObserverMenuMultipleSelectController: MenuController {

    var multipleSelect: MultipleSelect!

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        tableView.register(MenuCell.self, forCellReuseIdentifier: checkableCellId)
        Settings.default.subscribe(setting: .groundTexture, object: self) { (oldValue, newValue) in
            self.tableView.reloadRows(at: [oldValue, newValue].map { self.multipleSelect.indexPath(for: $0)! }, with: .automatic)
        }
    }

    deinit {
        Settings.default.unsubscribe(object: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return multipleSelect.options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: checkableCellId, for: indexPath)
        cell.backgroundColor = UIColor.clear
        let selection = multipleSelect.options[indexPath.row]
        cell.textLabel?.text = selection.1
        if multipleSelect.selectedIndex == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selection = multipleSelect.options[indexPath.row]
        Settings.default[multipleSelect.setting] = selection.0
    }
}
