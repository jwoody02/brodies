//
//  ReplyLikedCell.swift
//  Egg.
//
//  Created by Jordan Wood on 9/3/22.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher
//timestamp: FieldValue.serverTimestamp(),
//type: 'reply_like',
//userId: userId,
//postId: postId,
//commentId: commentID,
//replyId: replyID,
//likeId: likeID,
//likeUserID: change.data().authorID,
//likeUserName: change.data().authorUserName,
//likeUserImage: change.data().authorProfilePic,
//replyUserID: replyAuthor,
//replyUserName: replySnap.data().authorUserName,
//replyUserImage: replySnap.data().authorProfilePic,
//originalReply: replySnap.data().replyText
class likedReplyNotif {
    var timestamp: Double = 0
    var timeSince: String = ""
    var userId: String = ""
    var postId: String = ""
    var commentId: String = ""
    var replyId: String = ""
    var likeId: String = ""
    var likeUserID: String = ""
    var likeUserName: String = ""
    var likeUserImage: String = ""
    var replyUserID: String = ""
    var replyUserName: String = ""
    var replyUserImage: String = ""
    var originalReply: String = ""
    var postThumbnailURL: String = ""
    var comment: String = ""
    var hasValidStory: Bool = false
    var currentPost: imagePost?
}
class ReplyLikedCell: UITableViewCell {
    private var db = Firestore.firestore()
    @IBOutlet weak var profilePicButton: IGStoryButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var likedYourPostLabel: UILabel!
    @IBOutlet weak var actualCommentTextLabel: UILabel!
    
    @IBOutlet weak var previewImage: UIImageView!
    
    var parentViewController: NotificationsViewController?
    var index = 0
    
    var result = likedReplyNotif()
    func styleCell() {
        profilePicButton.setTitle("", for: .normal)
        
        
        let profWid = Int(self.contentView.frame.height - 32)
        let profXY = Int(16)
        profilePicButton.frame = CGRect(x: profXY, y: profXY, width: profWid, height: profWid)
        profilePicButton.layer.cornerRadius = 12
        usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
        likedYourPostLabel.font = UIFont(name: "\(Constants.globalFont)", size: 13)
        
        let titleWidths = Int(Int(self.contentView.frame.width) - profXY - profWid - 10 - 30 - (Int(self.contentView.bounds.height) - (30)))
        usernameLabel.frame = CGRect(x: Int(profXY + profWid + 10), y: profXY, width: titleWidths, height: 16)
        likedYourPostLabel.frame = CGRect(x: usernameLabel.frame.minX, y: usernameLabel.frame.maxY, width: CGFloat(titleWidths), height: 15)
        let attrib = "liked your reply.  \(result.timeSince)"
        let mutableAttributedString = NSMutableAttributedString.init(string: attrib)
        mutableAttributedString.setColorForText(result.timeSince, with: .lightGray)
        likedYourPostLabel.attributedText = mutableAttributedString
        self.backgroundColor = .clear
        self.contentView.backgroundColor = Constants.surfaceColor.hexToUiColor()
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
        if result.likeUserImage == "" {
            profilePicButton.image = UIImage(named: "no-profile-img.jpeg")
        } else {
            downloadImage(with: result.likeUserImage)
        }
        self.previewImage.layer.cornerRadius = 8
        self.previewImage.clipsToBounds = true
        
        let prevImageY = 15
        let prevImageWidth = Int(self.contentView.bounds.height) - (2*prevImageY)
        
        self.previewImage.frame = CGRect(x: Int(self.contentView.frame.width) - prevImageWidth - prevImageY, y: prevImageY, width: prevImageWidth, height: prevImageWidth)
        self.previewImage.contentMode = .scaleAspectFill
        
        print("* profileHeight: \(profilePicButton.frame.width), preview iamge: \(self.previewImage.frame.width)")
        downloadPreview(with: result.postThumbnailURL)
        
        actualCommentTextLabel.text = "\"\(result.originalReply)\""
        actualCommentTextLabel.textColor = .lightGray
        actualCommentTextLabel.frame = CGRect(x: likedYourPostLabel.frame.minX, y: likedYourPostLabel.frame.maxY, width: CGFloat(titleWidths), height: 15)
    }
    func styleCellFor(notification: likedReplyNotif, index: Int) {
        self.result = notification
        self.index = index
        self.usernameLabel.text = notification.likeUserName
        if notification.hasValidStory {
            print("* valid story")
            self.profilePicButton.isUserInteractionEnabled = true
            self.profilePicButton.condition = .init(display: .unseen, color: .custom(colors: [hexStringToUIColor(hex: Constants.primaryColor), .blue, hexStringToUIColor(hex: Constants.primaryColor).withAlphaComponent(0.6)]))
        } else {
            print("* no valid story")
            self.profilePicButton.condition = .init(display: .none, color: .none)
        }
        
    }
    func downloadPreview(`with` urlString : String) {
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
                self.previewImage.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
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

