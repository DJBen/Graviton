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

fileprivate let expandableCellId = "expandableCell"

class ObserverMenuController: UITableViewController {

    var backgroundImage: UIImage? {
        didSet {
            if let bg = backgroundImage {
                self.blurredImage = UIImageEffects.blurredMenuImage(bg)
            }
        }
    }
    var blurredImage: UIImage?
    private static let resizingMask: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight]
    
    private lazy var imageView: UIImageView = {
        let imgView = UIImageView(image: self.blurredImage)
        imgView.frame = self.view.bounds
        imgView.autoresizingMask = resizingMask
        return imgView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.clear
        clearsSelectionOnViewWillAppear = true
        tableView.register(MenuCell.self, forCellReuseIdentifier: expandableCellId)

        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = ObserverMenuController.resizingMask
        backgroundView.addSubview(imageView)
        
        tableView.backgroundView = backgroundView
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.separatorColor = Constants.Menu.separatorColor
        
        if let navController = navigationController {
            let scale = UIScreen.main.scale
            let navHeight = navController.navigationBar.frame.height
            let cgImage = self.blurredImage?.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: navController.navigationBar.frame.width * scale, height: navHeight * scale))
            let newImage = UIImage(cgImage: cgImage!, scale: scale, orientation: self.blurredImage!.imageOrientation)
            navController.navigationBar.setBackgroundImage(newImage, for: .default)
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
        cell.imageView?.image = #imageLiteral(resourceName: "row_icon_compass")
        cell.textLabel?.text = "Content Drawing"
        cell.accessoryType = .disclosureIndicator
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: expandableCellId, for: indexPath)
        return cell
    }
 
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}

fileprivate extension UIImageEffects {
    static func blurredMenuImage(_ image: UIImage) -> UIImage {
        return imageByApplyingBlur(to: image, withRadius: 8, tintColor: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1).withAlphaComponent(0.1), saturationDeltaFactor: 1.8, maskImage: nil)
    }
}
