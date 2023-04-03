//
//  PullerTransitioningDelegate.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 16.02.2023.
//

import UIKit

final class PullerTransitioningDelegate: NSObject {
    
    private let model: PullerModel
    private let animationController: PullerAnimationController
    
    init(model: PullerModel, viewController: UIViewController) {
        self.model = model
        self.animationController = PullerAnimationController(model: model,
                                                             viewController: viewController,
                                                             isPresenting: true)
    }
}

extension PullerTransitioningDelegate: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        animationController.isPresenting = true
        return animationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        animationController.isPresenting = false
        return animationController
    }
    
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        
        let pullerPresentationController = PullerPresentationController(presentedViewController: presented,
                                                                        presenting: presenting,
                                                                        model: model)
        animationController.pullerPresentationController = pullerPresentationController
        pullerPresentationController.animationController = animationController
        return pullerPresentationController
    }
}
