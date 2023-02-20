//
//  AppleDetent.swift
//  PullerLikeAt
//
//  Created by Sergey Zapuhlyak on 22.03.2023.
//

import UIKit

@available(iOS 15.0, *)
extension PullerModel.Detent {
    
    func makeSheetDetent(id: inout Int) -> UISheetPresentationController.Detent {
        switch self {
        case .medium:
            return .medium()
        case .large, .full:
            return .large()
        case .custom(let value):
            if #available(iOS 16.0, *) {
                let identifier = UISheetPresentationController.Detent.Identifier("id-\(id)")
                id = id + 1
                return .custom(identifier: identifier) { context in
                    value * context.maximumDetentValue
                }
            } else {
                return .medium()
            }
        }
    }
}

@available(iOS 15.0, *)
extension Array where Element == PullerModel.Detent {
    
    var sheetDetents: [UISheetPresentationController.Detent] {
        var id = 0
        return map { $0.makeSheetDetent(id: &id) }
    }
}
