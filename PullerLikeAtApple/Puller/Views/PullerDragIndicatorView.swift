//
//  PullerDragIndicatorView.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 14.03.2023.
//

import UIKit

final class PullerDragIndicatorView: UIView {
    
    var contentEdgeInsets: UIEdgeInsets = .zero
    
    weak var viewToTranslateGesture: UIView?
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let x = -contentEdgeInsets.left
        let y = -contentEdgeInsets.top
        let width = frame.size.width + contentEdgeInsets.left + contentEdgeInsets.right
        let height = frame.size.height + contentEdgeInsets.top + contentEdgeInsets.bottom
        return CGRect(x: x, y: y, width: width, height: height).contains(point)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        /// If the user has tapped on the extended area of `DragIndicatorView`, we pass the control to the `View` of the presented screen, so that the puller movement is triggered.
        if view == self,
            let viewToTranslateGesture = viewToTranslateGesture {
            
            return viewToTranslateGesture
        }
        
        return view
    }
}
