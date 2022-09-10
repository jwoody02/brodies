//
//  _Double.swift
//  FAStoryKit
//
//  Created by Ferhat Abdullahoglu on 11.07.2019.
//  Copyright © 2019 Ferhat Abdullahoglu. All rights reserved.
//

import Foundation
import CoreGraphics
/// __Double__ type extensions

internal extension Double {
    /// Value type casted to CGFloat
    var cgFloat: CGFloat {
        return CGFloat(self)
    }
    
    /// Radiants to Degress
    var toDegrees: Double {
        return (self * 180) / .pi
    }
    
    var raidants: Double {
        self / 180.0 * Double.pi
    }
}
