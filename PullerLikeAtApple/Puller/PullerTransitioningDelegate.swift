//
//  PullerTransitioningDelegate.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 16.02.2023.
//

import UIKit

final class PullerTransitioningDelegate: NSObject {
    
    private let model: PullerModel
    private let animationController: PullerAnimationController
    private weak var fromViewController: UIViewController?
    
    init(model: PullerModel, fromViewController: UIViewController) {
        self.model = model
        self.fromViewController = fromViewController
        self.animationController = PullerAnimationController(model: model, isPresenting: true)
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
        
        PullerPresentationController(presentedViewController: presented,
                                     presenting: presenting,
                                     model: model)
        
    }
}
