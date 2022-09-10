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
        advertisernameLabel1.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
        advertisernameLabel1.textColor = Constants.textColor.hexToUiColor()
        advertisernameLabel1.text = usingAd.headline ?? ""
        print("* using headline: \(usingAd.headline)")
        LilAdLabel.frame = CGRect(x: advertisernameLabel1.frame.minX, y: advertisernameLabel1.frame.maxY + 5, width: 25, height: 15)
        LilAdLabel.layer.cornerRadius = 4
        LilAdLabel.font = UIFont(name: "\(Constants.globalFont)", size: 11)
        
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
        
        actionButton.frame = CGRect(x: 0, y: mediaView.frame.maxY, width: contentView.frame.width, height: 40)
        actionButton.backgroundColor = Constants.primaryColor.hexToUiColor()
        actionButton.tintColor = .white
        actionButton.setTitleColor(.white, for: .normal)
        let fnt = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
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
        let captionFont = UIFont(name: "\(Constants.globalFont)", size: 14)
        captionLabel.text = usingAd.body ?? ""
        print("* ad body: \(usingAd.body ?? "")")
        captionLabel.frame = CGRect(x: 15, y: actionButton.frame.maxY + 10, width: contentView.frame.width - 30, height: contentView.frame.height - self.actionButton.frame.maxY - 10 - 5)
        captionLabel.numberOfLines = 3
        captionLabel.font = captionFont
        captionLabel.textColor = Constants.textColor.hexToUiColor()
        
        actionButton.isHidden = usingAd.callToAction == nil
        
        setLocalShit()
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
