
//
//  PushOverlayTransition.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

/// This transition creates an overlay that blurs the source view. Instead of being pushed aside, the source view keeps in its place.
class PushOverlayTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let presenting: Bool

    init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return presenting ? 0.4 : 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        let offScreenRight = container.frame.offsetBy(dx: container.frame.width, dy: 0)

        let imageView: UIImageView

        if let bgProvider = fromVC as? MenuBackgroundProvider, presenting {
            imageView = UIImageView(image: bgProvider.menuBackgroundImage?(fromVC: fromVC, toVC: toVC))
        } else if let bgProvider = toVC as? MenuBackgroundProvider, !presenting {
            imageView = UIImageView(image: bgProvider.menuBackgroundImage?(fromVC: fromVC, toVC: toVC))
        } else {
            imageView = UIImageView()
        }

        let imageContainerView = UIView(frame: presenting ? offScreenRight : container.frame)
        imageContainerView.clipsToBounds = true
        imageContainerView.addSubview(imageView)
        let imageViewLeft = imageContainerView.bounds.offsetBy(dx: -container.frame.width, dy: 0)
        imageView.frame = presenting ? imageViewLeft : imageContainerView.bounds

        if presenting {
            imageContainerView.frame = offScreenRight
            toView.frame = offScreenRight
            container.addSubview(fromView)
            container.addSubview(toView)
        } else {
            imageContainerView.frame = container.frame
            fromView.frame = container.frame
            container.addSubview(toView)
            container.addSubview(fromView)
        }

        container.insertSubview(imageContainerView, belowSubview: presenting ? toView : fromView)
        let duration = self.transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            if self.presenting {
                imageContainerView.frame = container.frame
                imageView.frame = imageContainerView.bounds
                toView.frame = container.frame
            } else {
                imageContainerView.frame = offScreenRight
                imageView.frame = imageViewLeft
                fromView.frame = offScreenRight
            }
        }, completion: { finished in
            let canceled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!canceled)
        })
    }
}
