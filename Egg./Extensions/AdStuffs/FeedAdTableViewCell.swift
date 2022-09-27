//
//  FeedAdTableViewCell.swift
//  Egg.
//
//  Created by Jordan Wood on 8/6/22.
//

import UIKit
import GoogleMobileAds

class FeedAdTableViewCell: UITableViewCell {
    @IBOutlet weak var nativeAdView: GADNativeAdView!
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var advertisernameLabel1: UILabel!
    @IBOutlet weak var LilAdLabel: UILabel!
    
    @IBOutlet weak var mediaView: GADMediaView!
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var advertisernameLabel2: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()

//        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
        contentView.frame = CGRect(x: 5, y: 10, width: self.frame.width - 10, height: self.frame.height - 20)
    }
    func styleCell(usingAd: GADNativeAd) {
        contentView.frame = CGRect(x: 5, y: 10, width: self.frame.width - 10, height: self.frame.height - 20)
//        self.backgroundColor = .clear
        self.nativeAdView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width + 20, height: contentView.frame.height)
        
        profilePicImage.layer.cornerRadius = 8
        profilePicImage.frame = CGRect(x: 8, y: 8, width: 38, height: 38)
        print("* setting image")
        if let icon = usingAd.icon {
            profilePicImage.image = icon.image
        } else {
            profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
        }
        advertisernameLabel1.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: contentView.frame.width - profilePicImage.frame.maxY - 20, height: 16)
        advertisernameLabel1.text = usingAd.advertiser
        advertisernameLabel1.font = UIFont(name: Constants.globalFontBold, size: 12)
        advertisernameLabel1.textColor = Constants.textColor.hexToUiColor()
        advertisernameLabel1.text = usingAd.headline ?? ""
        print("* using headline: \(usingAd.headline)")
        LilAdLabel.frame = CGRect(x: advertisernameLabel1.frame.minX, y: advertisernameLabel1.frame.maxY + 5, width: 25, height: 15)
        LilAdLabel.layer.cornerRadius = 4
        LilAdLabel.font = UIFont(name: "\(Constants.globalFontMedium)", size: 10)
        
        LilAdLabel.textColor = Constants.primaryColor.hexToUiColor()
        LilAdLabel.backgroundColor = Constants.secondaryColor.hexToUiColor()
        
        
//        mediaView.contentMode = .scaleAspectFill
//        nativeAdView.mediaView?.contentMode = .scaleAspectFill
        mediaView.contentMode = .scaleAspectFit
        nativeAdView.mediaView?.contentMode = .scaleAspectFit
        
        nativeAdView.backgroundColor = .clear
        nativeAdView.isUserInteractionEnabled = true
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        mediaView.backgroundColor = .clear
        mediaView.frame = CGRect(x: 0, y: profilePicImage.frame.maxY + 8 , width: contentView.frame.width, height: contentView.frame.width)
        mediaView.mediaContent = usingAd.mediaContent
        mediaView.isUserInteractionEnabled = true
        
        actionButton.frame = CGRect(x: 0, y: mediaView.frame.maxY, width: contentView.frame.width, height: 40)
        actionButton.backgroundColor = Constants.primaryColor.hexToUiColor()
        actionButton.tintColor = .white
        actionButton.setTitleColor(.white, for: .normal)
        let fnt = UIFont(name: Constants.globalFontBold, size: 12)
        actionButton.titleLabel?.font = fnt
        let hotAction = (usingAd.callToAction ?? "").lowercased().capitalizingFirstLetter() // "INSTALL" -> "Install"
        actionButton.setTitle(hotAction, for: .normal)
        actionButton.semanticContentAttribute = .forceRightToLeft
        let estimatedLabelWidth = hotAction.width(withConstrainedHeight: 40, font: fnt!)
        print("* got width: \(estimatedLabelWidth)")
        let leftOffset = self.frame.width - estimatedLabelWidth - 10 - 20
        print("* estiamted offset: \(leftOffset)")
        actionButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 20)
        actionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: leftOffset, bottom: 0, right: 10)
        actionButton.isUserInteractionEnabled = false
        
//        advertisernameLabel2.text = usingAd.advertiser
//        advertisernameLabel2.backgroundColor = Constants.backgroundColor.hexToUiColor()
        let captionFont = UIFont(name: "\(Constants.globalFont)", size: 13)
        captionLabel.text = usingAd.body ?? ""
        print("* ad body: \(usingAd.body ?? "")")
        captionLabel.frame = CGRect(x: 15, y: actionButton.frame.maxY + 10, width: contentView.frame.width - 30, height: contentView.frame.height - self.actionButton.frame.maxY - 10 - 5)
        captionLabel.numberOfLines = 3
        captionLabel.font = captionFont
        captionLabel.textColor = Constants.textColor.hexToUiColor()
        
        actionButton.isHidden = usingAd.callToAction == nil
        
        setLocalShit()
        
//        if let icon = usingAd.icon {
//            icon.image?.getColors { colors in
//                self.actionButton.backgroundColor = colors?.background
//                self.actionButton.tintColor = colors?.primary
//                self.actionButton.setTitleColor(colors?.primary, for: .normal)
//                if ((colors?.primary.isLight()) != nil) && (colors?.primary.isLight()) == true {
//                    self.actionButton.setTitleColor(.black, for: .normal)
//                } else {
//                    self.actionButton.setTitleColor(.white, for: .normal)
//                }
//                
//                self.LilAdLabel.backgroundColor = colors?.primary
//                self.LilAdLabel.textColor = colors?.background
//            }
//        }
        
    }
    func setLocalShit() {
        nativeAdView.callToActionView = self.actionButton
        nativeAdView.mediaView = self.mediaView
        nativeAdView.bodyView = self.captionLabel
        nativeAdView.iconView = self.profilePicImage
        nativeAdView.headlineView = self.advertisernameLabel1
    }
    override class func awakeFromNib() {
        super.awakeFromNib()
//        self.addSeparatorLineToTop()
    }
}
extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}
extension UIColor {

    // Check if the color is light or dark, as defined by the injected lightness threshold.
    // Some people report that 0.7 is best. I suggest to find out for yourself.
    // A nil value is returned if the lightness couldn't be determined.
    func isLight(threshold: Float = 0.5) -> Bool? {
        let originalCGColor = self.cgColor

        // Now we need to convert it to the RGB colorspace. UIColor.white / UIColor.black are greyscale and not RGB.
        // If you don't do this then you will crash when accessing components index 2 below when evaluating greyscale colors.
        let RGBCGColor = originalCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        guard let components = RGBCGColor?.components else {
            return nil
        }
        guard components.count >= 3 else {
            return nil
        }

        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
        return (brightness > threshold)
    }
}
