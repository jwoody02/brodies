//
//  StatusBarColorProxy.swift
//  FAGlobalKit
//
//  Created by Ferhat Abdullahoglu on 17.07.2019.
//  Copyright © 2019 Ferhat Abdullahoglu. All rights reserved.
//

import UIKit
//import FAStoryKit

public protocol StatusBarColorProxy where Self: UIViewController {
    /// Status bar color
    var statusBarColor: UIColor? {get set}
    /// Method to get the adopting UIiewController
    /// to set its status bar color
    func setBarColor(_ color: UIColor?, animated: Bool) -> Void 
}

public extension StatusBarColorProxy {
    var statusBarColor: UIColor? {
        return .white
    }
}
