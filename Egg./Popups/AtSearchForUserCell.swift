//
//  AtSearchForUserCell.swift
//  Egg.
//
//  Created by Jordan Wood on 9/18/22.
//

import UIKit
import FirebaseFirestore
import Kingfisher

class AtSearchForUserCell: UICollectionViewCell {
    private var db = Firestore.firestore()
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var brodieBanner: UIImageView!
    
    var parentViewController: CommentSectionPopup?
    var index = 0
    var isUnblockView = false
    var result = User(uid: "", username: "", profileImageUrl: "", bio: "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: "", hasValidStory: false, isFollowing: false)
    func styleCell() {
        let profXY = Int(5)
        let profWid = Int(Int(self.contentView.frame.height) - (profXY*2))
        
        profilePicImage.frame = CGRect(x: profXY, y: profXY, width: profWid, height: profWid)
        profilePicImage.layer.cornerRadius = 8
        titleLabel.font = UIFont(name: Constants.globalFontBold, size: 11)
        subTitleLabel.font = UIFont(name: "\(Constants.globalFont)", size: 11)
        
        let titleWidths = Int(Int(self.contentView.frame.width) - profXY - profWid - 5)
        titleLabel.frame = CGRect(x: Int(profXY + profWid + 10), y: 5, width: titleWidths, height: 16)
        subTitleLabel.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY, width: CGFloat(titleWidths), height: 15)
        titleLabel.text = result.fullname
        subTitleLabel.text = "@\(result.username)"
        subTitleLabel.textColor = .gray
        self.backgroundColor = .clear
//        self.contentView.backgroundColor = .white
        self.contentView.backgroundColor = Constants.backgroundColor.hexToUiColor()
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true

        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 8
        self.layer.cornerRadius = 8
        self.layer.shadowOpacity = 0.1
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = hexStringToUIColor(hex: "#f0f0f5").cgColor
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        if result.profileImageUrl == "" {
            profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
        } else {
            downloadImage(with: result.profileImageUrl)
        }
        
       
        if result.uid == "1drvriZljTSCXM7qSFyJHCLqENE2" {
            print("* brodieeee")
            titleLabel.isHidden = true
            subTitleLabel.isHidden = true
            brodieBanner.isHidden = false
            brodieBanner.frame = CGRect(x: Int(profXY + profWid + 10), y: 5, width: 40, height: 16)
            brodieBanner.center.y = self.contentView.frame.height / 2
            subTitleLabel.frame = CGRect(x: titleLabel.frame.minX, y: brodieBanner.frame.maxY, width: CGFloat(titleWidths), height: 15)
            subTitleLabel.text = "@brodie"
        } else {
            titleLabel.isHidden = false
            subTitleLabel.isHidden = false
            brodieBanner.isHidden = true
        }
    }
    
    func downloadImage(`with` urlString : String) {
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        let processor = DownsamplingImageProcessor(size: CGSize(width: profilePicImage.frame.width, height: profilePicImage.frame.height))
        KingfisherManager.shared.retrieveImage(with: resource, options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .cacheOriginalImage
        ], progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.profilePicImage.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
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
    // Inside UITableViewCell subclass

    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 2, bottom: 5, right: 2))
        styleCell()
    }
    override func prepareForReuse() {
        if let ur = URL(string:result.profileImageUrl) {
            KingfisherManager.shared.downloader.cancel(url: ur)
        }
        
        self.profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
    }
}
