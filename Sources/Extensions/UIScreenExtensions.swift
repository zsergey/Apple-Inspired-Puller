//
//  UIScreenExtensions.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 20.02.2023.
//

import UIKit

/// https://github.com/kylebshr/ScreenCorners
public extension UIScreen {
    
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()

    /// The corner radius of the display. Uses a private property of `UIScreen`,
    /// and may report 0 if the API changes.
    var displayCornerRadius: CGFloat {
        guard let cornerRadius = value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            assertionFailure("Failed to detect screen corner radius")
            return 0
        }

        return cornerRadius
    }
}
