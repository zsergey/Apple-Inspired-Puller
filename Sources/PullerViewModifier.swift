//
//  PullerViewModifier.swift
//  AppleInspiredPuller
//
//  Created by Ruslan Kavetsky on 10.04.2023.
//

import SwiftUI

@available(iOS 15, *)
public struct PullerViewModifier<ContentView: View>: ViewModifier {
    
    @Binding private var isPresented: Bool
    
    private let model: PullerModel
    private let content: () -> ContentView
    
    public init(isPresented: Binding<Bool>,
                model: PullerModel,
                @ViewBuilder content: @escaping () -> ContentView) {
        _isPresented = isPresented
        self.model = model
        self.content = content
    }
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: isPresented, perform: updatePresentation)
    }
    
    private func updatePresentation(_ isPresented: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene else {
            return
        }
        
        guard let rootViewController = windowScene.keyWindow?.rootViewController else {
            return
        }
        
        var fromViewController = rootViewController
        if let presentedViewController = fromViewController.presentedViewController {
            fromViewController = presentedViewController
        }
        
        if isPresented {
            let onDidDismiss = model.onDidDismiss
            var model = model
            model.onDidDismiss = {
                self.isPresented = false
                onDidDismiss?()
            }
            
            let toViewController = PullerHostingController(rootView: content())
            fromViewController.presentAsPuller(toViewController, model: model)
        }
    }
}

@available(iOS 15, *)
public extension View {
    
    /// Presents a puller when the binding to a Boolean value you provide is true.
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the puller that you create in the modifier’s content closure.
    ///   - model: A model of the puller.
    ///   - contentView: A closure that returns the content of the puller.
    func puller<ContentView: View>(isPresented: Binding<Bool>,
                                   model: PullerModel,
                                   @ViewBuilder content: @escaping () -> ContentView) -> some View {
        modifier(PullerViewModifier<ContentView>(isPresented: isPresented,
                                                 model: model,
                                                 content: content))
    }
}
