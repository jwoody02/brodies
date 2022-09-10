//
//  ShareUserButton.swift
//  Egg.
//
//  Created by Jordan Wood on 6/17/22.
//
import UIKit

class ShareUserButton: UIButton {
var isLiked = false
  
//    var unlikedImage = UIImage(systemName: "heart")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .medium, scale: .medium))?.image(withTintColor: .red)
//    let likedImage = UIImage(systemName: "heart.fill")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .medium, scale: .medium))?.image(withTintColor: .red)
    var unlikedImage = UIImage(systemName: "paperplane")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
    let likedImage = UIImage(systemName: "paperplane")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: UIColor.red)
  
  private let unlikedScale: CGFloat = 0.7
  private let likedScale: CGFloat = 1.3
    
    public var likesCount: Int = 0
//
//  override public init(frame: CGRect) {
//    super.init(frame: frame)
//
//
//  }
    func setDefaultImage() {
        self.imageView?.contentMode = .scaleAspectFit
        self.setInsets(forContentPadding: UIEdgeInsets(top: 12, left: 2, bottom: 2, right: 2), imageTitlePadding: CGFloat(14))
        self.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        setImage(unlikedImage, for: .normal)
    }
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }

  public func flipLikedState() {
    isLiked = !isLiked
    animate()
      self.sizeToFit()
  }
    public func setNewLikeAmount(to: Int) {
        self.likesCount = to
        self.setTitle("\(suffixNumber(number: to as NSNumber).replacingOccurrences(of: ".0", with: ""))", for: .normal)
        self.sizeToFit()
    }
    func suffixNumber(number:NSNumber) -> NSString {

        var num:Double = number.doubleValue;
        let sign = ((num < 0) ? "-" : "" );

        num = fabs(num);

        if (num < 1000.0){
            return "\(sign)\(num)" as NSString;
        }

        let exp:Int = Int(log10(num) / 3.0 ); //log10(1000));

        let units:[String] = ["K","M","G","T","P","E"];

        let roundedNum:Double = round(10 * num / pow(1000.0,Double(exp))) / 10;

        return "\(sign)\(roundedNum)\(units[exp-1])" as NSString;
    }
  private func animate() {
    UIView.animate(withDuration: 0.1, animations: {
      let newImage = self.isLiked ? self.likedImage : self.unlikedImage
      let newScale = self.isLiked ? self.likedScale : self.unlikedScale
      self.transform = self.transform.scaledBy(x: newScale, y: newScale)
      self.setImage(newImage, for: .normal)
    }, completion: { _ in
      UIView.animate(withDuration: 0.1, animations: {
        self.transform = CGAffineTransform.identity
          
      })
        
    })
  }
}
