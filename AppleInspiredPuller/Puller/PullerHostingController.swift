//
//  PullerHostingController.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 14.04.2023.
//

import SwiftUI

/// `PullerHostingController` fixes issues related to `UIHostingController`.
///
/// Disabling the safe area to prevent a glitch
/// https://defagos.github.io/swiftui_collection_part3
///
/// Syncing the size of the `SwiftUI view` on `UIHostingController` using `CADisplayLink` from the presentation layer of the `UIKit view`
/// https://stackoverflow.com/questions/65150610
///
@available(iOS 15.0, *)
class PullerHostingController<Content: View>: UIHostingController<Content> {
    
    private class RootView: UIView {
        override var frame: CGRect {
            didSet {
                setSizeSwiftUIView(frame.size)
            }
        }
        
        func setSizeSwiftUIView(_ size: CGSize) {
            let swiftUIView = subviews.first
            swiftUIView?.frame = CGRect(origin: .zero, size: size)
        }
    }
    
    var isConfiguredView = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupDisplayLink()
        disableSafeArea()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isConfiguredView {
            (view as? RootView)?.setSizeSwiftUIView(view.frame.size)
            isConfiguredView = true
        }
    }

    private func setupView() {
        guard let swiftUIView = view else {
            return
        }
        
        swiftUIView.removeFromSuperview()
         
        let rootView = RootView()
        rootView.backgroundColor = .systemBackground
        rootView.addSubview(swiftUIView)
        view = rootView
    }
    
    private func setupDisplayLink() {
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: Float(UIScreen.main.maximumFramesPerSecond), preferred: 60)
        displayLink.add(to: .current, forMode: .common)
    }
    
    @objc private func handleDisplayLink() {
        guard let presentationLayer = view.layer.presentation() else {
            return
        }
        let swiftUIView = view.subviews.first
        if swiftUIView?.frame.size != presentationLayer.frame.size {
            (view as? RootView)?.setSizeSwiftUIView(presentationLayer.frame.size)
        }
    }
    
    private func disableSafeArea() {
        
        guard let viewClass = object_getClass(view) else {
            return
        }
        
        let viewSubclassName = String(cString: class_getName(viewClass)).appending("_IgnoreSafeArea")
        if let viewSubclass = NSClassFromString(viewSubclassName) {
            object_setClass(view, viewSubclass)
            return
        }
        
        guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else {
            return
        }
        guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else {
            return
        }
        
        if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
            let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
                return .zero
            }
            class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets),
                            imp_implementationWithBlock(safeAreaInsets),
                            method_getTypeEncoding(method))
        }
        
        objc_registerClassPair(viewSubclass)
        object_setClass(view, viewSubclass)
    }
}
