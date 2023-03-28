//
//  HapticFeedback.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 20.03.2023.
//

import UIKit

struct Shadow: Equatable {
    
    let color: UIColor
    let opacity: Float
    let radius: CGFloat
    let offset: CGSize

    static var `default`: Shadow {
        
        Shadow(color: UIColor.black.withAlphaComponent(0.15),
               radius: 8,
               offset: .zero)
    }

    init(color: UIColor, opacity: Float = 1, radius: CGFloat, offset: CGSize) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.offset = offset
    }
}
