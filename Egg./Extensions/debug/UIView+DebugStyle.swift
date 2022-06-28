//
//  UIView+DebugStyle.swift
//  Egg.
//
//  Created by Jordan Wood on 6/25/22.
//

import UIKit

struct AssociatedKeys {
  static var debuggingStyle: String = "debuggingStyle"
  static var nonDebuggingAttributes: String = "nonDebuggingAttributes"
}

extension UIView {
  
  // MARK: - Associated Objects
  
  // debuggingStyle is only set on the superview that applies the style to all its subviews
  var debuggingStyle: Bool {
    set { objc_setAssociatedObject(self, &AssociatedKeys.debuggingStyle, newValue, .OBJC_ASSOCIATION_ASSIGN)
      // didSet:
        print("* new debug style: \(newValue)")
      applyDebuggingStyle(newValue)
    }
    get { return objc_getAssociatedObject(self, &AssociatedKeys.debuggingStyle) as? Bool ?? false }
  }
  
  private var nonDebuggingAttributes: [String: Any] {
    set { objc_setAssociatedObject(self, &AssociatedKeys.nonDebuggingAttributes, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    get { return objc_getAssociatedObject(self, &AssociatedKeys.nonDebuggingAttributes) as? [String: Any] ?? [:] }
  }
  
  private func saveNonDebuggingAttritutes(for keyPaths: [String]) {
    self.nonDebuggingAttributes = keyPaths.reduce(into: [String: Any]()) { (attributes, keyPath) in
      
      attributes[keyPath] = self.value(forKeyPath: keyPath) ?? NSNull()
    }
  }
  
  private func applyNonDebuggingAttributes() {
    self.nonDebuggingAttributes.forEach { keyPath, value in
      self.setValue(value is NSNull ? nil : value, forKeyPath: keyPath)
    }
  }
  
  // MARK: - Swizzling
  
  @objc func debuggingDidMoveToSuperview() {
    self.debuggingDidMoveToSuperview() // Call original method (Swizzling)
    // Assuming window is the superview with/without debuggingStyle set to true/false
    if let window = self.window, window.debuggingStyle {
      applyDebuggingStyle(true)
    }
  }
  
  // MARK: -
  
  func applyDebuggingStyle(_ visible: Bool) {
    defer { subviews.forEach { $0.applyDebuggingStyle(visible) } }
    guard visible else { return applyNonDebuggingAttributes() }
    
    // Applying debugging attributes
    let debugColor: UIColor = .red
    switch self {
    case let imageView as UIImageView:
      saveNonDebuggingAttritutes(for: [
        #keyPath(layer.borderColor),
        #keyPath(layer.borderWidth)])
      imageView.layer.borderColor = debugColor.cgColor
      imageView.layer.borderWidth = visible ? 1.0 : 0.0
      
    case let label as UILabel:
      saveNonDebuggingAttritutes(for: [
        #keyPath(layer.borderColor),
        #keyPath(layer.borderWidth)])
      label.layer.borderColor = debugColor.cgColor
      label.layer.borderWidth = 1.0
      
    case let cell as UICollectionViewCell:
      saveNonDebuggingAttritutes(for: [
        #keyPath(layer.backgroundColor),
        #keyPath(layer.borderColor),
        #keyPath(layer.borderWidth)])
      cell.layer.backgroundColor = UIColor.yellow.withAlphaComponent(0.3).cgColor
      cell.layer.borderColor = debugColor.cgColor
      cell.layer.borderWidth = 1.0
      
    case let stackView as UIStackView:
      saveNonDebuggingAttritutes(for: [#keyPath(layer.backgroundColor)])
      stackView.layer.backgroundColor = UIColor.purple.withAlphaComponent(0.3).cgColor
      
    case let view where view.superview is UIStackView:
      saveNonDebuggingAttritutes(for: [
        #keyPath(layer.borderColor),
        #keyPath(layer.borderWidth)])
      view.layer.borderColor = UIColor.purple.cgColor
      view.layer.borderWidth = 1.0
      
    default:
      saveNonDebuggingAttritutes(for: [
        #keyPath(layer.borderColor),
        #keyPath(layer.borderWidth)])
      layer.borderColor = UIColor.blue.cgColor
      layer.borderWidth = 1.0
    }
    
  }
}
