//
//  UINavigationBar+Config.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationBar {
    public static func configureNavigationBarStyles() {
        func applyStyle(_ navBar: UINavigationBar) {
            navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navBar.isTranslucent = true
            navBar.shadowImage = UIImage()
        }
        applyStyle(UINavigationBar.appearance(whenContainedInInstancesOf: [ObserverNavigationController.self]))
        applyStyle(UINavigationBar.appearance(whenContainedInInstancesOf: [SolarSystemNavigationController.self]))
    }
}
