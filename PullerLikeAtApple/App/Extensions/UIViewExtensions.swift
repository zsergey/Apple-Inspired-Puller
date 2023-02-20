//
//  UIViewExtensions.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 14.02.2023.
//

import UIKit

extension UIView {
    
    static func deactivate(constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.deactivate(constraints)
    }
    
    static func activate(constraints: [NSLayoutConstraint]) {
        constraints.forEach { ($0.firstItem as? UIView)?.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate(constraints)
    }
    
    @discardableResult
    func pin(to view: UIView, insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        let anchors = [
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leftAnchor.constraint(equalTo: view.leftAnchor, constant: insets.left),
            rightAnchor.constraint(equalTo: view.rightAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ]
        UIView.activate(constraints: anchors)
        return anchors
    }
    
    @discardableResult
    func center(in view: UIView) -> [NSLayoutConstraint] {
        let anchors = [
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        UIView.activate(constraints: anchors)
        return anchors
    }

    @discardableResult
    func centerX(in view: UIView) -> [NSLayoutConstraint] {
        let anchors = [
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ]
        UIView.activate(constraints: anchors)
        return anchors
    }

    @discardableResult
    func centerY(in view: UIView) -> [NSLayoutConstraint] {
        let anchors = [
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ]
        UIView.activate(constraints: anchors)
        return anchors
    }

    @discardableResult
    func vertical(in view: UIView) -> NSLayoutConstraint {
        let anchor = centerXAnchor.constraint(equalTo: view.centerXAnchor)
        UIView.activate(constraints: [anchor])
        return anchor
    }
    
    @discardableResult
    func left(to view: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        let anchor = leftAnchor.constraint(equalTo: view.leftAnchor, constant: constant)
        UIView.activate(constraints: [anchor])
        return anchor
    }

    @discardableResult
    func right(to view: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        let anchor = rightAnchor.constraint(equalTo: view.rightAnchor, constant: -constant)
        UIView.activate(constraints: [anchor])
        return anchor
    }

    @discardableResult
    func top(to view: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        let anchor = topAnchor.constraint(equalTo: view.topAnchor, constant: constant)
        UIView.activate(constraints: [anchor])
        return anchor
    }

    @discardableResult
    func bottom(to view: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        let anchor = bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -constant)
        UIView.activate(constraints: [anchor])
        return anchor
    }

}
