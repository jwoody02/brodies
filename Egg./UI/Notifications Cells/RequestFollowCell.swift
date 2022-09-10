//
//  RequestFollowCell.swift
//  Egg.
//
//  Created by Jordan Wood on 9/6/22.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher
import SPAlert

class ReqFollowNotif {
    var uid: String = ""
    var username: String = ""
    var profileImageUrl: String = ""
    var fullname: String = ""
    var hasValidStory: Bool = false
    var isFollowing: Bool = false
    var followingTimeStamp: Double = 0
    var timeSince: String = ""
    var hasAccepted = false
}
class RequestFollowCell: UITableViewCell {
    private var db = Firestore.firestore()
    @IBOutlet weak var profilePicButton: IGStoryButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var startedFollowingYouLabel: UILabel!
    
    @IBOutlet weak var followButton: UIButton!
    
    var parentViewController: NotificationsViewController?
    var index = 0
    
    var result = ReqFollowNotif()
    func styleCell() {
        profilePicButton.setTitle("", for: .normal)
        
        
        let profWid = Int(self.contentView.frame.height - 32)
        let profXY = Int(16)
        profilePicButton.frame = CGRect(x: profXY, y: profXY, width: profWid, height: profWid)
        profilePicButton.layer.cornerRadius = 12
        usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
        startedFollowingYouLabel.font = UIFont(name: "\(Constants.globalFont)", size: 13)
        let attrib = "wants to follow you.  \(result.timeSince)"
        let mutableAttributedString = NSMutableAttributedString.init(string: attrib)
        mutableAttributedString.setColorForText(result.timeSince, with: .lightGray)
        startedFollowingYouLabel.attributedText = mutableAttributedString
        
        let titleWidths = Int(Int(self.contentView.frame.width) - profXY - profWid - 10 - 30 - (Int(self.contentView.bounds.height) - (30)))
        usernameLabel.frame = CGRect(x: Int(profXY + profWid + 10), y: 25, width: titleWidths, height: 16)
        startedFollowingYouLabel.frame = CGRect(x: usernameLabel.frame.minX, y: usernameLabel.frame.maxY, width: CGFloat(titleWidths), height: 15)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true

        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.cornerRadius = 12
        self.layer.shadowOpacity = 0.1
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = hexStringToUIColor(hex: "#f0f0f5").cgColor
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        let arrWit = 30
        if result.profileImageUrl == "" {
            profilePicButton.image = UIImage(named: "no-profile-img.jpeg")
        } else {
            downloadImage(with: result.profileImageUrl)
        }
        styleForNotFollowing()
        let followbuttonwidth = 100
        followButton.frame = CGRect(x: Int(self.contentView.frame.width) - followbuttonwidth - 20, y: Int(22.5), width: followbuttonwidth, height: 35)
        if result.uid == Auth.auth().currentUser?.uid {
            followButton.isHidden = true
        }
        followButton.setTitle("Accept", for: .normal)
//        self.followButton.center.y = self.contentView.frame.center.y
//        self.followButton.fadeIn()
//        arrButton.center.y = self.contentView.center.y
    }
    func styleCellFor(notification: ReqFollowNotif, index: Int) {
        self.result = notification
        self.index = index
        self.usernameLabel.text = notification.username
        if notification.hasValidStory {
            print("* valid story")
            self.profilePicButton.isUserInteractionEnabled = true
            self.profilePicButton.condition = .init(display: .unseen, color: .custom(colors: [hexStringToUIColor(hex: Constants.primaryColor), .blue, hexStringToUIColor(hex: Constants.primaryColor).withAlphaComponent(0.6)]))
        } else {
            print("* no valid story")
            self.profilePicButton.condition = .init(display: .none, color: .none)
        }
        
    }
    @IBAction func acceptButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
//        self.isUserInteractionEnabled = false
        print("* accept button pressed")
        parentViewController?.notifications.remove(at: self.index)
        parentViewController?.usersTableView.deleteRows(at: [IndexPath(row: self.index, section: 0)], with: .automatic) //Hope it is in section 0
        self.db.collection("pending-followers").document(userID!).collection("sub-pending-followers").document(result.uid).delete()
        print("* deleted pending-followers/\(userID)/sub-pending-followers/\(result.uid)")
        SPAlert.present(title: "Accepted @\(result.username)!", preset: .done, haptic: .success)
    }
    func styleForFollowing() {
        self.followButton.setTitle("Unfollow", for: .normal)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
        self.followButton.tintColor = .black
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 12
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        self.followButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        self.followButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        self.followButton.setImage(UIImage(systemName: "chevron.down")?.applyingSymbolConfiguration(.init(pointSize: 8, weight: .semibold, scale: .medium))?.image(withTintColor: .black), for: .normal)
//        self.followButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        let spacing = CGFloat(-10); // the amount of spacing to appear between image and title
//        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: -2, right: 0)
//
//        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    }
    func styleForNotFollowing() {
        self.followButton.setTitle("Follow", for: .normal)
//        self.followButton.backgroundColor = self.hexStringToUIColor(hex: Constants.primaryColor)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
//        self.followButton.tintColor = .white
        self.followButton.tintColor = .black
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 12
        self.followButton.setImage(nil, for: .normal)
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.followButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.followButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.followButton.setImage(UIImage(systemName: "plus")?.applyingSymbolConfiguration(.init(pointSize: 8, weight: .bold, scale: .medium))?.image(withTintColor: .black), for: .normal)
        self.followButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        let spacing = CGFloat(-10); // the amount of spacing to appear between image and title
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: -2, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    }
    
    func downloadImage(`with` urlString : String) {
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        let processor = DownsamplingImageProcessor(size: CGSize(width: profilePicButton.frame.width, height: profilePicButton.frame.height))
        KingfisherManager.shared.retrieveImage(with: resource, options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .cacheOriginalImage
        ], progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.profilePicButton.image = value.image
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
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
        styleCell()
    }
}

