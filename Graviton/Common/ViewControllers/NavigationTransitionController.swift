//
//  NavigationTransitionController.swift
//  Graviton
//
//  Created by Ben Lu on 4/24/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

@objc protocol MenuBackgroundProvider {
    @objc optional func menuBackgroundImage(fromVC: UIViewController, toVC: UIViewController) -> UIImage?
}

class NavigationTransitionController: NSObject, UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if fromVC is SceneController || toVC is SceneController {
            return PushOverlayTransition(presenting: operation == .push)
        } else {
            let transition = PushAsideTransition(presenting: operation == .push)
            if let menuProvider = fromVC as? MenuBackgroundProvider, operation == .push {
                transition.destinationBackgroundImage = menuProvider.menuBackgroundImage?(fromVC: fromVC, toVC: toVC)
            } else if let menuProvider = toVC as? MenuBackgroundProvider, operation == .pop {
                transition.destinationBackgroundImage = menuProvider.menuBackgroundImage?(fromVC: fromVC, toVC: toVC)
            }
            return transition
        }
    }
}
