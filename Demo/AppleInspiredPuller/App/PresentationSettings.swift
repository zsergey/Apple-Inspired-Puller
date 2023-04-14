//
//  PresentationSettings.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 09.03.2023.
//

import Foundation
import Puller

class PresentationSettings {
    
    static let sharedInstance = PresentationSettings()
    
    var slowAnimations: Bool = false
    var dragIndicator: PullerModel.DragIndicator = .none
    var animator: PullerAnimator = .default
    var largestUndimmedDetent: PullerModel.Detent = .zero
    var scrollingExpandsWhenScrolledToEdge: Bool = true
    var keyboardExpands: Bool = true
    var isModalInPresentation: Bool = false
    var dismissWhenSelectedARow: Bool = false
    var hasCircleCloseButton: Bool = true
    var supportsInteractivePopGesture: Bool = true
    
    func makePullerModel(detents: [PullerModel.Detent]? = nil,
                         isSettings: Bool = false,
                         hasDynamicHeight: Bool = true) -> PullerModel {
        var model = PullerModel(animator: animator.duration(isSettings ? 0.5 : (slowAnimations ? 5 : 0.5)),
                                detents: detents ?? [.custom(0.25), .medium, .large],
                                dragIndicator: dragIndicator,
                                isModalInPresentation: isSettings ? false : isModalInPresentation,
                                scrollingExpandsWhenScrolledToEdge: scrollingExpandsWhenScrolledToEdge,
                                keyboardExpands: keyboardExpands,
                                largestUndimmedDetent: largestUndimmedDetent,
                                hasDynamicHeight: hasDynamicHeight,
                                hasCircleCloseButton: hasCircleCloseButton,
                                supportsInteractivePopGesture: supportsInteractivePopGesture)
        model.onChangeDetent = { detent in
            print("change to \(detent)")
        }
        model.onWillDismiss = {
            print("puller will be closed")
        }
        model.onDidDismiss = {
            print("puller was closed")
        }
        return model
    }
}
