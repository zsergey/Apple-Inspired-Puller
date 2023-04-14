//
//  UIScrollViewExtensions.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 09.03.2023.
//


import UIKit

public extension UIScrollView {

    var isScrolling: Bool {
        isDragging && !isDecelerating || isTracking
    }
}
