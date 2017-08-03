//
//  ObserverMenuController.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import QuartzCore
import KMNavigationBarTransition
import SpaceTime

fileprivate let buttonCellId = "buttonCell"
fileprivate let detailCellId = "detailCell"
fileprivate let toggleCellId = "toggleCell"
fileprivate let locationCellId = "locationCell"
fileprivate let headerFooterId = "headerFooter"

class ObserverMenuController: MenuController {
    class HeaderView: UIView {
        lazy var textLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.boldSystemFont(ofSize: 16)
            return label
        }()

        init() {
            super.init(frame: CGRect.zero)
            setupViewElements()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViewElements() {
            isOpaque = false
            addSubview(textLabel)
            addConstraints([
                textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                textLabel.topAnchor.constraint(equalTo: topAnchor),
                textLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
    }

    var menu: Menu!

    private var indexPathsToDisable = Set<IndexPath>()

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true

        tableView.register(MenuCell.self, forCellReuseIdentifier: detailCellId)
        tableView.register(MenuToggleCell.self, forCellReuseIdentifier: toggleCellId)
        tableView.register(MenuButtonCell.self, forCellReuseIdentifier: buttonCellId)
        tableView.register(MenuLocationCell.self, forCellReuseIdentifier: locationCellId)

        let behaviors = menu.registerAllConditionalDisabling()
        behaviors.forEach { (behavior) in
            let indexPath = self.menu.indexPath(for: behavior.setting)!
            if behavior.condition == Settings.default[behavior.dependent] {
                self.indexPathsToDisable.insert(indexPath)
            } else {
                self.indexPathsToDisable.remove(indexPath)
            }
            Settings.default.subscribe(setting: behavior.dependent, object: self, valueChanged: { (_, newValue) in
                if behavior.condition == newValue {
                    self.indexPathsToDisable.insert(indexPath)
                } else {
                    self.indexPathsToDisable.remove(indexPath)
                }
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            })
            Settings.default.subscribe(setting: behavior.setting, object: self, valueChanged: { (_, newValue) in
                if let cell = self.tableView.cellForRow(at: indexPath) as? MenuToggleCell, cell.toggle.isEnabled == newValue {
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            })
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Settings.default.unsubscribe(object: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Menu delivered actions
    func jumpToCelestialPoint(_ userInfo: Any?) {
        guard let dict = userInfo as? [String: Double] else { fatalError() }
        let coordinate = EquatorialCoordinate(dictionary: dict)
        navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "jumpToCelestialPoint"), object: self, userInfo: ["content": coordinate])
    }

    func jumpToDirection(_ userInfo: Any?) {
        guard let dict = userInfo as? [String: Double] else { fatalError() }
        let coordinate = HorizontalCoordinate(dictionary: dict)
        navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "jumpToDirection"), object: self, userInfo: ["content": coordinate])
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return menu.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = menu[indexPath]
        cell.backgroundColor = UIColor.clear
        cell.imageView?.image = item.image
        switch item.type {
        case .detail, .multipleSelect:
            cell.textLabel?.text = item.text
            cell.accessoryType = .disclosureIndicator
        case .toggle:
            cell.textLabel?.text = item.text
            let toggleCell = cell as! MenuToggleCell
            let shouldDisable = indexPathsToDisable.contains(indexPath)
            toggleCell.textLabel?.isEnabled = !shouldDisable
            toggleCell.toggle.isEnabled = !shouldDisable
        case .button:
            cell.textLabel?.text = item.text
        case .external:
            break
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = menu[indexPath]
        let cell: UITableViewCell
        switch item.type {
        case .toggle(let binding, _):
            cell = tableView.dequeueReusableCell(withIdentifier: toggleCellId, for: indexPath)
            cell.selectionStyle = .none
            let toggleCell = cell as! MenuToggleCell
            toggleCell.binding = binding
        case .detail, .multipleSelect:
            cell = tableView.dequeueReusableCell(withIdentifier: detailCellId, for: indexPath)
        case let .button(key, info):
            cell = tableView.dequeueReusableCell(withIdentifier: buttonCellId, for: indexPath)
            let buttonCell = cell as! MenuButtonCell
            buttonCell.button.setTitle(item.text, for: .normal)
            buttonCell.key = key
            buttonCell.userInfo = info
            buttonCell.handler = { [weak self] (key, userInfo) in
                self?.performSelector(onMainThread: Selector.init(key + ":"), with: info, waitUntilDone: false)
            }
        case let .external(identifier):
            if identifier == "location" {
                cell = MenuLocationCell(style: .subtitle, reuseIdentifier: locationCellId)
                let locationCell = cell as! MenuLocationCell
                locationCell.textLabel?.text = CityManager.default.locationDescription
                locationCell.detailTextLabel?.text = CityManager.default.locationDetailDescription
                locationCell.accessoryType = .disclosureIndicator
            } else {
                fatalError("Unrecognized external menu identifier")
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = menu[indexPath]
        if case let .detail(submenu) = item.type {
            // transition to submenu
            let subMenuController = ObserverMenuController(style: .plain)
            subMenuController.menu = submenu
            navigationController?.pushViewController(subMenuController, animated: true)
        } else if case let .multipleSelect(mulSel) = item.type {
            // transition to submenu
            let subMenuController = ObserverMenuMultipleSelectController(style: .plain)
            subMenuController.multipleSelect = mulSel
            navigationController?.pushViewController(subMenuController, animated: true)
        } else if case let .external(identifier) = item.type, identifier == "location" {
            let subMenuController = ObserverLocationMenuController(style: .plain)
            navigationController?.pushViewController(subMenuController, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if menu.sections[section].name != nil {
            return 24
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = HeaderView()
        header.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3031194982)
        header.textLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        header.textLabel.text = menu.sections[section].name
        return header
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = menu[indexPath]
        switch item.type {
        case let .external(identifier) where identifier == "location":
            return 60
        default:
            return 44
        }
    }

}
