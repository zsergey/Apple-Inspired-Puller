//
//  Keyboard.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 26.10.2022.
//

import UIKit

final public class Keyboard {
    
    final public class Parameters: NSObject {
        
        public var frameFrom: CGRect
        public var frameTo: CGRect
        public var animationDuration: TimeInterval
        public var curve: UIView.AnimationCurve
        
        public init(frameFrom: CGRect,
                    frameTo: CGRect,
                    animationDuration: TimeInterval,
                    curve: UIView.AnimationCurve) {
            
            self.frameFrom = frameFrom
            self.frameTo = frameTo
            self.animationDuration = animationDuration
            self.curve = curve
        }
        
        public init(dictionary: [AnyHashable : Any]) {
            
            self.frameFrom = (dictionary[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            self.frameTo = (dictionary[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            self.animationDuration = (dictionary[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
            let curveInt = (dictionary[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 0
            self.curve = UIView.AnimationCurve(rawValue: curveInt) ?? .easeInOut
        }
    }
    
    public var isKeyboardShown = false

    public var onFrameChange: ((Parameters) -> Void)?
    public var onWillShow: ((Parameters) -> Void)?
    public var onDidShow: ((Parameters) -> Void)?
    public var onWillHide: ((Parameters) -> Void)?
    public var onDidHide: ((Parameters) -> Void)?
    
    private (set) var keyboardParameters: Parameters? {
        didSet {
            guard let new = self.keyboardParameters else {
                return
            }
            if let old = oldValue {
                if new.frameTo != old.frameTo {
                    onFrameChange?(new)
                }
            } else {
                onFrameChange?(new)
            }
        }
    }
    
    private (set) var isSubscribed = false
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    public func subscribeToNotifications() {
        
        if !isSubscribed {
            
            isSubscribed = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillShow(notification:)),
                                                   name: UIResponder.keyboardWillShowNotification,
                                                   object: nil)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardDidShow(notification:)),
                                                   name: UIResponder.keyboardDidShowNotification,
                                                   object: nil)
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillHide(notification:)),
                                                   name: UIResponder.keyboardWillHideNotification,
                                                   object: nil)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardDidHide(notification:)),
                                                   name: UIResponder.keyboardDidHideNotification,
                                                   object: nil)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillChange(notification:)),
                                                   name: UIResponder.keyboardWillChangeFrameNotification,
                                                   object: nil)
        }
    }
    
    public func unsubscribeFromNotifications() {
        if isSubscribed {
            isSubscribed = false
            NotificationCenter.default.removeObserver(self,
                                                      name: UIResponder.keyboardWillShowNotification,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: UIResponder.keyboardDidShowNotification,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: UIResponder.keyboardWillHideNotification,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: UIResponder.keyboardDidHideNotification,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: UIResponder.keyboardWillChangeFrameNotification,
                                                      object: nil)
        }
        
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        if isKeyboardShown {
            return
        }
        
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onWillShow?(keyboardParameters)
    }

    @objc private func keyboardDidShow(notification: Notification) {
        if isKeyboardShown {
            return
        }
        
        isKeyboardShown = true
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onDidShow?(keyboardParameters)
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        if !isKeyboardShown {
            return
        }

        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onWillHide?(keyboardParameters)
    }
    
    @objc private func keyboardDidHide(notification: Notification) {
        if !isKeyboardShown {
            return
        }

        isKeyboardShown = false
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onDidHide?(keyboardParameters)
    }
    
    @objc private func keyboardWillChange(notification: Notification) {
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
    }
    
    private func fetchAnimationParameters(notification: Notification) -> Parameters {
        
        Parameters(dictionary: notification.userInfo ?? [:])
    }
    
    public func animate(with parameters: Parameters,
                        animations: @escaping () -> Void) {
        
        var options = UIView.AnimationOptions(rawValue: UInt(parameters.curve.rawValue))
        options.update(with: .beginFromCurrentState)
        
        UIView.animate(withDuration: parameters.animationDuration,
                       delay: 0,
                       options: options,
                       animations: animations)
    }
}
