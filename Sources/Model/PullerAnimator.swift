//
//  PullerAnimator.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 16.02.2023.
//

import UIKit

public struct PullerAnimator {
    public var duration: TimeInterval
    public let delay: TimeInterval
    public let damping: CGFloat
    public let initialSpringVelocity: CGFloat
    public let options: UIView.AnimationOptions
    
    public init(duration: TimeInterval,
                delay: TimeInterval,
                damping: CGFloat,
                initialSpringVelocity: CGFloat,
                options: UIView.AnimationOptions) {
        self.duration = duration
        self.delay = delay
        self.damping = damping
        self.initialSpringVelocity = initialSpringVelocity
        self.options = options
    }

    public func animate(_ animations: @escaping () -> Void,
                        completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: initialSpringVelocity,
                       options: options,
                       animations: animations,
                       completion: completion)
    }
    
    public func duration(_ duration: TimeInterval) -> PullerAnimator {
        var instance = self
        instance.duration = duration
        return instance
    }
}

public extension PullerAnimator {
    
    static var spring: Self {
        Self(duration: 0.5,
             delay: 0.0,
             damping: 0.8,
             initialSpringVelocity: 0.0,
             options: UIView.AnimationOptions(arrayLiteral: [
                .curveEaseInOut,
                .allowUserInteraction,
                .beginFromCurrentState
             ])
        )
    }
    
    static var `default`: Self {
        Self(duration: 0.5,
             delay: 0.0,
             damping: 1.0,
             initialSpringVelocity: 0.0,
             options: UIView.AnimationOptions(arrayLiteral: [
                .curveEaseInOut,
                .allowUserInteraction,
                .beginFromCurrentState
             ])
        )
    }
}
