//
//  Keyboard.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 26.10.2022.
//

import UIKit

final class Keyboard {
    
    final class Parameters: NSObject {
        
        var frameFrom: CGRect
        var frameTo: CGRect
        var animationDuration: TimeInterval
        var curve: UIView.AnimationCurve
        
        init(frameFrom: CGRect,
             frameTo: CGRect,
             animationDuration: TimeInterval,
             curve: UIView.AnimationCurve) {
            
            self.frameFrom = frameFrom
            self.frameTo = frameTo
            self.animationDuration = animationDuration
            self.curve = curve
        }
        
        init(dictionary: [AnyHashable : Any]) {
            
            self.frameFrom = (dictionary[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            self.frameTo = (dictionary[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            self.animationDuration = (dictionary[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
            let curveInt = (dictionary[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 0
            self.curve = UIView.AnimationCurve(rawValue: curveInt) ?? .easeInOut
        }
    }
    
    var isKeyboardShown = false

    var onFrameChange: ((Parameters) -> Void)?
    var onWillShow: ((Parameters) -> Void)?
    var onDidShow: ((Parameters) -> Void)?
    var onWillHide: ((Parameters) -> Void)?
    var onDidHide: ((Parameters) -> Void)?
    
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
    
    func subscribeToNotifications() {
        
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
    
    func unsubscribeFromNotifications() {
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
    
    @objc func keyboardWillShow(notification: Notification) {
        if isKeyboardShown {
            return
        }
        
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onWillShow?(keyboardParameters)
    }

    @objc func keyboardDidShow(notification: Notification) {
        if isKeyboardShown {
            return
        }
        
        isKeyboardShown = true
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onDidShow?(keyboardParameters)
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if !isKeyboardShown {
            return
        }

        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onWillHide?(keyboardParameters)
    }
    
    @objc func keyboardDidHide(notification: Notification) {
        if !isKeyboardShown {
            return
        }

        isKeyboardShown = false
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
        onDidHide?(keyboardParameters)
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        let keyboardParameters = fetchAnimationParameters(notification: notification)
        self.keyboardParameters = keyboardParameters
    }
    
    private func fetchAnimationParameters(notification: Notification) -> Parameters {
        
        Parameters(dictionary: notification.userInfo ?? [:])
    }
    
    func animate(with parameters: Parameters,
                        animations: @escaping () -> Void) {
        
        var options = UIView.AnimationOptions(rawValue: UInt(parameters.curve.rawValue))
        options.update(with: .beginFromCurrentState)
        
        UIView.animate(withDuration: parameters.animationDuration,
                       delay: 0,
                       options: options,
                       animations: animations)
    }
}
