//
//  UITableViewController+BlurredBackground.swift
//  Graviton
//
//  Created by Sihao Lu on 10/10/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

extension UITableViewController {
    func setUpBlurredBackground() {
        if UIAccessibilityIsReduceTransparencyEnabled() == false {
            tableView.backgroundColor = UIColor.clear
            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            tableView.backgroundView = blurEffectView
            tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)

            // if inside a popover
            if let popover = navigationController?.popoverPresentationController {
                popover.backgroundColor = UIColor.clear
            }
        }
    }
}
