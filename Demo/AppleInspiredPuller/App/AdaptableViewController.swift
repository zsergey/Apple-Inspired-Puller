//
//  AdaptableViewController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 15.10.2023.
//

import UIKit
import Puller

final class AdaptableViewController: UIViewController {
    
    private let insets: UIEdgeInsets = .init(top: 65, left: 16, bottom: 16, right: 16)
    private let minimumHeight: CGFloat = 100
    private let maximumHeight = UIScreen.main.bounds.height - 100
    private let impactGenerator = UIImpactFeedbackGenerator()
    private var pipButton: UIButton!
    private var isMinimized = true
    private var isConfigured = false
    
    override func loadView() {
        let view = GradientView()
        view.topColor = UIColor(hex: 0xF2F23A)
        view.bottomColor = UIColor(hex: 0xF7A51C)
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPipButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updatePipButton()
        
        if !isConfigured {
            (view as? GradientView)?.defaultHeight = minimumHeight
            isConfigured = true
        }
    }
    
    private func setupPipButton() {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "PictureInPictureOutButton")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(pipButtonTapped), for: .touchUpInside)
        view.addSubview(button)
        pipButton = button
    }
    
    @objc private func pipButtonTapped() {
        
        impactGenerator.impactOccurred()
        
        let defaultHeight = isMinimized ? randomHeight() : minimumHeight
        let fitsContentDetent = self.pullerPresentationController?.makeFitsContentDetent(height: defaultHeight) ?? .large
        self.pullerPresentationController?.apply(detents: [fitsContentDetent])
        
        self.pullerPresentationController?.animateChanges { [weak self] in
            self?.pullerPresentationController?.setHeightThatMatches(detent: fitsContentDetent)
        }
        
        isMinimized = !isMinimized
        
        let image = isMinimized ? UIImage(named: "PictureInPictureOutButton") : UIImage(named: "PictureInPictureButton")
        pipButton.setImage(image, for: .normal)
    }
    
    private func updatePipButton() {
        let topInset: CGFloat = 12
        let rightInset: CGFloat = topInset + 3
        let size: CGFloat = 32
        let point = CGPoint(x: view.frame.size.width - size - rightInset, y: topInset)
        pipButton.frame = CGRect(origin: point, size: CGSize(width: size, height: size))
    }
    
    @discardableResult
    private func setRandomDefaultHeight() -> CGFloat {
        
        let defaultHeight = randomHeight() + insets.top + insets.bottom
        (view as? ResizableView)?.defaultHeight = defaultHeight
        return defaultHeight
    }

    private func randomHeight() -> CGFloat {
        CGFloat.random(in: 2 * minimumHeight...maximumHeight)
    }
}
