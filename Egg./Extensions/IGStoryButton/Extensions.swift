//
//  Extensions.swift
//  Egg.
//
//  Created by Jordan Wood on 7/12/22.
//

import UIKit

extension UIColor {
    /// static variable of UIColor applied to darkmode
    static var border = UIColor.clear
}
extension CALayer {
    /// function to add animation to layer without key
    func add<A: CAAnimation>(animation: A, forKey: String? = nil) {
        self.add(animation, forKey: forKey)
    }
}
