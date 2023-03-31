//
//  PullerAnimationController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 08.03.2023.
//

import UIKit

final class PullerAnimationController: NSObject {
    
    var isPresenting: Bool
    
    /// `PullerAnimationController` can adjust detents for `PullerPresentationController` when it encounters the `.fitsContent` value in detents array of `PullerModel`.
    weak var pullerPresentationController: PullerPresentationController?
    
    private let model: PullerModel
    private weak var viewController: UIViewController?
    private let screenHeight = UIScreen.main.bounds.height
    private let safeAreaBottomInset: CGFloat = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.safeAreaInsets.bottom ?? 0
    
    init(model: PullerModel,
         viewController: UIViewController?,
         isPresenting: Bool) {
        self.model = model
        self.viewController = viewController
        self.isPresenting = isPresenting
    }
    
    private func present(from fromViewController: UIViewController,
                         to toViewController: UIViewController,
                         until detent: PullerModel.Detent,
                         using transitionContext: UIViewControllerContextTransitioning) {
        
        toViewController.view.frame.origin.y = UIScreen.main.bounds.maxY

        model.animator.animate { [weak self] in
            guard let self = self else {
                return
            }
            
            let adjustedDetent = self.adjustDetent(detent, toViewController: toViewController)
            let viewHeight = self.screenHeight * adjustedDetent.value
            toViewController.view.frame.origin.y = self.screenHeight - viewHeight
            
            if self.model.isModalInPresentation {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

        } completion: { [weak self] _ in
            
            self?.model.onChangeDetent?(detent)

            fromViewController.endAppearanceTransition()
            toViewController.endAppearanceTransition()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func dismiss(from fromViewController: UIViewController,
                         to toViewController: UIViewController,
                         using transitionContext: UIViewControllerContextTransitioning) {
        
        let indexOfShadowView = 1
        transitionContext.containerView.insertSubview(fromViewController.view,
                                                      at: indexOfShadowView + 1)
        
        let hasOutsideDragIndicator = model.dragIndicator.isInside == false
        
        var dragIndicatorView: PullerDragIndicatorView?
        var shadowView: PullerShadowView?
        
        transitionContext.containerView.subviews.forEach { view in
            if let view = view as? PullerDragIndicatorView {
                dragIndicatorView = view
            } else if let view = view as? PullerShadowView {
                shadowView = view
            }
        }
        
        model.onWillDismiss?()

        model.animator.animate {
            
            let value = UIScreen.main.bounds.maxY
            fromViewController.view.frame.origin.y = value
            shadowView?.frame.origin.y = value
            
            if hasOutsideDragIndicator {
                dragIndicatorView?.alpha = 0
            }
            
        } completion: { [weak self] _ in
            
            toViewController.view.layer.setCornerRadius(0)
            fromViewController.endAppearanceTransition()
            toViewController.endAppearanceTransition()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            self?.viewController?.pullerTransitioningDelegate = nil

            self?.model.onDidDismiss?()
        }
    }
    
    private func adjustDetent(_ detent: PullerModel.Detent, toViewController: UIViewController) -> PullerModel.Detent {
        
        let largeHeight = screenHeight * PullerModel.Detent.large.value
        let defaultHeight = toViewController.view.intrinsicContentSize.height
        let hasDefaultHeight = defaultHeight != UIView.noIntrinsicMetric
        
        if detent.isFitContent && hasDefaultHeight {
            
            var viewHeight = defaultHeight + safeAreaBottomInset
            viewHeight = min(viewHeight, screenHeight)
            if viewHeight > largeHeight, viewHeight < screenHeight {
                viewHeight = largeHeight
            }

            let detentValue = viewHeight / screenHeight
            pullerPresentationController?.apply(detents: [.custom(detentValue)])
            
            return .custom(detentValue)
            
        } else if detent.isFitContent {
            
            pullerPresentationController?.apply(detents: [.large])
            
            return .large
        }
        
        return detent
    }
}

extension PullerAnimationController: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        model.animator.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let firstDetent = model.detents.first else {
            return
        }
        
        fromViewController.beginAppearanceTransition(false, animated: true)
        toViewController.beginAppearanceTransition(true, animated: true)
        
        if isPresenting {
            present(from: fromViewController, to: toViewController, until: firstDetent, using: transitionContext)
        } else {
            dismiss(from: fromViewController, to: toViewController, using: transitionContext)
        }
    }
}
