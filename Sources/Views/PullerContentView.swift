//
//  PullerContentView.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 14.03.2024.
//

import UIKit

final class PullerContentView: UIView {
    
    let scrollView = UIScrollView()
    
    weak var contentView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override var frame: CGRect {
        didSet {
            if scrollView.frame != bounds {
                scrollView.frame = bounds
            }
            
            let bounds = CGRect(origin: .zero, size: scrollView.contentSize)
            if contentView?.frame != bounds {
                contentView?.frame = bounds
            }
        }
    }
    
    private func setup() {
        
        addSubview(scrollView)
        scrollView.frame = bounds
    }
}
