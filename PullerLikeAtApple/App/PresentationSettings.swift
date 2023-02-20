//
//  PresentationSettings.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 09.03.2023.
//

import Foundation

class PresentationSettings {
    
    static let sharedInstance = PresentationSettings()
    
    var slowAnimations: Bool = false
    var dragIndicator: PullerModel.DragIndicator = .none
    var pullerAnimator: PullerAnimator = .default
    var largestUndimmedDetent: PullerModel.Detent = .custom(0.25)
    var scrollingExpandsWhenScrolledToEdge: Bool = true
    var keyboardExpands: Bool = true
    var isClosingLockedBySwipe: Bool = false
    var dismissWhenSelectedARow: Bool = false
    
    func makePullerModel(detents: [PullerModel.Detent]? = nil,
                         isSettings: Bool = false,
                         hasDynamicHeight: Bool = true) -> PullerModel {
        PullerModel(animator: pullerAnimator.duration(isSettings ? 0.5 : (slowAnimations ? 5 : 0.5)),
                    detents: detents ?? [.custom(0.25), .medium, .large],
                    dragIndicator: dragIndicator,
                    isClosingLockedBySwipe: isSettings ? false : isClosingLockedBySwipe,
                    scrollingExpandsWhenScrolledToEdge: scrollingExpandsWhenScrolledToEdge,
                    keyboardExpands: keyboardExpands,
                    largestUndimmedDetent: largestUndimmedDetent,
                    hasDynamicHeight: hasDynamicHeight)
    }
}
