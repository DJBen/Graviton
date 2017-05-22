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

fileprivate let detailCellId = "detailCell"
fileprivate let toggleCellId = "toggleCell"
fileprivate let headerFooter = "headerFooter"

class ObserverMenuController: UITableViewController, MenuWithBackground, MenuBackgroundProvider {
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

    var backgroundImage: UIImage? {
        didSet {
            if let navController = navigationController {
                self.imageView.image = self.backgroundImage
                if let blurredImage = backgroundImage {
                    let scale = UIScreen.main.scale
                    let navHeight = navController.navigationBar.frame.height
                    let cgImage = blurredImage.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: navController.navigationBar.frame.width * scale, height: navHeight * scale))
                    let newImage = UIImage(cgImage: cgImage!, scale: scale, orientation: blurredImage.imageOrientation)
                    navController.navigationBar.setBackgroundImage(newImage, for: .default)
                }
            }
        }
    }

    var menu: Menu!

    private static let resizingMask: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight]

    private lazy var imageView: UIImageView = {
        let imgView = UIImageView(image: self.backgroundImage)
        imgView.frame = self.view.bounds
        imgView.autoresizingMask = resizingMask
        return imgView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true

        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = ObserverMenuController.resizingMask
        backgroundView.addSubview(imageView)

        tableView.register(MenuCell.self, forCellReuseIdentifier: detailCellId)
        tableView.register(MenuToggleCell.self, forCellReuseIdentifier: toggleCellId)
        tableView.backgroundView = backgroundView
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.separatorColor = Constants.Menu.separatorColor
        tableView.backgroundColor = UIColor.clear
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override var prefersStatusBarHidden: Bool {
        return true
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
        cell.textLabel?.text = item.text
        switch item.type {
        case .detail(_):
            cell.accessoryType = .disclosureIndicator
        case .toggle(_):
            break
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = menu[indexPath]
        let cell: UITableViewCell
        switch item.type {
        case .toggle(let binding):
            cell = tableView.dequeueReusableCell(withIdentifier: toggleCellId, for: indexPath)
            cell.selectionStyle = .none
            let toggleCell = cell as! MenuToggleCell
            toggleCell.binding = binding
        case .detail(_):
            cell = tableView.dequeueReusableCell(withIdentifier: detailCellId, for: indexPath)
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

    // MARK: - Menu Background Provider

    func menuBackgroundImage(fromVC: UIViewController, toVC: UIViewController) -> UIImage? {
        return backgroundImage
    }
}
