//
//  AppleSheet.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 15.02.2023.
//

import UIKit

extension UIViewController {

    @available(iOS 15.0, *)
    func presentAsAppleSheet(_ viewController: UIViewController,
                             model: PullerModel,
                             completion: (() -> Void)? = nil) {
        
        guard presentedViewController == nil else {
            dismiss(animated: true, completion: {
                self.presentAsAppleSheet(viewController, model: model)
            })
            return
        }
        
        viewController.apply(model: model)
        
        present(viewController, animated: true, completion: completion)
        
    }
    
    @available(iOS 15.0, *)
    private func apply(model: PullerModel) {
        
        guard let sheetController = sheetPresentationController else {
            return
        }
        
        sheetController.detents = model.detents.sheetDetents
        sheetController.prefersGrabberVisible = model.dragIndicator != .none
        sheetController.prefersScrollingExpandsWhenScrolledToEdge = model.scrollingExpandsWhenScrolledToEdge
        
        isModalInPresentation = model.isClosingLockedBySwipe
        sheetController.preferredCornerRadius = model.cornerRadius
        if #available(iOS 16.0, *) {
            var id: Int = 0
            sheetController.largestUndimmedDetentIdentifier = model.largestUndimmedDetent.makeSheetDetent(id: &id).identifier
        } else {
            sheetController.largestUndimmedDetentIdentifier = .medium
        }
    }
}
