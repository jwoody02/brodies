//
//  CommentSectionTableViewCell.swift
//  Egg.
//
//  Created by Jordan Wood on 8/27/22.
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
import ActiveLabel

class CommentSectionTableViewCell: UITableViewCell, MultiTappable {
    weak var multiTapDelegate: MultiTappableDelegate?
    lazy var tapCounter = ThreadSafeValue(value: 0)
    weak var delegate: TableViewCellDelegate?
    
    private var db = Firestore.firestore()
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var usernameButton: UIButton!
    
    @IBOutlet weak var actualCommentLabel: ActiveLabel! //VerticalAlignLabel
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    @IBOutlet weak var arrowImage: UIImageView!
    
    @IBOutlet weak var bottomGrayView: UIView!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var likesCountLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    @IBOutlet weak var flagButton: UIButton!
    @IBOutlet weak var brodieBanner: UIImageView!
    
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
        self.contentView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        

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
            
            self.contentView.layer.borderWidth = 1
            self.yourViewBorder.removeFromSuperlayer()
            self.contentView.layer.borderColor = "#f0f0f5".hexToUiColor().cgColor
        }
        
        styleMainStuff()
        styleBottomStuff()
        styleActiveLabel()
    }
    func styleActiveLabel() {
        actualCommentLabel.enabledTypes = [.mention, .hashtag, .url]
        actualCommentLabel.customize { label in
            label.hashtagColor = Constants.primaryColor.hexToUiColor().withAlphaComponent(0.7)
            label.mentionColor = Constants.primaryColor.hexToUiColor()
            label.URLColor = Constants.primaryColor.hexToUiColor()
            label.handleMentionTap { userHandle in
                print("* opening profile for user: @\(userHandle)")
                let userLocalRef = self.db.collection("user-locations").whereField("username", isEqualTo: userHandle.lowercased()).limit(to: 1)
                userLocalRef.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        if querySnapshot?.count != 0 {
                            print("* got user doc: \(querySnapshot?.documents[0].documentID)")
                            self.openProfileForUser(withUID: (querySnapshot?.documents[0].documentID)!)
                        }
                    }
                }
            }
//            label.handleHashtagTap { self.alert("Hashtag", message: $0) }
            label.handleURLTap { url in
                print("* opening url: \(url)")
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    func styleMainStuff() {
        profilePicImage.layer.cornerRadius = 8
        if actualComment.authorProfilePic == "" {
            profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
        } else {
            setUserImage(fromUrl: actualComment.authorProfilePic)
        }
        
        profilePicImage.contentMode = .scaleAspectFill
        profilePicImage.frame = CGRect(x: 15, y: 15, width: 30, height: 30)
        profilePicImage.clipsToBounds = true
        
        usernameButton.setTitle(actualComment.authorUserName, for: .normal)
        usernameButton.sizeToFit()
        usernameButton.backgroundColor = self.contentView.backgroundColor
        usernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: usernameButton.frame.width, height: 14)
        if actualComment.authorID == "1drvriZljTSCXM7qSFyJHCLqENE2" {
            usernameButton.isHidden = true
            brodieBanner.isHidden = false
            timeSincePostedLabel.isHidden = true
            brodieBanner.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: 40, height: 15)
        } else {
            timeSincePostedLabel.isHidden = false
            usernameButton.isHidden = false
            brodieBanner.isHidden = true
        }
        actualCommentLabel.text = actualComment.commentText
        actualCommentLabel.numberOfLines = 0
        actualCommentLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.maxY, width: self.contentView.frame.width - profilePicImage.frame.maxY - 35 - 45, height: 0)
//        actualCommentLabel.sizeToFit()
        let wid = UIScreen.main.bounds.width - 20 - 45 - 35 - 45 - 15
        let expectedLabelHeight = actualComment.commentText.height(withConstrainedWidth: wid, font: UIFont(name: Constants.globalFont, size: 13)!)
        actualCommentLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.maxY, width: actualCommentLabel.frame.width, height: expectedLabelHeight)
        
        timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 10)
        timeSincePostedLabel.textColor = UIColor.lightGray
        timeSincePostedLabel.backgroundColor = contentView.backgroundColor
        
        timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 11)
        let timeSince = Date(timeIntervalSince1970: TimeInterval(actualComment.createdAt)).simplifiedTimeAgoDisplay()
        timeSincePostedLabel.text = "\(actualComment.authorUserName)     ∙ \(timeSince)"
        timeSincePostedLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.minY, width: contentView.bounds.width - 30 - usernameButton.frame.maxX, height: 16)
        
        let arrWidth = 15
        arrowImage.frame = CGRect(x: Int(self.contentView.frame.width)-arrWidth-15, y: 0, width: arrWidth, height: 15)
        arrowImage.center.y = profilePicImage.center.y
        usernameButton.titleLabel?.font = UIFont(name: Constants.globalFontMedium, size: 13)
        actualCommentLabel.font = UIFont(name: Constants.globalFont, size: 12)
        likesCountLabel.font = UIFont(name: Constants.globalFontBold, size: 12)
        commentCountLabel.font = UIFont(name: Constants.globalFontBold, size: 12)
    }
    
    func styleBottomStuff() {
        bottomGrayView.backgroundColor = "#828282".hexToUiColor().withAlphaComponent(0.04)
        let bottomHeight = 35
        bottomGrayView.frame = CGRect(x: 0, y: Int(self.contentView.frame.height) - bottomHeight, width: Int(self.contentView.frame.width), height: bottomHeight)
//        bottomGrayView.layer.borderColor = "#828282".hexToUiColor().withAlphaComponent(0.1).cgColor
//        bottomGrayView.layer.borderWidth = 2
        
        heartButton.frame = CGRect(x: 15, y: 0, width: 20, height: bottomHeight)
        heartButton.setTitle("", for: .normal)
//        likesCountLabel.text = "\(actualComment.numberOfLikes.roundedWithAbbreviations)"
        likesCountLabel.text = "\(actualComment.numberOfLikes.delimiter)"
        if actualComment.numberOfLikes == 0 {
            likesCountLabel.text = ""
        }
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: 100, height: CGFloat(bottomHeight))
        likesCountLabel.sizeToFit()
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: likesCountLabel.frame.width, height: CGFloat(bottomHeight))
//        likesCountLabel.contentHorizontalAlignment = .left
        if actualComment.isLiked {
            heartButton.tintColor = Constants.universalRed.hexToUiColor()
            heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            heartButton.tintColor = .darkGray
            heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        }
        
        commentButton.frame = CGRect(x: Int(likesCountLabel.frame.maxX) + 15, y: 0, width: 20, height: bottomHeight)
        commentButton.setTitle("", for: .normal)
//        commentCountLabel.text = "\(actualComment.numberOfReplies.roundedWithAbbreviations)"
        commentCountLabel.text = "\(actualComment.numberOfReplies.delimiter)"
        if actualComment.numberOfReplies == 0 {
            commentCountLabel.text = ""
        }
        commentCountLabel.frame = CGRect(x: commentButton.frame.maxX + 5, y: 0, width: 100, height: CGFloat(bottomHeight))
//        commentCountLabel.contentHorizontalAlignment = .left
        commentCountLabel.sizeToFit()
        commentCountLabel.frame = CGRect(x: commentButton.frame.maxX + 5, y: 0, width: commentCountLabel.frame.width, height: CGFloat(bottomHeight))
        
        flagButton.setTitle("", for: .normal)
//        flagButton.tintColor = Constants.universalRed.hexToUiColor()
        flagButton.tintColor = .darkGray
        flagButton.frame = CGRect(x: Int(bottomGrayView.frame.width) - 20 - 10, y: 0, width: 20, height: bottomHeight)
        flagButton.setImage(UIImage(systemName: "arrowshape.turn.up.forward")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .medium, scale: .medium))?.image(withTintColor: .darkGray), for: .normal)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        self.contentView.addGestureRecognizer(longPressRecognizer)
    }
    
                                              @objc func longPressed(sender: UILongPressGestureRecognizer)
    {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        showCommentSharePopup()
    }
    
    @IBAction func flagButtonPressed(_ sender: Any) {
        print("* popping up menu")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        showCommentSharePopup()
    }
    func showCommentSharePopup() {
        let vc = ThreeDotsOnComment()
        vc.postID = originalPostID
        vc.authorOfPost = originalPostAuthorID
        vc.authorOFComment = actualComment.authorID
//        vc.imagePostURL = self.actualPost.imageUrl
        vc.mainText = actualComment.commentText
        vc.commentID = commentID
        self.findViewController()?.presentPanModal(vc)
    }
    func likeComment(authorID: String) {
        likesCountLabel.pushScrollingTransitionUp(0.2) // Invoke before changing content
        likesCountLabel.text = "\(actualComment.numberOfLikes.delimiter)"
//        likesCountLabel.sizeToFit()
//        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: likesCountLabel.frame.width, height: CGFloat(40))
        commentButton.frame = CGRect(x: Int(likesCountLabel.frame.maxX) + 15, y: 0, width: 20, height: 35)
        commentCountLabel.frame = CGRect(x: commentButton.frame.maxX + 5, y: 0, width: commentCountLabel.frame.width, height: CGFloat(35))
        
        
        if isCurrentlySavingData == false {
            isCurrentlySavingData = true
            let postsRef = db.collection("posts")
            let timestamp = NSDate().timeIntervalSince1970
            print("* liking at location: posts/\(originalPostAuthorID)/posts/\(originalPostID)/comments/\(commentID)/likes/\(authorID)")
            parentVC?.comments[index].isLiked = true
            actualComment.isLiked = true
            let userIDz = Auth.auth().currentUser?.uid
//            postsRef.document(userID).collection("posts").document(id).updateData(["likes_count":incr])
            self.db.collection("user-locations").document(userIDz!).getDocument { (document, err) in
                print("* doc: \(document)")
                if ((document?.exists) != nil) && document?.exists == true {
                    let data = document?.data()! as! [String: AnyObject]
                    let usrname = data["username"] as? String ?? ""
                    postsRef.document(self.originalPostAuthorID).collection("posts").document(self.originalPostID).collection("comments").document(self.commentID).collection("likes").document(userIDz!).setData([
                    "uid": "\(userIDz as? String ?? "")",
                    "likedAtTimeStamp": Int(timestamp),
                    "username": usrname
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
        likesCountLabel.text = "\(actualComment.numberOfLikes.delimiter)"
        likesCountLabel.sizeToFit()
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: likesCountLabel.frame.width, height: CGFloat(35))
        
        commentButton.frame = CGRect(x: Int(likesCountLabel.frame.maxX) + 15, y: 0, width: 20, height: 35)
        commentCountLabel.frame = CGRect(x: commentButton.frame.maxX + 5, y: 0, width: commentCountLabel.frame.width, height: CGFloat(35))
        
        
        if isCurrentlySavingData == false {
            parentVC?.comments[index].isLiked = false
            actualComment.isLiked = false
            isCurrentlySavingData = true
            let postsRef = db.collection("posts")
//            let value: Double = -1
//            let incr = FieldValue.increment(value)
//            postsRef.document(originalPostAuthorID).collection("posts").document(originalPostID).collection("comments").document(commentID).updateData(["likes_count":incr])
            
            postsRef.document(originalPostAuthorID).collection("posts").document(originalPostID).collection("comments").document(commentID).collection("likes").document(authorID).delete() {err in
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
        if self.actualComment.isLiked == false {
            actualComment.numberOfLikes += 1
            parentVC?.comments[index].numberOfLikes += 1
            print("* liking comment \(commentID)")
            heartButton.tintColor = Constants.universalRed.hexToUiColor()
            heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeComment(authorID: userID)
        } else {
            actualComment.numberOfLikes -= 1
            parentVC?.comments[index].numberOfLikes -= 1
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
        initMultiTap()
    }
    
    override func prepareForReuse() {
        if let ur = URL(string:actualComment.authorProfilePic) {
            KingfisherManager.shared.downloader.cancel(url: ur)
        }
        
        self.profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
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
extension CommentSectionTableViewCell: MultiTappableDelegate {
    func singleTapDetected(in view: MultiTappable) {
        self.delegate?.singleTapDetected(in: self)
//        print("* single tap detected in comment")
        
    }
    func doubleTapDetected(in view: MultiTappable) {
        self.delegate?.doubleTapDetected(in: self)
//        print("* double tap detected on comment")
        
    }
}


// multi tap handlers
protocol TableViewCellDelegate: class {
    func singleTapDetected(in cell: CommentSectionTableViewCell)
    func doubleTapDetected(in cell: CommentSectionTableViewCell)
}
protocol MultiTappableDelegate: class {
    func singleTapDetected(in view: MultiTappable)
    func doubleTapDetected(in view: MultiTappable)
}

class ThreadSafeValue<T> {
    private var _value: T
    private lazy var semaphore = DispatchSemaphore(value: 1)
    init(value: T) { _value = value }
    var value: T {
        get {
            semaphore.signal(); defer { semaphore.wait() }
            return _value
        }
        set(value) {
            semaphore.signal(); defer { semaphore.wait() }
            _value = value
        }
    }
}

protocol MultiTappable: UIView {
    var multiTapDelegate: MultiTappableDelegate? { get set }
    var tapCounter: ThreadSafeValue<Int> { get set }
}

extension MultiTappable {
    func initMultiTap() {
        if let delegate = self as? MultiTappableDelegate { multiTapDelegate = delegate }
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIView.multitapActionHandler))
        addGestureRecognizer(tap)
    }

    func multitapAction() {
        if tapCounter.value == 0 {
            DispatchQueue.global(qos: .utility).async {
                usleep(250_000)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if self.tapCounter.value > 1 {
                        self.multiTapDelegate?.doubleTapDetected(in: self)
                    } else {
                        self.multiTapDelegate?.singleTapDetected(in: self)
                    }
                    self.tapCounter.value = 0
                }
            }
        }
        tapCounter.value += 1
    }
    
}

private extension UIView {
    @objc func multitapActionHandler() {
        if let tappable = self as? MultiTappable { tappable.multitapAction() }
    }
}
extension CommentSectionPopup {
    func styleCopyView(actualComment:commentStruct) {
        
        copyView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        copyView.layer.cornerRadius = 12
        copyView.clipsToBounds = true
        copyView.layer.cornerRadius = 12
        copyView.layer.borderWidth = 1.0
        copyView.layer.borderColor = UIColor.clear.cgColor
        copyView.layer.masksToBounds = true

        copyView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        copyView.layer.shadowOffset = CGSize(width: 0, height: 4)
        copyView.layer.shadowRadius = 12
        copyView.layer.cornerRadius = 12
        copyView.layer.shadowOpacity = 0.1
        copyView.layer.borderWidth = 1
        copyView.layer.borderColor = "#f0f0f5".hexToUiColor().cgColor
        copyView.layer.masksToBounds = false
        copyView.clipsToBounds = true
        
        styleMainStuff(actualComment: actualComment)
        styleBottomStuff(actualComment: actualComment)
    }
    func styleMainStuff(actualComment:commentStruct) {
        profilePicImage.layer.cornerRadius = 8
//        if actualComment.authorProfilePic == "" {
//            profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
//        } else {
//            setUserImage(fromUrl: actualComment.authorProfilePic)
//        }
        
        profilePicImage.contentMode = .scaleAspectFill
        profilePicImage.frame = CGRect(x: 15, y: 15, width: 30, height: 30)
        profilePicImage.clipsToBounds = true
        
        usernameButton.setTitle(actualComment.authorUserName, for: .normal)
        usernameButton.sizeToFit()
        usernameButton.backgroundColor = copyView.backgroundColor
        usernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: usernameButton.frame.width, height: 14)
        
        actualCommentLabel.text = actualComment.commentText
        actualCommentLabel.numberOfLines = 0
        actualCommentLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.maxY, width: UIScreen.main.bounds.width - 20 - profilePicImage.frame.maxY - 35 - 45, height: 0)
//        actualCommentLabel.sizeToFit()
        let wid = UIScreen.main.bounds.width - 20 - 45 - 35 - 45 - 15
        let expectedLabelHeight = actualComment.commentText.height(withConstrainedWidth: wid, font: UIFont(name: Constants.globalFont, size: 13)!)
        actualCommentLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.maxY, width: actualCommentLabel.frame.width, height: expectedLabelHeight)
        
        timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 10)
        timeSincePostedLabel.textColor = UIColor.lightGray
        timeSincePostedLabel.backgroundColor = Constants.surfaceColor.hexToUiColor()
        
        timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 11)
        let timeSince = Date(timeIntervalSince1970: TimeInterval(actualComment.createdAt)).simplifiedTimeAgoDisplay()
        timeSincePostedLabel.text = "\(actualComment.authorUserName)     ∙ \(timeSince)"
        timeSincePostedLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.minY, width: UIScreen.main.bounds.width - 20 - 30 - usernameButton.frame.maxX, height: 16)
        
        let arrWidth = 15
        arrowImage.frame = CGRect(x: Int(copyView.frame.width)-arrWidth-15, y: 0, width: arrWidth, height: 15)
        arrowImage.center.y = profilePicImage.center.y
        if actualComment.authorID == "1drvriZljTSCXM7qSFyJHCLqENE2" {
            usernameButton.isHidden = true
            brodieBanner.isHidden = false
            timeSincePostedLabel.isHidden = true
            brodieBanner.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: 40, height: 15)
        } else {
            timeSincePostedLabel.isHidden = false
            usernameButton.isHidden = false
            brodieBanner.isHidden = true
        }
        usernameButton.titleLabel?.font = UIFont(name: Constants.globalFontMedium, size: 13)
        actualCommentLabel.font = UIFont(name: Constants.globalFont, size: 12)
        likesCountLabel.font = UIFont(name: Constants.globalFontBold, size: 12)
        commentCountLabel.font = UIFont(name: Constants.globalFontBold, size: 12)
    }
    
    
    func styleBottomStuff(actualComment:commentStruct) {
        bottomGrayView.backgroundColor = "#828282".hexToUiColor().withAlphaComponent(0.04)
        let bottomHeight = 35
        bottomGrayView.frame = CGRect(x: 0, y: Int(self.copyView.frame.height) - bottomHeight, width: Int(self.copyView.frame.width), height: bottomHeight)
//        bottomGrayView.layer.borderColor = "#828282".hexToUiColor().withAlphaComponent(0.1).cgColor
//        bottomGrayView.layer.borderWidth = 2
        
        heartButton.frame = CGRect(x: 15, y: 0, width: 20, height: bottomHeight)
        heartButton.setTitle("", for: .normal)
//        likesCountLabel.text = "\(actualComment.numberOfLikes.roundedWithAbbreviations)"
        likesCountLabel.text = "\(actualComment.numberOfLikes.delimiter)"
        if actualComment.numberOfLikes == 0 {
            likesCountLabel.text = ""
        }
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: 100, height: CGFloat(bottomHeight))
        likesCountLabel.sizeToFit()
        likesCountLabel.frame = CGRect(x: heartButton.frame.maxX + 5, y: 0, width: likesCountLabel.frame.width, height: CGFloat(bottomHeight))
//        likesCountLabel.contentHorizontalAlignment = .left
        if actualComment.isLiked {
            heartButton.tintColor = Constants.universalRed.hexToUiColor()
            heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        }
        
        commentButton.frame = CGRect(x: Int(likesCountLabel.frame.maxX) + 15, y: 0, width: 20, height: bottomHeight)
        commentButton.setTitle("", for: .normal)
//        commentCountLabel.text = "\(actualComment.numberOfReplies.roundedWithAbbreviations)"
        commentCountLabel.text = "\(actualComment.numberOfReplies.delimiter)"
        if actualComment.numberOfReplies == 0 {
            commentCountLabel.text = ""
        }
        commentCountLabel.frame = CGRect(x: commentButton.frame.maxX + 5, y: 0, width: 100, height: CGFloat(bottomHeight))
//        commentCountLabel.contentHorizontalAlignment = .left
        commentCountLabel.sizeToFit()
        commentCountLabel.frame = CGRect(x: commentButton.frame.maxX + 5, y: 0, width: commentCountLabel.frame.width, height: CGFloat(bottomHeight))
        
        flagButton.setTitle("", for: .normal)
        flagButton.tintColor = Constants.universalRed.hexToUiColor()
        flagButton.frame = CGRect(x: Int(bottomGrayView.frame.width) - 20 - 10, y: 0, width: 20, height: bottomHeight)
    }
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
                let seconds = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    // Put your code which should be executed with a delay here
                    self.profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
                }
                
            }
        }
    }
    
}
