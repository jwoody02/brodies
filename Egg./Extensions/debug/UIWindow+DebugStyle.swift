//
//  UIWindow+DebugStyle.swift
//  Egg.
//
//  Created by Jordan Wood on 6/25/22.
//

import UIKit

extension UIWindow {

//  public func setupDebugStyleGesture() {
//    let tap = UITapGestureRecognizer(target: self, action: #selector(showDebugMenu))
//    tap.numberOfTapsRequired = 5
//    tap.numberOfTouchesRequired = 1
//    tap.delaysTouchesBegan = false
//    tap.delaysTouchesEnded = false
//    addGestureRecognizer(tap)
//
//    // Swizzle UIView's didMoveToSuperview
//    let originalSelector = #selector(UIView.didMoveToSuperview)
//    let swizzleSelector = #selector(UIView.debuggingDidMoveToSuperview)
//    let originalMethod = class_getInstanceMethod(UIView.self, originalSelector)
//    let swizzleMethod = class_getInstanceMethod(UIView.self, swizzleSelector)
//    method_exchangeImplementations(originalMethod!, swizzleMethod!)
//  }

  @objc func showDebugMenu() {
    guard let presentingController = rootViewController else {
      print("UIWindow cannot present its debug menu without a rootViewController")
      return
    }

    let showHideTitle = debuggingStyle ? "Hide Containers" : "Show Containers"
    let alertController = UIAlertController(title: "Debug Menu", message: nil, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: showHideTitle, style: .default, handler: { _ in
        print("* setting debug style: \(!self.debuggingStyle)")
      self.debuggingStyle = !self.debuggingStyle
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    presentingController.present(alertController, animated: true)
  }
}
