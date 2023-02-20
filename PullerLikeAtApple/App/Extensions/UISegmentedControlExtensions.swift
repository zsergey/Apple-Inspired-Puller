//
//  UISegmentedControlExtensions.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 22.03.2023.
//

import UIKit

extension UISegmentedControl {
    
    func setTextColor(_ color: UIColor) {
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: color]
        setTitleTextAttributes(titleTextAttributes, for: .normal)
        setTitleTextAttributes(titleTextAttributes, for: .selected)
    }
}
