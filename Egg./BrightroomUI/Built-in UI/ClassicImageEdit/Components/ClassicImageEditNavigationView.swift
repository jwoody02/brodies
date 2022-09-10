//
// Copyright (c) 2018 Muukii <muukii.app@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import UIKit

open class ClassicImageEditNavigationView : UIStackView {

  public var didTapDoneButton: () -> Void = {}
  public var didTapCancelButton: () -> Void = {}

  private let saveButton = UIButton(type: .custom)
  private let cancelButton = UIButton(type: .custom)
  
  private let feedbacker = UIImpactFeedbackGenerator(style: .light)

  public init(saveText: String, cancelText: String) {

    super.init(frame: .zero)

    axis = .horizontal
    distribution = .fillEqually

    heightAnchor.constraint(equalToConstant: 50).isActive = true

    addArrangedSubview(cancelButton)
    addArrangedSubview(saveButton)

    cancelButton.setTitle(cancelText, for: .normal)
    saveButton.setTitle(saveText, for: .normal)

      cancelButton.setTitleColor(hexStringToUIColor(hex: Constants.primaryColor), for: .normal)
    saveButton.setTitleColor(hexStringToUIColor(hex: Constants.primaryColor), for: .normal)
      
      cancelButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
      saveButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)

    cancelButton.titleLabel!.font = UIFont.systemFont(ofSize: 17)
    saveButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 17)

    cancelButton.addTarget(self, action: #selector(_didTapCancelButton), for: .touchUpInside)
    saveButton.addTarget(self, action: #selector(_didTapSaveButton), for: .touchUpInside)
  }
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
  public required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  private func _didTapSaveButton() {
    didTapDoneButton()
    feedbacker.impactOccurred()
  }

  @objc
  private func _didTapCancelButton() {
    didTapCancelButton()
    feedbacker.impactOccurred()
  }
}
