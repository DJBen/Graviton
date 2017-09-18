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
        tableView.register(MenuCell.self, forCellReuseIdentifier: checkableCellId)
        Settings.default.subscribe(settings: [.groundTexture, .antialiasingMode], object: self) { (_, _) in
            self.tableView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let menuCell = cell as? MenuCell {
            menuCell.textLabelLeftInset = 21
        }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selection = multipleSelect.options[indexPath.row]
        Settings.default[multipleSelect.setting] = selection.0
    }
}
