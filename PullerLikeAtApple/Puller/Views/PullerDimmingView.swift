//
//
//  PullerDimmingView.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 08.03.2023.
//

import UIKit

final class PullerDimmingView: UIView {
    
    var onDidTap: (() -> Void)?
    
    weak var viewToTranslateGesture: UIView?
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        alpha = 0.0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapView))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapView() {
        onDidTap?()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        guard view == nil else {
            return view
        }
        
        return viewToTranslateGesture?.hitTest(point, with: event)
    }
}
