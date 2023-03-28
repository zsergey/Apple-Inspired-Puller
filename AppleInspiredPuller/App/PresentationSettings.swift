//
//  PresentationSettings.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 09.03.2023.
//

import Foundation

class PresentationSettings {
    
    static let sharedInstance = PresentationSettings()
    
    var slowAnimations: Bool = false
    var dragIndicator: PullerModel.DragIndicator = .none
    var animator: PullerAnimator = .default
    var largestUndimmedDetent: PullerModel.Detent = .custom(0.25)
    var scrollingExpandsWhenScrolledToEdge: Bool = true
    var keyboardExpands: Bool = true
    var isModalInPresentation: Bool = false
    var dismissWhenSelectedARow: Bool = false
    var hasCircleCloseButton: Bool = true
    
    func makePullerModel(detents: [PullerModel.Detent]? = nil,
                         isSettings: Bool = false,
                         hasDynamicHeight: Bool = true) -> PullerModel {
        PullerModel(animator: animator.duration(isSettings ? 0.5 : (slowAnimations ? 5 : 0.5)),
                    detents: detents ?? [.custom(0.25), .medium, .large],
                    dragIndicator: dragIndicator,
                    isModalInPresentation: isSettings ? false : isModalInPresentation,
                    scrollingExpandsWhenScrolledToEdge: scrollingExpandsWhenScrolledToEdge,
                    keyboardExpands: keyboardExpands,
                    largestUndimmedDetent: largestUndimmedDetent,
                    hasDynamicHeight: hasDynamicHeight,
                    hasCircleCloseButton: hasCircleCloseButton)
    }
}
