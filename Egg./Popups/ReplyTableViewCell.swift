//
//  ReplyTableViewCell.swift
//  Egg.
//
//  Created by Jordan Wood on 8/31/22.
//

import Foundation
import UIKit
import PanModal
import Presentr
import FirebaseFirestore
import FirebaseAuth
import SPAlert
import FirebaseAnalytics
import Kingfisher

class ReplyTableViewCell: UITableViewCell {
//    weak var multiTapDelegate: MultiTappableDelegate?
//    lazy var tapCounter = ThreadSafeValue(value: 0)
//    weak var delegate: TableViewCellDelegate?
    
    private var db = Firestore.firestore()
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var usernameButton: UIButton!
    
    @IBOutlet weak var actualCommentLabel: VerticalAlignLabel!
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    
//    @IBOutlet weak var bottomGrayView: UIView!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var likesCountLabel: UILabel!
    var yourViewBorder = CAShapeLayer()
    var oldestStoryID = ""
    var commentID = ""
    var userID = ""
    var imageHash = ""
    
    var originalPostID = ""
    var originalPostAuthorID = ""
    
    var isCurrentlySavingData = false
    
    var shouldHighlight = false
    var actualComment = commentStruct()
    var reply = CommentReply(data: [:])
    var index = -1
    
    var parentVC: CommentSectionPopup?
    
    func setUserImage(fromUrl: String) {
        let url = URL(string: fromUrl)
        let processor = DownsamplingImageProcessor(size: self.profilePicImage.bounds.size)
        self.profilePicImage.kf.indicatorType = .activity
        self.profilePicImage.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.5)),
                .cacheOriginalImage,
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }
    
    func styleCell() {
        self.backgroundColor = .clear
//        self.contentView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        self.contentView.backgroundColor = .clear
        

        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.cornerRadius = 12
        self.layer.shadowOpacity = 0.1
        
        self.contentView.layer.cornerRadius = 12
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        if shouldHighlight {
            
            yourViewBorder.strokeColor = Constants.primaryColor.hexToUiColor().cgColor
            yourViewBorder.lineDashPattern = [8, 6]
            let padding = 1
            let tmpBounds = CGRect(x: padding, y: padding, width: Int(self.contentView.bounds.width) - (padding*4), height: Int(self.contentView.bounds.height) - (padding*4))
            yourViewBorder.frame = tmpBounds
            yourViewBorder.fillColor = nil
            yourViewBorder.path = UIBezierPath(roundedRect: tmpBounds, cornerRadius: 12).cgPath
            self.contentView.layer.addSublayer(yourViewBorder)
        } else {
            
//            self.contentView.layer.borderWidth = 1
            self.contentView.layer.borderWidth = 0
            self.yourViewBorder.removeFromSuperlayer()
            self.contentView.layer.borderColor = "#f0f0f5".hexToUiColor().cgColor
        }
        
        styleMainStuff()
        styleBottomStuff()
    }
    func styleMainStuff() {
        profilePicImage.layer.cornerRadius = 8
        if reply.authorProfilePic == "" {
            profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
        } else {
            setUserImage(fromUrl: reply.authorProfilePic)
        }
        
        profilePicImage.contentMode = .scaleAspectFill
        profilePicImage.frame = CGRect(x: 15, y: 15, width: 30, height: 30)
        profilePicImage.clipsToBounds = true
        
        usernameButton.setTitle(reply.authorUserName, for: .normal)
        
        usernameButton.sizeToFit()
//        usernameButton.backgroundColor = self.contentView.backgroundColor
        usernameButton.backgroundColor = Constants.backgroundColor.hexToUiColor()
        usernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY - 2, width: usernameButton.frame.width, height: 14)
        
        actualCommentLabel.text = reply.replyText
        actualCommentLabel.numberOfLines = 0
        actualCommentLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.maxY+5, width: self.contentView.frame.width - profilePicImage.frame.maxY - 35 - 45, height: 0)
        actualCommentLabel.sizeToFit()
        actualCommentLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.maxY+5, width: actualCommentLabel.frame.width, height: actualCommentLabel.frame.height)
        
//        timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 9)
        timeSincePostedLabel.textColor = UIColor.lightGray
        timeSincePostedLabel.backgroundColor = contentView.backgroundColor
        
        timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 11)
        let timeSince = Date(timeIntervalSince1970: Double(reply.timestamp)).simplifiedTimeAgoDisplay()
        timeSincePostedLabel.text = "\(reply.authorUserName)    • \(timeSince)"
        timeSincePostedLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.minY, width: contentView.bounds.width - 30 - usernameButton.frame.maxX, height: 16)
        
    }
    
    func styleBottomStuff() {
//        bottomGrayView.backgroundColor = "#828282".hexToUiColor().withAlphaComponent(0.04)
        let bottomHeight = 20
//        bottomGrayView.frame = CGRect(x: 0, y: Int(self.contentView.frame.height) - bottomHeight, width: Int(self.contentView.frame.width), height: bottomHeight)
//        bottomGrayView.layer.borderColor = "#828282".hexToUiColor().withAlphaComponent(0.1).cgColor
//        bottomGrayView.layer.borderWidth = 2
        
        heartButton.frame = CGRect(x: Int(self.contentView.frame.width)-bottomHeight-15, y: 10, width: bottomHeight, height: bottomHeight)
        if reply.likes_count == 0 {
            heartButton.center.y = (self.contentView.frame.height / 2)
        } else {
            heartButton.center.y = (self.contentView.frame.height / 2) - 10
        }
        
        heartButton.setTitle("", for: .normal)
//        likesCountLabel.text = "\(actualComment.numberOfLikes.roundedWithAbbreviations)"
        likesCountLabel.text = "\(reply.likes_count.roundedWithAbbreviations)"
        if reply.likes_count == 0 {
            likesCountLabel.text = ""
        }
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: 100, height: CGFloat(bottomHeight))
        likesCountLabel.sizeToFit()
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: heartButton.frame.maxY, width: likesCountLabel.frame.width, height: CGFloat(bottomHeight))
        likesCountLabel.center.x = self.heartButton.center.x
//        likesCountLabel.contentHorizontalAlignment = .left
        if reply.isLiked {
            heartButton.tintColor = Constants.universalRed.hexToUiColor()
            heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            heartButton.tintColor = .darkGray
            heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        }
        
    }
    func likeComment(authorID: String) {
        likesCountLabel.pushScrollingTransitionUp(0.2) // Invoke before changing content
        likesCountLabel.text = "\(reply.likes_count.roundedWithAbbreviations)"
        likesCountLabel.sizeToFit()
//        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: likesCountLabel.frame.width, height: CGFloat(40))
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: heartButton.frame.maxY, width: likesCountLabel.frame.width, height: CGFloat(20))
        likesCountLabel.center.x = self.heartButton.center.x
        if isCurrentlySavingData == false {
            isCurrentlySavingData = true
            let postsRef = db.collection("posts")
            let timestamp = NSDate().timeIntervalSince1970
            print("* liking at location: posts/\(originalPostAuthorID)/posts/\(originalPostID)/comments/\(commentID)/likes/\(authorID)")
            parentVC?.replies[index].isLiked = true
            reply.isLiked = true
            let userIDz = Auth.auth().currentUser?.uid
//            postsRef.document(userID).collection("posts").document(id).updateData(["likes_count":incr])
            self.db.collection("user-locations").document(userIDz!).getDocument { (document, err) in
                print("* doc: \(document)")
                if ((document?.exists) != nil) && document?.exists == true {
                    let data = document?.data()! as! [String: AnyObject]
                    let usrname = data["username"] as? String ?? ""
                    postsRef.document(self.originalPostAuthorID).collection("posts").document(self.originalPostID).collection("comments").document(self.reply.commentID).collection("comment_replies").document(self.reply.replyID).collection("likes").document(userIDz!).setData([
                    "uid": "\(userIDz as? String ?? "")",
                    "likedAtTimeStamp": Int(timestamp)
                ], merge: true) { err in
                    print("* successfully liked post")
                    
                    self.isCurrentlySavingData = false
                }
            
                }
            }
        }
    }
    func updateLikesLabel() {
        
    }
    func unlikeComment(authorID: String) {
        likesCountLabel.pushScrollingTransitionDown(0.2) // Invoke before changing content
        likesCountLabel.text = "\(reply.likes_count.roundedWithAbbreviations)"
        likesCountLabel.sizeToFit()
//        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: likesCountLabel.frame.width, height: CGFloat(40))
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: heartButton.frame.maxY, width: likesCountLabel.frame.width, height: CGFloat(20))
        likesCountLabel.center.x = self.heartButton.center.x
        if isCurrentlySavingData == false {
            parentVC?.replies[index].isLiked = false
            reply.isLiked = false
            isCurrentlySavingData = true
            let postsRef = db.collection("posts")
            
            postsRef.document(originalPostAuthorID).collection("posts").document(originalPostID).collection("comments").document(reply.commentID).collection("comment_replies").document(reply.replyID).collection("likes").document(authorID).delete() {err in
                print("* done unliking comment!")
                self.isCurrentlySavingData = false
            }
            
        }
    }
    func likeFunction() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if isCurrentlySavingData == false {
        print("* like button pressed")
        let userID : String = (Auth.auth().currentUser?.uid)!
            if reply.isLiked == false {
            parentVC?.replies[index].likes_count += 1
            reply.likes_count += 1
            print("* liking comment \(commentID)")
            heartButton.tintColor = Constants.universalRed.hexToUiColor()
            heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeComment(authorID: userID)
        } else {
            parentVC?.replies[index].likes_count -= 1
            reply.likes_count -= 1
            print("* unliking post \(commentID)")
            heartButton.tintColor = .darkGray
            heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
            unlikeComment(authorID: userID)
        }
//        likeButtonAnimateToRed()
        }
    }
    @IBAction func likeButtonPressed(_ sender: Any) {
        likeFunction()
        
    }
    @IBAction func openProfile(_ sender: Any) {
        openProfileForUser(withUID: actualComment.authorID)
    }
    func getHeightForEverything() -> CGFloat {
        return timeSincePostedLabel.frame.maxY
    }
    func openProfileForUser(withUID: String) {
        print("* opening profile for \(withUID)")
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
            if let navigator = self.findViewController()?.navigationController {
                vc.uidOfProfile = withUID
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigator.pushViewController(vc, animated: true)

            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
//        initMultiTap()
    }
    
    

    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
        styleCell()
        if Constants.isDebugEnabled {
//            var window : UIWindow = UIApplication.shared.keyWindow!
//            window.showDebugMenu()
            self.debuggingStyle = true
        }
    }
}
