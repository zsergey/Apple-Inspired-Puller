//
//  PullerModel.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 15.02.2023.
//

import Foundation
import UIKit

struct PullerModel {
    
    /// How to animate a puller
    let animator: PullerAnimator
    
    /// Positions of a puller where it can chill
    var detents: [Detent]

    /// Corner radius of a puller
    let cornerRadius: CGFloat

    /// How to display drag indicator in a puller
    let dragIndicator: DragIndicator
    
    /// Can a puller dismiss by swipe or by tap on dimming view?
    let isModalInPresentation: Bool
    
    /// `Detent` at which dimming view shading begins.
    var largestUndimmedDetent: Detent
    
    /// Should a puller be expanded to the maximum `detent` when scrolling up?
    let scrollingExpandsWhenScrolledToEdge: Bool

    /// Should a puller be expanded to the maximum `detent` when the keyboard appears?
    let keyboardExpands: Bool

    /// Swipe sensitivity, the default value in `UIScrollView.DecelerationRate.normal` is too sensitive.
    let decelerationRate: CGFloat
    
    /// Maximum value of alpha of `DimmingView`
    let dimmedAlpha: CGFloat
    
    /// Does a puller have dynamic height? Use `false` if you want to display a puller in the style of `AirPods Pro`.
    let hasDynamicHeight: Bool

    /// Does a puller have the rounded close button?
    let hasCircleCloseButton: Bool

    /// Does a puller can be dismissed by swiping to right?
    /// It has effect only on iPhones and for puller with dynamic height.
    var supportsInteractivePopGesture: Bool

    /// It calls when a puller moves to detents values.
    var onChangeDetent: ((Detent) -> Void)?
    
    /// It calls when a puller will dismiss.
    var onWillDismiss: (() -> Void)?
    
    /// It calls when a puller did dismiss.
    var onDidDismiss: (() -> Void)?
    
    init(animator: PullerAnimator = .default,
         detents: [Detent],
         cornerRadius: CGFloat = 16,
         dragIndicator: DragIndicator = .none,
         isModalInPresentation: Bool = false,
         scrollingExpandsWhenScrolledToEdge: Bool = true,
         keyboardExpands: Bool = true,
         largestUndimmedDetent: Detent = .zero,
         decelerationRate: CGFloat = 0.99,
         dimmedAlpha: CGFloat = 0.4,
         hasDynamicHeight: Bool = true,
         hasCircleCloseButton: Bool = true,
         supportsInteractivePopGesture: Bool = true) {
        self.detents = (detents.filter { $0.value != 0 }.count == 0 ? [.fitsContent] : detents.filter { $0.value != 0 }).sorted(by: <)
        self.animator = animator
        self.cornerRadius = cornerRadius
        self.dragIndicator = dragIndicator
        self.isModalInPresentation = isModalInPresentation
        self.scrollingExpandsWhenScrolledToEdge = scrollingExpandsWhenScrolledToEdge
        self.keyboardExpands = keyboardExpands
        self.largestUndimmedDetent = largestUndimmedDetent
        self.decelerationRate = decelerationRate
        self.dimmedAlpha = dimmedAlpha
        self.hasDynamicHeight = hasDynamicHeight
        self.hasCircleCloseButton = hasCircleCloseButton
        self.supportsInteractivePopGesture = supportsInteractivePopGesture
    }
}

extension PullerModel {
    
    enum Detent {
        case custom(CGFloat)
        case medium
        case large
        case full
        case fitsContent

        var value: CGFloat {
            switch self {
            case .custom(let value): return min(max(value, 0), 1)
            case .medium: return 0.5
            case .large: return 0.92
            case .full: return 1
            case .fitsContent: return 1
            }
        }
        
        var isFull: Bool { value == 1.0 }

        var isFitContent: Bool {
            switch self {
            case .fitsContent: return true
            default: return false
            }
        }
        
        var isExpanded: Bool {
            switch self {
            case .large, .full:
                return true
            case .custom(let value):
                return value == Detent.large.value || value == Detent.full.value
            default:
                return false
            }
        }
        
        static var zero: Detent { .custom(0.0) }
    }
}

extension PullerModel {
    
    enum Movement {
        case vertical
        case horizontal
    }
}

extension PullerModel {
    
    enum DragIndicator: Comparable {
        
        case none
        case inside(UIColor)
        case outside(UIColor)
        
        var isInside: Bool? {
            switch self {
            case .none: return nil
            case .inside: return true
            case .outside: return false
            }
        }
        
        var color: UIColor? {
            switch self {
            case .none: return nil
            case .inside(let color): return color
            case .outside(let color): return color
            }
        }
        
        private var id: Int {
            switch self {
            case .none: return 0
            case .inside: return 1
            case .outside: return 2
            }
        }
        
        static func < (lhs: PullerModel.DragIndicator,
                       rhs: PullerModel.DragIndicator) -> Bool {
            lhs.id < rhs.id
        }
    }
}

extension PullerModel.Detent: Comparable {
    
    static func < (lhs: PullerModel.Detent, rhs: PullerModel.Detent) -> Bool {
        lhs.value < rhs.value
    }
}
