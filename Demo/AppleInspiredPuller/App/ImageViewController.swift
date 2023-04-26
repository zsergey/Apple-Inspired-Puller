//
//  ImageViewController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 26.04.2023.
//

import UIKit

final class ImageViewController: UIViewController {
    
    private var imageView: UIImageView?
    private var componentHeight: CGFloat = 0

    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private let safeAreaBottomInset: CGFloat = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.safeAreaInsets.bottom ?? 0

    private var isConfigured = false
    
    override func loadView() {
        view = ResizableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isConfigured {
            adjustContraints()
        } else {
            adjustComponent()
        }
    }
    
    private func adjustComponent() {
        guard let imageView = imageView,
              let image = imageView.image,
              image.size.width != 0,
              image.size.height != 0 else {
            return
        }
        
        let imageViewWidth = imageView.frame.size.width
        let imageAspectRatio = image.size.width / image.size.height
        
        let defaultHeight = imageViewWidth / imageAspectRatio
        if defaultHeight == componentHeight {
            return
        }
        
        isConfigured = true
        
        (view as? ResizableView)?.defaultHeight = defaultHeight
        componentHeight = defaultHeight
    }

    private func adjustContraints() {
        guard let imageView = imageView,
              let image = imageView.image,
              image.size.height != 0 else {
            return
        }
        let imageAspectRatio = image.size.width / image.size.height

        let viewHeight = view.frame.size.height
        let imageViewWidth = viewHeight * imageAspectRatio
        let constant = max((imageViewWidth - view.frame.size.width) / 2, 0)
        
        leftConstraint?.constant = -constant
        rightConstraint?.constant = constant
    }
    
    private func setupUI() {
        
        let imageView = UIImageView(image: UIImage(named: "puller-image"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        
        let leftConstraint = imageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        let rightConstraint = imageView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        let anchors = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            leftConstraint,
            rightConstraint,
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(anchors)
        self.leftConstraint = leftConstraint
        self.rightConstraint = rightConstraint
        self.imageView = imageView
    }
}
