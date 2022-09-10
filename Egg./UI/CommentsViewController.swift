//
//  CommentsViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 6/14/22.
//

import UIKit
import Foundation
import SwiftKeychainWrapper
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Kingfisher
import SpriteKit
import FirebaseAnalytics

struct commentStruct: Equatable {
    var authorID = ""
    var commentID = ""
    var authorUserName = ""
    var authorProfilePic = ""
    var commentText = ""
    var createdAt = Double(0)
    var numberOfReplies = Int(0)
    var firstStoryUID = ""
    var numberOfLikes = Int(0)
    var isLiked = false
    static func ==(lhs: commentStruct, rhs: commentStruct) -> Bool {
        return lhs.authorID == rhs.authorID && lhs.commentID == rhs.commentID && lhs.authorUserName == rhs.authorUserName && lhs.authorProfilePic == rhs.authorProfilePic && lhs.commentText == rhs.commentText && lhs.createdAt == rhs.createdAt
    }
}
class commentTableViewCell: UITableViewCell {
    private var db = Firestore.firestore()
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var usernameButton: UIButton!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var viewCommentsButton: UIButton!
    @IBOutlet weak var likeButton: HeartButton!
    @IBOutlet weak var actualCommentLabel: VerticalAlignLabel!
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    
    
    var oldestStoryID = ""
    var commentID = ""
    var userID = ""
    var imageHash = ""
    
    var originalPostID = ""
    var originalPostAuthorID = ""
    
    var isCurrentlySavingData = false
    
    var actualComment = commentStruct()
    
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
    func styleElements() {
//        self.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        profilePicImage.layer.cornerRadius = 8
        profilePicImage.frame = CGRect(x: 15, y: 15, width: 30, height: 30)
        usernameButton.contentHorizontalAlignment = .left
        let extraButtonWidths = Int(self.frame.width) - Int(profilePicImage.frame.maxY) - 20
        usernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: CGFloat(extraButtonWidths), height: 16)
        usernameButton.backgroundColor = .blue
        actualCommentLabel.verticalAlignment = .top
//        actualCommentLabel.font = UIFont(name: "\(Constants.globalFont)", size: 13)
        
        timeSincePostedLabel.frame = CGRect(x: usernameButton.frame.minX, y: usernameButton.frame.maxY, width: CGFloat(extraButtonWidths), height: 20)
        timeSincePostedLabel.backgroundColor = .clear
        
        let likebuttonWidth = 40
        likeButton.centerVertically()
        likeButton.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        likeButton.layer.cornerRadius = 4
        likeButton.frame = CGRect(x: Int(self.frame.width) - likebuttonWidth - 15, y: Int(profilePicImage.frame.minY) + 10, width: likebuttonWidth, height: 80)
        likeButton.unlikedImage = UIImage(systemName: "heart")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .semibold, scale: .medium))?.image(withTintColor: .lightGray)
        likeButton.setDefaultImage()
        if Constants.isDebugEnabled {
//            var window : UIWindow = UIApplication.shared.keyWindow!
//            window.showDebugMenu()
            self.debuggingStyle = true
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
    func likeButtonAnimateToRed() {
//        self.updateCommentButtonLocation()
        if self.likeButton.isLiked {
            self.likeButton.setNewLikeAmount(to: self.likeButton.likesCount - 1)
            self.likeButton.sizeToFit()
        } else {
            self.likeButton.setNewLikeAmount(to: self.likeButton.likesCount + 1)
            self.likeButton.sizeToFit()
        }
        self.likeButton.flipLikedState()
        
        let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
    }
    func likeComment(authorID: String) {
        if isCurrentlySavingData == false {
            isCurrentlySavingData = true
            let postsRef = db.collection("posts")
            let timestamp = NSDate().timeIntervalSince1970
            print("* liking at location: posts/\(originalPostAuthorID)/posts/\(originalPostID)/comments/\(commentID)/likes/\(authorID)")
//            let value: Double = 1
//            let incr = FieldValue.increment(value)
//
//            postsRef.document(originalPostAuthorID).collection("posts").document(originalPostID).collection("comments").document(commentID).updateData(["likes_count":incr]) {err in
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
    func unlikeComment(authorID: String) {
        if isCurrentlySavingData == false {
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
    @IBAction func likeButtonPressed(_ sender: Any) {
        if isCurrentlySavingData == false {
        print("* like button pressed")
        let userID : String = (Auth.auth().currentUser?.uid)!
        if self.likeButton.isLiked == false{
            print("* liking comment \(commentID)")
            likeComment(authorID: userID)
        } else {
            print("* unliking post \(commentID)")
            unlikeComment(authorID: userID)
        }
        likeButtonAnimateToRed()
        }
        
    }
    @IBAction func openProfile(_ sender: Any) {
        openProfileForUser(withUID: actualComment.authorID)
    }
    func getHeightForEverything() -> CGFloat {
        return timeSincePostedLabel.frame.maxY
    }
    func openProfileForUser(withUID: String) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
            if let navigator = self.findViewController()?.navigationController {
                vc.uidOfProfile = withUID
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigator.pushViewController(vc, animated: true)

            }
        }
    }
}
class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? commentTableViewCell
        commentTextField.placeholder = "Reply to \(cell?.actualComment.authorUserName ?? "")'s comment"
        commentTextField.becomeFirstResponder()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentTableViewCell", for: indexPath) as! commentTableViewCell
        cell.likeButton.setAsCommentLike()
        cell.styleElements()
        let comment = comments[indexPath.row]
        cell.actualComment = comment
        cell.commentID = comment.commentID
        
        
        cell.usernameButton.setTitle(comment.authorUserName, for: .normal)
        cell.usernameButton.sizeToFit()
        cell.usernameButton.backgroundColor = self.view.backgroundColor
        cell.usernameButton.frame = CGRect(x: cell.usernameButton.frame.minX, y: cell.usernameButton.frame.minY, width: UIScreen.main.bounds.width - cell.profilePicImage.frame.maxX - cell.likeButton.frame.width - 15 - 25, height: 14)
        
        
        cell.actualCommentLabel.text = comment.commentText
        cell.actualCommentLabel.numberOfLines = 0
        cell.actualCommentLabel.frame = CGRect(x: cell.usernameButton.frame.minX, y: cell.usernameButton.frame.maxY+5, width: cell.usernameButton.frame.width, height: 0)
        cell.actualCommentLabel.sizeToFit()
        cell.actualCommentLabel.frame = CGRect(x: cell.usernameButton.frame.minX, y: cell.usernameButton.frame.maxY+5, width: cell.usernameButton.frame.width, height: cell.actualCommentLabel.frame.height)
        cell.originalPostAuthorID = originalPostAuthorID
        cell.originalPostID = originalPostID
        cell.userID = comment.authorID
        
//        cell.usernameButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        if comment.authorProfilePic == "" {
            cell.profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
        } else {
            cell.setUserImage(fromUrl: comment.authorProfilePic)
        }
        
        
        
//        cell.usernameButton.frame = CGRect(x: cell.usernameButton.frame.minX, y: cell.usernameButton.frame.minY, width: cell.usernameButton.frame.width, height: 14)
        cell.timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
        cell.timeSincePostedLabel.textColor = UIColor.lightGray
        let timeSince = Date(timeIntervalSince1970: TimeInterval(comment.createdAt)).simplifiedTimeAgoDisplay()
        cell.timeSincePostedLabel.text = "\(timeSince)"
        cell.timeSincePostedLabel.sizeToFit()
        cell.timeSincePostedLabel.frame = CGRect(x: cell.actualCommentLabel.frame.minX, y: cell.actualCommentLabel.frame.maxY + 5, width: cell.timeSincePostedLabel.frame.width, height: 16)
        cell.timeSincePostedLabel.backgroundColor = cell.backgroundColor
        
        
        cell.replyButton.frame = CGRect(x: cell.timeSincePostedLabel.frame.maxX+10, y: cell.timeSincePostedLabel.frame.minY, width: UIScreen.main.bounds.width - cell.timeSincePostedLabel.frame.maxX - 15, height: 16)
        
        cell.likeButton.setNewLikeAmount(to: comment.numberOfLikes)
        print("* set likie button to: comment.numberOfLikes")
        cell.likeButton.contentMode = .scaleAspectFit
        cell.likeButton.imageView?.contentMode = .scaleAspectFit
        cell.likeButton.centerVertically()
        cell.likeButton.backgroundColor = .clear
        cell.likeButton.contentMode = .center
        
        if comment.isLiked == true {
            print("* comment is liked: '\(comment.commentText)'")
            cell.likeButton.setImage(cell.likeButton.likedImage, for: .normal)
            cell.likeButton.isLiked = true
            cell.likeButton.tintColor = Constants.universalRed.hexToUiColor()
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            // Trigger pagination when scrolled to last cell
            // Feel free to adjust when you want pagination to be triggered
            if (indexPath.row == comments.count - 1) && hasReachedEndOfComments == false {
                
                print("* fetching more comments. Current comment count: \(comments.count-1)")
                paginate()
            }
        }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let expectedLabelHeight = comments[indexPath.row].commentText.height(withConstrainedWidth: UIScreen.main.bounds.width - 15 - 40 - 10 - 25, font: UIFont(name: Constants.globalFont, size: 14)!)
        print("* [\(indexPath.row)] calculated expected height \(expectedLabelHeight)")
        let calculatedHeight = expectedLabelHeight + 14 + 15 + 16 + 20
        print("* [\(indexPath.row)] final height \(calculatedHeight)")
        return calculatedHeight ?? 120
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    @IBOutlet weak var commentsTableView: UITableView!
    private var db = Firestore.firestore()
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var captionTextView: VerticalAlignLabel!
    @IBOutlet weak var topLabel: UILabel!
    
    
    @IBOutlet weak var bottomWhiteView: UIView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var postButton: UIButton!
    
    @IBOutlet weak var commentTableView: UITableView!
    
    var percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition!
    var panGestureRecognizer: UIPanGestureRecognizer!
    // This constraint ties an element at zero points from the bottom layout guide
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    
    var actualPost = imagePost()
    var tmpImage = UIImage(named: "")
    
    var comments: [commentStruct] = []
    
    var originalBottomY = 0
    var originalPostID = ""
    var originalPostAuthorID = ""
    
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    var highlightCommentUID = "" // when opening comment from notifications page
    
    var hasReachedEndOfComments = false
    override func viewDidLoad() {
        super.viewDidLoad()
        print("* fetching comments from posts/\(originalPostAuthorID)/posts/\(originalPostID)/comments")
        Analytics.logEvent("load_comment_section", parameters: [
            "postAuthor": originalPostAuthorID,
          "postId": originalPostID,
          "currentUID": (Auth.auth().currentUser?.uid)!
        ])
//        commentsTableView.delegate = self
//        commentsTableView.dataSource = self
        backButton.setTitle("", for: .normal)
        postButton.setTitle("", for: .normal)
        
        commentsTableView.backgroundColor = .clear
        commentTextField.placeholder = "Comment on \(actualPost.username)'s post" // OR "Reply to username's comment" for comment replies
//        addGesture()
        styleTopAndBottom()
//        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        
        postButton.backgroundColor = hexStringToUIColor(hex: Constants.secondaryColor)
        postButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
//        postButton.titleLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
        postButton.layer.cornerRadius = 12
        
        backButton.frame = CGRect(x: 0, y: 30, width: 50, height: 60)
        backButton.tintColor = .darkGray
        
        
        previewImage.frame = CGRect(x: backButton.frame.maxX+5, y: backButton.frame.minY, width: 48, height: 48)
        previewImage.contentMode = .scaleAspectFill
        previewImage.layer.cornerRadius = 8
        previewImage.image = tmpImage
        
        
        captionTextView.text = actualPost.caption
        captionTextView.frame = CGRect(x: previewImage.frame.maxX+10, y: backButton.frame.minY, width: UIScreen.main.bounds.width - previewImage.frame.maxX - 15, height: 48)
        captionTextView.font = UIFont(name: "\(Constants.globalFont)", size: 13)
        if let prefs = UserDefaults(suiteName: "com.apple.EmojiPreferences") {
                if let defaults = prefs.dictionary(forKey: "EMFDefaultsKey"){
                    if let recents = defaults["EMFRecentsKey"] as? [String]{
//                        emojiList.append(recents)
                        print("* got recent emojis: \(recents)")
                    }
                }
            }
        query = db.collection("posts").document(originalPostAuthorID).collection("posts").document(originalPostID).collection("comments")
                         .order(by: "likes_count", descending: true)
                         .order(by: "createdAt", descending: false)
                         .limit(to: 10)
        commentTableView.dataSource = self
        commentTableView.delegate = self
        fetchComments()
//        hideKeyboardWhenTappedAround()
        commentTableView.keyboardDismissMode = .onDrag
        commentTableView.separatorStyle = .none
//        commentsTableView.hideKeyboardWhenTappedAround()
        // call the 'keyboardWillShow' function when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // call the 'keyboardWillHide' function when the view controlelr receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        commentTableView.rowHeight = CGFloat(120)
        if Constants.isDebugEnabled {
//            var window : UIWindow = UIApplication.shared.keyWindow!
//            window.showDebugMenu()
            self.view.debuggingStyle = true
        }
        commentTableView.frame = CGRect(x: 0, y: topWhiteView.frame.maxY, width: UIScreen.main.bounds.width, height: bottomWhiteView.frame.minY - topWhiteView.frame.maxY + 10)
        commentTableView.showsVerticalScrollIndicator = false
//        hideKeyboardWhenTappedAround()
    }
    @IBAction func postButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let postsRef = db.collection("posts")
        let timestamp = NSDate().timeIntervalSince1970
//        let value: Double = 1
//        let incr = FieldValue.increment(value)
//        postsRef.document(originalPostAuthorID).collection("posts").document(originalPostID).updateData(["comments_count":incr])
        let commentRef = postsRef.document(originalPostAuthorID).collection("posts").document(originalPostID).collection("comments").document()
        let userID : String = (Auth.auth().currentUser?.uid)!
        print("* pushing comment:")
        print("  |_ uid = \(commentRef.documentID)")
        print("  |_ authorID = \(userID)")
        print("  |_ commentText = \(commentTextField.text ?? "")")
        print("  |_ createdAt = \(Int(timestamp))")
        print("  |_ authorProfilePic = \(self.currentUserProfilePic)")
        print("  |_ authorUserName = \(self.currentUserUsername)")
        print("  |_ replies_count = 0")
        print("  |_ likes_count = 0")
        commentRef.setData([
            "uid": "\(commentRef.documentID)",
            "authorID": "\(userID)",
            "commentText": "\(commentTextField.text ?? "")",
            "createdAt": Int(timestamp),
            "authorProfilePic": "\(self.currentUserProfilePic)",
            "authorUserName": "\(self.currentUserUsername)",
            "replies_count": 0,
            "likes_count": 0
        ], merge: true) { err in
            if err == nil {
                print("* successfully commented on post")
                self.dismissKeyboard()
                var newComment = commentStruct()
                newComment.authorID = userID
                newComment.commentID = commentRef.documentID
                newComment.commentText = "\(self.commentTextField.text ?? "")"
                newComment.createdAt = Double(Int(timestamp))
                newComment.authorProfilePic = "\(self.currentUserProfilePic)"
                newComment.authorUserName = "\(self.currentUserUsername)"
                newComment.numberOfReplies = 0
                newComment.numberOfLikes = 0
                
                self.commentTextField.text = ""
                self.comments.insert(newComment, at: 0)
                self.commentTableView.beginUpdates()
                self.commentTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.commentTableView.endUpdates()
            } else {
                print("* looks like there was an error posting comment: \(err)")
//                let value: Double = -1
//                let incr = FieldValue.increment(value)
//                postsRef.document(self.originalPostAuthorID).collection("posts").document(self.originalPostID).updateData(["comments_count":incr])
            }
            
            
            
            
        }
    }
    func fetchComments() {
        print("* fetch comments called")
        query.getDocuments() { (querySnapshot, err) in
            let mainCommentsDispatchGroup = DispatchGroup()
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                querySnapshot!.documents.forEach({ (document) in
                    let data = document.data() as [String: AnyObject]
                    
                    //Setup your data model
                    var postItem = commentStruct()
                    postItem.authorID = data["authorID"] as? String ?? ""
                    postItem.authorProfilePic = data["authorProfilePic"] as? String ?? ""
                    postItem.authorUserName = data["authorUserName"] as? String ?? ""
                    let commID = data["uid"] as? String ?? ""
                    postItem.commentID = commID
                    postItem.commentText = data["commentText"] as? String ?? ""
                    postItem.createdAt = data["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                    postItem.numberOfReplies = data["replies_count"] as? Int ?? 0
                    postItem.numberOfLikes = data["likes_count"] as? Int ?? 0
                    mainCommentsDispatchGroup.enter()
                    print("* checking posts/\(self.originalPostAuthorID)/posts/\(self.originalPostID)/comments/\(commID)/likes/\(Auth.auth().currentUser?.uid ?? "")")
                    self.db.collection("posts").document(self.originalPostAuthorID).collection("posts").document(self.originalPostID).collection("comments").document(commID).collection("likes").whereField("uid", isEqualTo: Auth.auth().currentUser?.uid ?? "").limit(to: 1).getDocuments() { (likesSnapshot, err) in
                        if likesSnapshot!.isEmpty {
                            postItem.isLiked = false
                            print("* user has not liked comment")
                        } else {
                            postItem.isLiked = true
                            print("* comment is liked!")
                        }
                        self.comments += [postItem]
                        
                        mainCommentsDispatchGroup.leave()
                        
                        
                    }
                    self.documents += [document]
                    
                })
                if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                    
                    self.hasReachedEndOfComments = true
                }
                
            }
            mainCommentsDispatchGroup.notify(queue: .main) {
                self.comments = self.comments.sorted (by: {$0.numberOfLikes > $1.numberOfLikes})
                print("* got done working on tasks -- reloading")
                if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                    print("* looks like we've reached the end of comments collection")
                    self.hasReachedEndOfComments = true
                } else {
                    DispatchQueue.main.async {
                        self.commentsTableView.reloadData()
                    }
                }
                
            }
        }
        
    }
    func paginate() {
            //This line is the main pagination code.
            //Firestore allows you to fetch document from the last queryDocument
        query = query.start(afterDocument: documents.last!).limit(to: 4)
        fetchComments()
        }
    @IBAction func goBackPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        navigationController?.delegate = self
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
            
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      
      // move the root view up by the distance of keyboard height
        self.bottomWhiteView.frame.origin.y = CGFloat(originalBottomY) - keyboardSize.height + 20
    }

    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
        self.bottomWhiteView.frame.origin.y = CGFloat(originalBottomY)
    }
    
    func styleTopAndBottom() {
        topWhiteView.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 90)
        self.topWhiteView.layer.masksToBounds = false
        self.topWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.topWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.topWhiteView.layer.shadowOpacity = 0.3
        self.topWhiteView.layer.shadowRadius = Constants.borderRadius
        topLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
        topLabel.text = "\(suffixNumber(number:actualPost.commentCount as NSNumber).replacingOccurrences(of: ".0", with: "")) Comments"
        topLabel.sizeToFit()
        topLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (topLabel.frame.width / 2), y: 50, width: topLabel.frame.width, height: topLabel.frame.height)

        bottomWhiteView.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        bottomWhiteView.layer.cornerRadius = Constants.borderRadius
        bottomWhiteView.clipsToBounds = true
        bottomWhiteView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 140, width: UIScreen.main.bounds.width, height: 140)
        originalBottomY = Int(bottomWhiteView.frame.minY)
        self.bottomWhiteView.layer.masksToBounds = false
        self.bottomWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.bottomWhiteView.layer.shadowOffset = CGSize(width: 0, height: -5)
        self.bottomWhiteView.layer.shadowOpacity = 0.3
        self.bottomWhiteView.layer.shadowRadius = Constants.borderRadius
        
        
        commentTextField.styleSearchBar()
        commentTextField.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        commentTextField.frame = CGRect(x: 15, y: 50, width: UIScreen.main.bounds.width - 30, height: 50)
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        commentTextField.leftView = paddingView
        commentTextField.leftViewMode = .always
        
        let postButtonWidth = 60
        
        let postButtonPadd = 10
        let newWidth = Int(commentTextField.frame.minY) - (2*postButtonPadd)
//        postButton.frame = CGRect(x: Int(commentTextField.frame.maxX) - postButtonWidth - postButtonPadd, y: Int(commentTextField.frame.minY)+postButtonPadd, width: Int(CGFloat(postButtonWidth)), height: Int(commentTextField.frame.minY) - (2*postButtonPadd))
        postButton.frame = CGRect(x: Int(commentTextField.frame.maxX) - newWidth - postButtonPadd, y: Int(commentTextField.frame.minY)+postButtonPadd, width: newWidth, height: newWidth)
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
    func addGesture() {
        
        guard (navigationController?.viewControllers.count)! > 1 else {
            return
        }
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(CommentsViewController.handlePanGesture(_:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    @objc func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
//        if(isBackGestureEnabled && self.slideshow.isCurrentlyFullscreen == false) {
        let percent = max(panGesture.translation(in: view).x, 0) / view.frame.width
        switch panGesture.state {
            
        case .began:
            navigationController?.delegate = self
            _ = navigationController?.popViewController(animated: true)
            
        case .changed:
            if let percentDrivenInteractiveTransition = percentDrivenInteractiveTransition {
                percentDrivenInteractiveTransition.update(percent)
            }
            
        case .ended:
            let velocity = panGesture.velocity(in: view).x
            
            // Continue if drag more than 50% of screen width or velocity is higher than 1000
            if percent > 0.5 || velocity > 1000 {
                percentDrivenInteractiveTransition.finish()
            } else {
                percentDrivenInteractiveTransition.cancel()
            }
            
        case .cancelled, .failed:
            percentDrivenInteractiveTransition.cancel()
            
        default:
            break
        }
        
//        }
    }
    
    
}
extension CommentsViewController: UINavigationControllerDelegate {

//    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//
//        return SlideAnimatedTransitioning()
//    }
//
//    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//
//        navigationController.delegate = nil
//
//        if panGestureRecognizer.state == .began {
//            percentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
//            percentDrivenInteractiveTransition.completionCurve = .easeOut
//        } else {
//            percentDrivenInteractiveTransition = nil
//        }
//
//        return percentDrivenInteractiveTransition
//    }
}
extension UIViewController {

    func presentDetail(_ viewControllerToPresent: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.1
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        self.view.window!.layer.add(transition, forKey: kCATransition)
        
        present(viewControllerToPresent, animated: false)
    }

    func dismissDetail() {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        self.view.window!.layer.add(transition, forKey: kCATransition)

        dismiss(animated: false)
    }
}
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
// Usage: insert view.pushTransition right before changing content
extension UIView {
    func pushTransition(_ duration:CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
                                                            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = CATransitionSubtype.fromTop
        animation.duration = duration
//        layer.add(animation, forKey: kCATransitionPush)
    }
}
extension UILabel {
    func animateUp(count: String) {
        self.pushTransition(0.4)
        self.text = "\(count) Comments"
//        count += 1
    }
}
extension UIButton {
    
    func centerVertically(padding: CGFloat = 6.0) {
        guard
            let imageViewSize = self.imageView?.frame.size,
            let titleLabelSize = self.titleLabel?.frame.size else {
            return
        }
        
        let totalHeight = imageViewSize.height + titleLabelSize.height + padding
        
        self.imageEdgeInsets = UIEdgeInsets(
            top: -(totalHeight - imageViewSize.height),
            left: 0.0,
            bottom: 0.0,
            right: -titleLabelSize.width
        )
        
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: -imageViewSize.width,
            bottom: -(totalHeight - titleLabelSize.height),
            right: 0.0
        )
        
        self.contentEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: titleLabelSize.height,
            right: 0.0
        )
    }
    
}
