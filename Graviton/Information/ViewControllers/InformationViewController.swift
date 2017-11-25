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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedInformation" {
            _ = segue.destination as! InformationInnerViewController
        }
    }
}

class InformationInnerViewController: ButtonBarPagerTabStripViewController {

    override func viewDidLoad() {
        settings.style.selectedBarBackgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        settings.style.buttonBarBackgroundColor = #colorLiteral(red: 0.9735557437, green: 0.9677678943, blue: 0.978004396, alpha: 1)
        settings.style.buttonBarItemTitleColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        settings.style.buttonBarItemBackgroundColor = #colorLiteral(red: 0.9735557437, green: 0.9677678943, blue: 0.978004396, alpha: 1)
        super.viewDidLoad()
    }

    // MARK: - PagerTabStripDataSource
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let rtsInfo = ObserverRTSViewController(style: .plain)
        let realtimeInfo = RealtimeInfoViewController(style: .plain)
        return [realtimeInfo, rtsInfo]
    }
}
