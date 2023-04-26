//
//  ImageContentViewController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 26.04.2023.
//

import UIKit

final class ImageContentViewController: SomeViewController {
    
    private var imageView: UIImageView?

    private weak var scrollBehaviorConstraint: NSLayoutConstraint?
    private var contentOffsetObservation: NSKeyValueObservation?
    private var componentHeight: CGFloat = 0
    
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private let safeAreaBottomInset: CGFloat = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.safeAreaInsets.bottom ?? 0
    
    private var isConfigured = false
    private var minimumTopOffset: CGFloat = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isConfigured {
            adjustComponent()
        }
    }

    private func adjustComponent() {
        guard let imageView = imageView,
              let image = imageView.image,
              image.size.height != 0 else {
            return
        }
        
        let imageViewWidth = imageView.frame.size.width
        let imageAspectRatio = image.size.width / image.size.height
        guard imageViewWidth != 0, imageAspectRatio != 0 else {
            return
        }
        
        let defaultHeight = imageViewWidth / imageAspectRatio
        if defaultHeight == componentHeight {
            return
        }
        
        isConfigured = true
        
        bottomConstraint?.isActive = false
        heightConstraint = imageView.heightAnchor.constraint(equalToConstant: defaultHeight)
        heightConstraint?.isActive = true
        
        let height = CGFloat(Int(defaultHeight))
        tableView.contentInset.top = height
        tableView.contentOffset.y = -height
        tableView.scrollIndicatorInsets.top = height

        componentHeight = defaultHeight
    }
    
    private func setupUI() {
        setBackgroundColor(false)
        
        contentOffsetObservation = tableView.observe(\.contentOffset) { [weak self] scrollView, _ in
            
            self?.updateComponentOnScroll(scrollView)
        }
        
        let imageView = UIImageView(image: UIImage(named: "puller-image"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        
        let leftConstraint = imageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        let rightConstraint = imageView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        let bottomConstraint = imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let scrollBehaviorConstraint = imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: minimumTopOffset)
        let anchors = [
            scrollBehaviorConstraint,
            leftConstraint,
            rightConstraint,
            bottomConstraint
        ]
        NSLayoutConstraint.activate(anchors)
        self.leftConstraint = leftConstraint
        self.rightConstraint = rightConstraint
        self.bottomConstraint = bottomConstraint
        self.scrollBehaviorConstraint = scrollBehaviorConstraint
        self.imageView = imageView
    }
    
    private func updateComponentOnScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        let contentInsetTop = scrollView.contentInset.top
        
        var offset: CGFloat
        
        if contentOffsetY < 0 {
            offset = -(contentInsetTop + contentOffsetY)
        } else {
            offset = -contentInsetTop - contentOffsetY
        }
        offset = min(offset, minimumTopOffset)
        
        scrollBehaviorConstraint?.constant = offset
    }
    
    private func invalidateObserver() {
        
        contentOffsetObservation?.invalidate()
        contentOffsetObservation = nil
    }
    
    deinit {
        
        invalidateObserver()
    }
}
