//
//  MenuController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/10/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class MenuController: UIViewController, UITableViewDelegate, UITableViewDataSource, MenuWithBackground, MenuBackgroundProvider {
    private static let resizingMask: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight]

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var imageView: UIImageView = {
        let imgView = UIImageView(image: self.backgroundImage)
        imgView.frame = self.view.bounds
        imgView.autoresizingMask = MenuController.resizingMask
        return imgView
    }()

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

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        view.addConstraint(tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        view.addConstraint(tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor))
        view.addConstraint(tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor))

        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = ObserverMenuController.resizingMask
        backgroundView.addSubview(imageView)
        tableView.backgroundView = backgroundView

        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.separatorColor = Constants.Menu.separatorColor
        tableView.backgroundColor = UIColor.clear
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        fatalError()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError()
    }

    // MARK: - Menu Background Provider

    func menuBackgroundImage(fromVC: UIViewController, toVC: UIViewController) -> UIImage? {
        return backgroundImage
    }

}
