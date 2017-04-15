
//
//  PushOverlayTransition.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class PushOverlayTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let fromVC: UIViewController
    let toVC: UIViewController
    let operation: UINavigationControllerOperation
    
    init(from fromVC: UIViewController, to toVC: UIViewController, operation: UINavigationControllerOperation) {
        self.fromVC = fromVC
        self.toVC = toVC
        self.operation = operation
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        let offScreenRight = CGAffineTransform(translationX: container.frame.width, y: 0)

        if operation == .push {
            toView.transform = offScreenRight
            container.addSubview(fromView)
            container.addSubview(toView)
        } else if operation == .pop {
            fromView.transform = CGAffineTransform.identity
            container.addSubview(toView)
            container.addSubview(fromView)
        }

        let duration = self.transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            if self.operation == .push {
                toView.transform = CGAffineTransform.identity
            } else if self.operation == .pop {
                fromView.transform = offScreenRight
            }
        }, completion: { finished in
            transitionContext.completeTransition(true)
        })
    }
}
