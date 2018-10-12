//
//  InformationViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 11/24/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class InformationViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        view.backgroundColor = UIColor.clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "embedInformation" {
            _ = segue.destination as! InformationInnerViewController
        }
    }
}

class InformationInnerViewController: ButtonBarPagerTabStripViewController {
    override func viewDidLoad() {
        settings.style.selectedBarBackgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        settings.style.buttonBarBackgroundColor = UIColor.black
        settings.style.buttonBarItemTitleColor = #colorLiteral(red: 0.9735557437, green: 0.9677678943, blue: 0.978004396, alpha: 1)
        settings.style.buttonBarItemBackgroundColor = UIColor.clear
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for _: PagerTabStripViewController) -> [UIViewController] {
        let rtsInfo = ObserverRTSViewController(style: .plain)
        let realtimeInfo = RealtimeInfoViewController(style: .plain)
        return [realtimeInfo, rtsInfo]
    }
}
