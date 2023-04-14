//
//  UIViewControllerExtensions.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 17.02.2023.
//

import UIKit

public extension UIViewController {
    
    private struct AssociatedKeys {
        static var pullerTransitioningDelegate: UInt8 = 0
        static var pullerPresentationController: UInt8 = 1
    }
    
    /// To enable any `ViewController` displayed as a puller to obtain a weak reference to the `PullerPresentationController`.
    var pullerPresentationController: PullerPresentationController? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pullerPresentationController) as? PullerPresentationController
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.pullerPresentationController,
                                     newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// To make any `ViewController` displayable as a puller, it is necessary to store a strong reference to the `PullerTransitioningDelegate` somewhere.
    var pullerTransitioningDelegate: PullerTransitioningDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pullerTransitioningDelegate) as? PullerTransitioningDelegate
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.pullerTransitioningDelegate,
                                     newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func presentAsPuller(_ viewController: UIViewController,
                         model: PullerModel,
                         completion: (() -> Void)? = nil) {
        
        guard presentedViewController == nil else {
            dismiss(animated: true, completion: {
                self.presentAsPuller(viewController, model: model)
            })
            return
        }
        
        pullerTransitioningDelegate = PullerTransitioningDelegate(model: model, viewController: self)
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = pullerTransitioningDelegate
        
        present(viewController, animated: true, completion: completion)
    }
}

public extension UIViewController {
    
    func findScrollView() -> UIScrollView? {
        if let navigationController = self as? UINavigationController,
           let view = navigationController.topViewController?.view {
            return findScrollView(in: view)
        }
        
        return findScrollView(in: view)
    }
    
    private func findScrollView(in view: UIView?) -> UIScrollView? {
        guard let view = view else {
            return nil
        }
        for index in view.subviews.indices {
            let subView = view.subviews[index]
            if let scrollView = subView as? UIScrollView {
                return scrollView
            }
            let scrollView = findScrollView(in: subView)
            if scrollView != nil {
                return scrollView
            }
        }
        return nil
    }

}

