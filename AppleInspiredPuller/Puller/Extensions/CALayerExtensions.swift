//
//  CALayerExtensions.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 16.02.2023.
//

import UIKit

extension CALayer {
    
    @discardableResult
    func setCornerRadius(_ cornerRadius: CGFloat) -> CALayer {
        
        self.cornerRadius = cornerRadius
        if #available(iOS 13.0, *) {
            self.cornerCurve = .continuous
        }
        
        return self
    }
    
    func adjustMasksToBounds() {
        
        masksToBounds = cornerRadius > 0
    }
    
    func applyShadow(_ shadow: Shadow?) {
        
        guard let shadow = shadow else {
            
            shadowOpacity = 0
            return
        }
        
        shadowOpacity = shadow.opacity
        shadowColor = shadow.color.cgColor
        shadowRadius = shadow.radius
        shadowOffset = shadow.offset
    }
}
