//
//  PullerAnimationController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 08.03.2023.
//

import UIKit

final class PullerAnimationController: NSObject {
    
    var isPresenting: Bool
    var pullerMovement: PullerModel.Movement = .vertical
    
    /// `PullerAnimationController` can adjust detents for `PullerPresentationController` when it encounters the `.fitsContent` value in detents array of `PullerModel`.
    weak var pullerPresentationController: PullerPresentationController?
    
    private let model: PullerModel
    private weak var viewController: UIViewController?
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    private var screenHeight: CGFloat { UIScreen.main.bounds.height }
    private var previousCornerRadius: CGFloat = 0
    
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
        
        previousCornerRadius = fromViewController.view.layer.cornerRadius

        let adjustedDetent = adjustDetent(detent, toViewController: toViewController)
        toViewController.view.frame.origin.y = UIScreen.main.bounds.maxY
        let toView = pullerPresentationController?.toView
        let viewHeight = screenHeight * adjustedDetent.value - model.inset
        let frame = toViewController.view.frame
        CATransaction.disableAnimations {
            toView?.frame = CGRect(origin: frame.origin, size: CGSize(width: frame.size.width, height: viewHeight))
        }
        
        model.animator.animate { [weak self] in
            guard let self = self else {
                return
            }

            toView?.frame.origin.y = self.screenHeight - viewHeight - model.inset
            
            if self.model.isModalInPresentation {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

        } completion: { [weak self] _ in
            
            self?.model.onChangeDetent?(adjustedDetent)

            fromViewController.endAppearanceTransition()
            toViewController.endAppearanceTransition()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func dismiss(from fromViewController: UIViewController,
                         to toViewController: UIViewController,
                         using transitionContext: UIViewControllerContextTransitioning) {
        
        let toView = pullerPresentationController?.toView
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
        
        model.animator.animate { [weak self] in
            guard let self = self else {
                return
            }
            if self.pullerMovement == .horizontal {
                toView?.frame.origin.x = self.screenWidth
            } else {
                let value = UIScreen.main.bounds.maxY
                toView?.frame.origin.y = value
                shadowView?.frame.origin.y = value
            }
            
            if hasOutsideDragIndicator {
                dragIndicatorView?.alpha = 0
            }
        } completion: { [weak self] _ in
            guard let self = self else {
                return
            }
            
            if self.previousCornerRadius == UIScreen.main.displayCornerRadius {
                toViewController.view.layer.setCornerRadius(0)
            } else {
                toViewController.view.layer.setCornerRadius(self.previousCornerRadius)
            }
            
            fromViewController.endAppearanceTransition()
            toViewController.endAppearanceTransition()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            self.model.onDidDismiss?()
        }
    }
    
    private func adjustDetent(_ detent: PullerModel.Detent, toViewController: UIViewController) -> PullerModel.Detent {
        
        let defaultHeight = toViewController.view.intrinsicContentSize.height
        let hasDefaultHeight = defaultHeight != UIView.noIntrinsicMetric
        
        if detent.isFitContent && hasDefaultHeight {
            
            let fitsContentDetent = pullerPresentationController?.makeFitsContentDetent(height: defaultHeight) ?? .large
            pullerPresentationController?.isFitContent = true
            pullerPresentationController?.defaultViewHeight = screenHeight * fitsContentDetent.value
            pullerPresentationController?.embedViewToScrollView()

            var detents = [fitsContentDetent]
            for detent in model.detents {
                if !detent.isFitContent && detent.value < fitsContentDetent.value {
                    detents.append(detent)
                }
            }
            detents = detents.sorted(by: <)
            pullerPresentationController?.apply(detents: detents)
            pullerPresentationController?.updateFirstDetentAsSelected()
            
            return detents.first ?? fitsContentDetent
            
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
