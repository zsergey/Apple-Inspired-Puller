//
//  UIColorExtensions.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 20.02.2023.
//

import UIKit

extension UIColor {
    
    static var grapiteColor = UIColor(hex: 0x11100C)
    static var skyBlueColor = UIColor(hex: 0xC6D8FF)
    static var lightTurquoiseColor = UIColor(hex: 0xB5F2EA)
    static var peachColor = UIColor(hex: 0xFED6BC)

    convenience init(hex: Int, alpha: CGFloat = 1) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255
        let g = CGFloat((hex & 0xFF00) >> 8) / 255
        let b = CGFloat((hex & 0xFF)) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
