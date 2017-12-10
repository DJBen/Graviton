//
//  PushAsideTransition.swift
//  Graviton
//
//  Created by Ben Lu on 4/24/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

/// A transition slightly different than the default behavior.
/// - Default behavior does not slide the presenting view controller aside completely.
/// Instead, the presenting view controller slides approximately 75% width of the screen to the left.
/// - PushAsideTransition slides the presenting view 100% of the width to the left.
///
/// When the presented view controller is not opaque and the presentation style is set to `overCurrentContext`,
/// the default behavior produces interesting visual 'glitches'. Here comes the rescue to address this issue.
class PushAsideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let presenting: Bool
    var destinationBackgroundImage: UIImage?

    init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let container = transitionContext.containerView
        let pushedInView = toVC.view!
        let pushedOutView = fromVC.view!

        let pushedInBeginFrame = presenting ? container.frame.offsetBy(dx: container.frame.width, dy: 0) : container.frame.offsetBy(dx: -container.frame.width, dy: 0)
        let pushedInFinalFrame = container.frame
        let pushedOutBeginFrame = container.frame
        let pushedOutFinalFrame = presenting ? container.frame.offsetBy(dx: -container.frame.width, dy: 0) : container.frame.offsetBy(dx: container.frame.width, dy: 0)

        pushedInView.frame = pushedInBeginFrame
        pushedOutView.frame = pushedOutBeginFrame
        container.addSubview(pushedInView)
        container.addSubview(pushedOutView)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 2.0, options: [.curveEaseInOut], animations: {
            pushedInView.frame = pushedInFinalFrame
            pushedOutView.frame = pushedOutFinalFrame
        }, completion: { (_) in
            let canceled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!canceled)
        })
    }
}
