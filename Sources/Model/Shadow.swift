//
//  HapticFeedback.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 20.03.2023.
//

import UIKit

public struct Shadow: Equatable {
    
    public let color: UIColor
    public let opacity: Float
    public let radius: CGFloat
    public let offset: CGSize

    public static var `default`: Shadow {
        
        Shadow(color: UIColor.black.withAlphaComponent(0.15),
               radius: 8,
               offset: .zero)
    }

    public init(color: UIColor, opacity: Float = 1, radius: CGFloat, offset: CGSize) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.offset = offset
    }
}
