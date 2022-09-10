//
//  HeartButton.swift
//  Egg.
//
//  Created by Jordan Wood on 6/17/22.
//
import UIKit
extension String {
    func hexToUiColor() -> UIColor {
        var cString:String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

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
}
class HeartButton: UIButton {
var isLiked = false
//    var unlikedImage = UIImage(systemName: "heart")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .medium, scale: .medium))?.image(withTintColor: .red)
//    let likedImage = UIImage(systemName: "heart.fill")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .medium, scale: .medium))?.image(withTintColor: .red)
    var unlikedImage = UIImage(systemName: "heart")?.applyingSymbolConfiguration(.init(pointSize: 19, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
    var likedImage = UIImage(systemName: "heart.fill")?.applyingSymbolConfiguration(.init(pointSize: 19, weight: .medium, scale: .medium))?.image(withTintColor: Constants.universalRed.hexToUiColor())
  
  private let unlikedScale: CGFloat = 0.7
  private let likedScale: CGFloat = 1.3
    
    public var likesCount: Int = 0
//
//  override public init(frame: CGRect) {
//    super.init(frame: frame)
//
//    
//  }
    func setAsCommentLike() {
        unlikedImage = UIImage(systemName: "heart")?.applyingSymbolConfiguration(.init(pointSize: 15, weight: .medium, scale: .medium))?.image(withTintColor: .black)
        likedImage = UIImage(systemName: "heart.fill")?.applyingSymbolConfiguration(.init(pointSize: 15, weight: .medium, scale: .medium))?.image(withTintColor: .red)
    }
    func setDefaultImage() {
        self.imageView?.contentMode = .scaleAspectFit
        self.setInsets(forContentPadding: UIEdgeInsets(top: 12, left: 2, bottom: 2, right: 2), imageTitlePadding: CGFloat(14))
        self.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Regular", size: 10)
        self.tintColor = .darkGray
        setImage(unlikedImage, for: .normal)
    }
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }

  public func flipLikedState() {
    isLiked = !isLiked
      if isLiked {
          self.tintColor = Constants.universalRed.hexToUiColor()
      } else {
          self.tintColor = .darkGray
      }
    animate()
      self.sizeToFit()
  }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentHorizontalAlignment = .center
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        centerButtonImageAndTitle()
    }

    private func centerButtonImageAndTitle() {
        let titleSize = self.titleLabel?.frame.size ?? .zero
        let imageSize = self.imageView?.frame.size  ?? .zero
        let spacing: CGFloat = 6.0
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + spacing),left: 0, bottom: 0, right:  -titleSize.width)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -(imageSize.height + spacing), right: 0)
     }
    public func setNewLikeAmount(to: Int) {
        self.likesCount = to
        print("[heart button] setting to \(suffixNumber(number: to as NSNumber).replacingOccurrences(of: ".0", with: ""))")
        DispatchQueue.main.async {
            self.setTitle("\(self.suffixNumber(number: to as NSNumber).replacingOccurrences(of: ".0", with: ""))", for: .normal)
            self.sizeToFit()
            self.centerButtonImageAndTitle()
        }
        
    }
    
    func suffixNumber(number:NSNumber) -> NSString {

        var num:Double = number.doubleValue;
        let sign = ((num < 0) ? "-" : "" );

        num = fabs(num);

        if (num < 1000.0){
            return "\(sign)\(num)" as NSString;
        }

        let exp:Int = Int(log10(num) / 3.0 ); //log10(1000));

        let units:[String] = ["k","m","G","T","P","E"];

        let roundedNum:Double = round(10 * num / pow(1000.0,Double(exp))) / 10;

        return "\(sign)\(roundedNum)\(units[exp-1])" as NSString;
    }
  private func animate() {
    UIView.animate(withDuration: 0.1, animations: {
      let newImage = self.isLiked ? self.likedImage : self.unlikedImage
      let newScale = self.isLiked ? self.likedScale : self.unlikedScale
      self.transform = self.transform.scaledBy(x: newScale, y: newScale)
      self.setImage(newImage, for: .normal)
        if newImage == self.likedImage {
            self.tintColor = Constants.universalRed.hexToUiColor()
        } else {
            self.tintColor = .darkGray
        }
    }, completion: { _ in
      UIView.animate(withDuration: 0.1, animations: {
        self.transform = CGAffineTransform.identity
          
      })
        
    })
  }
}
extension UIImage {
    public func image(withTintColor color: UIColor) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.normal)
        let rect: CGRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.fill(rect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
extension UIButton {
    func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        print("* image title padding: \(imageTitlePadding)")
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: contentPadding.left,
            bottom: contentPadding.bottom,
            right: contentPadding.right + imageTitlePadding
        )
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
}
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    
        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}
