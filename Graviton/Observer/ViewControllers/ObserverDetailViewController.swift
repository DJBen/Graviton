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

enum BodyInfoTarget {
    case star(Star)
    case nearbyBody(Body)
}

class ObserverDetailViewController: UIViewController {
    var target: BodyInfoTarget!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentTransparentNavigationBar()
    }

    private func setupViewElements() {
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedObserverDetail" {
            let innerVc = segue.destination as! ObserverDetailInnerViewController
            innerVc.target = target
        }
    }
}

class ObserverDetailInnerViewController: ButtonBarPagerTabStripViewController {
    var target: BodyInfoTarget!

    override func viewDidLoad() {
        settings.style.selectedBarBackgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        settings.style.buttonBarBackgroundColor = UIColor.white
        settings.style.buttonBarItemTitleColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        settings.style.buttonBarItemBackgroundColor = UIColor.white
        super.viewDidLoad()
    }

    // MARK: - PagerTabStripDataSource
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let bodyInfo = BodyInfoViewController(style: .plain)
        bodyInfo.target = target
        return [bodyInfo]
    }
}
