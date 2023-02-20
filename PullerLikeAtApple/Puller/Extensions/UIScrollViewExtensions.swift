//
//  UIScrollViewExtensions.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 09.03.2023.
//


import UIKit

extension UIScrollView {

    var isScrolling: Bool {
        isDragging && !isDecelerating || isTracking
    }
}
