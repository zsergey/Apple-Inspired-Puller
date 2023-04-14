//
//  CATransactionExtensions.swift
//  AppleInspiredPuller
//
//  Created by Sergey Zapuhlyak on 10.03.2023.
//

import UIKit

public extension CATransaction {

    static func disableAnimations(_ completion: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        completion()
        CATransaction.commit()
    }
}
