//
//  PullerModel.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 15.02.2023.
//

import Foundation
import UIKit

public struct PullerModel {
    
    /// How to animate a puller
    public let animator: PullerAnimator
    
    /// Positions of a puller where it can chill
    public var detents: [Detent]

    /// Corner radius of a puller
    public let cornerRadius: CGFloat

    /// How to display drag indicator in a puller
    public let dragIndicator: DragIndicator
    
    /// Can a puller dismiss by swipe or by tap on dimming view?
    public let isModalInPresentation: Bool
    
    /// `Detent` at which dimming view shading begins.
    public var largestUndimmedDetent: Detent
    
    /// Should a puller be expanded to the maximum `detent` when scrolling up?
    public let scrollingExpandsWhenScrolledToEdge: Bool

    /// Should a puller be expanded to the maximum `detent` when the keyboard appears?
    public let keyboardExpands: Bool

    /// Swipe sensitivity, the default value in `UIScrollView.DecelerationRate.normal` is too sensitive.
    public let decelerationRate: CGFloat
    
    /// Maximum value of alpha of `DimmingView`
    public let dimmedAlpha: CGFloat
    
    /// Does a puller have dynamic height? Use `false` if you want to display a puller in the style of `AirPods Pro`.
    public let hasDynamicHeight: Bool

    /// Does a puller have the rounded close button?
    public let hasCircleCloseButton: Bool

    /// Does a puller can be dismissed by swiping to right?
    /// It has effect only on iPhones and for puller with dynamic height.
    public var supportsInteractivePopGesture: Bool

    /// It calls when a puller moves to detents values.
    public var onChangeDetent: ((Detent) -> Void)?
    
    /// It calls when a puller will dismiss.
    public var onWillDismiss: (() -> Void)?
    
    /// It calls when a puller did dismiss.
    public var onDidDismiss: (() -> Void)?
    
    /// Inset of a puller in the style of `AirPods Pro`.
    public var inset: CGFloat {
        hasDynamicHeight ? 0.0 : 6.0
    }
    
    /// Embedding view of `UIViewController` to `UIScrollView` when you use `fitsContent` detent in case of huge height of the view.
    public var embeddingViewToScrollView: Bool

    /// Uses compact width size on iPads.
    public var isCompactPadSize: Bool
    
    public init(animator: PullerAnimator = .default,
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
                supportsInteractivePopGesture: Bool = true,
                embeddingViewToScrollView: Bool = false,
                isCompactPadSize: Bool = true) {
        self.detents = detents
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
        self.embeddingViewToScrollView = embeddingViewToScrollView
        self.isCompactPadSize = isCompactPadSize
    }
}

public extension PullerModel {
    
    enum Detent {
        case custom(CGFloat)
        case medium
        case large
        case full
        case fitsContent

        public var value: CGFloat {
            switch self {
            case .custom(let value): return min(max(value, 0), 1)
            case .medium: return 0.5
            case .large: return 0.92
            case .full: return 1
            case .fitsContent: return 1
            }
        }
        
        public var isFull: Bool { value == 1.0 }

        public var isFitContent: Bool {
            switch self {
            case .fitsContent: return true
            default: return false
            }
        }
        
        public var isExpanded: Bool {
            switch self {
            case .large, .full:
                return true
            case .custom(let value):
                return value == Detent.large.value || value == Detent.full.value
            default:
                return false
            }
        }
        
        public static var zero: Detent { .custom(0.0) }
        
        public init(rawValue: CGFloat) {
            if rawValue == Detent.medium.value {
                self = .medium
            } else if rawValue == Detent.large.value {
                self = .large
            } else if rawValue == Detent.full.value {
                self = .full
            } else {
                self = .custom(rawValue)
            }
        }
    }
}

public extension PullerModel {
    
    enum Movement {
        case vertical
        case horizontal
    }
}

public extension PullerModel {
    
    enum DragIndicator: Comparable {
        
        case none
        case inside(UIColor)
        case outside(UIColor)
        
        public var isInside: Bool? {
            switch self {
            case .none: return nil
            case .inside: return true
            case .outside: return false
            }
        }
        
        public var color: UIColor? {
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
        
        public static func < (lhs: PullerModel.DragIndicator,
                              rhs: PullerModel.DragIndicator) -> Bool {
            lhs.id < rhs.id
        }
    }
}

extension PullerModel.Detent: Comparable {
    
    public static func < (lhs: PullerModel.Detent, rhs: PullerModel.Detent) -> Bool {
        lhs.value < rhs.value
    }
}
