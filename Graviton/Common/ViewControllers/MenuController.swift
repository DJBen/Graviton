//
//  MenuController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/10/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class MenuController: UITableViewController, MenuWithBackground, MenuBackgroundProvider {
    private static let resizingMask: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight]

    private lazy var imageView: UIImageView = {
        let imgView = UIImageView(image: self.backgroundImage)
        imgView.frame = self.view.bounds
        imgView.autoresizingMask = resizingMask
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

    override func viewDidLoad() {
        super.viewDidLoad()

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

    override func numberOfSections(in tableView: UITableView) -> Int {
        fatalError()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError()
    }

    // MARK: - Menu Background Provider

    func menuBackgroundImage(fromVC: UIViewController, toVC: UIViewController) -> UIImage? {
        return backgroundImage
    }

}
