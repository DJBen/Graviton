//
//  ObserverDetailViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 7/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import StarryNight
import Orbits
import XLPagerTabStrip

protocol ObserverDetailViewControllerDelegate: NSObjectProtocol {
    func observerDetailViewController(viewController: ObserverDetailViewController, dismissTapped sender: UIButton)
}

class ObserverDetailViewController: UIViewController {
    var target: ObserveTarget!
    var ephemerisId: SubscriptionUUID!

    weak var delegate: ObserverDetailViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupViewElements() {
        title = String(describing: target!)
        navigationController?.navigationBar.barStyle = .black
        let doneBarItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(sender:)))
        navigationItem.rightBarButtonItem = doneBarItem
        view.backgroundColor = UIColor.clear
    }

    override var prefersStatusBarHidden: Bool {
        return Device.isiPhoneX == false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedObserverDetail" {
            let innerVc = segue.destination as! ObserverDetailInnerViewController
            innerVc.target = target
            innerVc.ephemerisId = ephemerisId
        }
    }

    @objc func doneButtonTapped(sender: UIButton) {
        delegate?.observerDetailViewController(viewController: self, dismissTapped: sender)
    }
}

class ObserverDetailInnerViewController: ButtonBarPagerTabStripViewController {
    var target: ObserveTarget!
    var ephemerisId: SubscriptionUUID!

    override func viewDidLoad() {
        settings.style.selectedBarBackgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        settings.style.buttonBarBackgroundColor = UIColor.black
        settings.style.buttonBarItemTitleColor = #colorLiteral(red: 0.9735557437, green: 0.9677678943, blue: 0.978004396, alpha: 1)
        settings.style.buttonBarItemBackgroundColor = UIColor.clear
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
    }

    // MARK: - PagerTabStripDataSource
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let bodyInfo = BodyInfoViewController(style: .plain)
        bodyInfo.target = target
        bodyInfo.ephemerisId = ephemerisId
        return [bodyInfo]
    }
}
