//
//  FeedViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 5/15/22.
//

import UIKit
import Foundation
import SwiftKeychainWrapper
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Kingfisher
import SpriteKit
import SkeletonView
import FirebaseAnalytics

class ImagePostTableViewCell: UITableViewCell {
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var firstusernameButton: UIButton!
    @IBOutlet weak var secondusernameButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    
    @IBOutlet weak var viewCommentsButton: UIButton!
    @IBOutlet weak var upperRightShareButton: UIButton!
    @IBOutlet weak var mainPostImage: UIImageView!
    
    @IBOutlet weak var likeButton: HeartButton!
    @IBOutlet weak var commentBubbleButton: CommentButton!
    @IBOutlet weak var shareToUserButton: UIButton!
    @IBOutlet weak var savePostButton: SaveButton!
    
    var postid = ""
    var userID = ""
    var imageHash = ""
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    var isCurrentlySavingData = false
    
    private var db = Firestore.firestore()
    
    var actualPost = imagePost()
    
    func setPostImage(fromUrl: String) {
        let url = URL(string: fromUrl)
        let processor = DownsamplingImageProcessor(size: self.mainPostImage.bounds.size)
        self.mainPostImage.kf.indicatorType = .activity
        self.mainPostImage.kf.setImage(
            with: url,
            placeholder: UIImage(blurHash: imageHash, size: CGSize(width: 32, height: 32)),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.5)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
                self.mainPostImage.contentMode = .scaleAspectFill
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
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
    func styleCell(type: String, hasSubTitle: Bool) {
        if type == "imagePost" {
            self.backgroundColor = .clear
            self.layer.cornerRadius = Constants.borderRadius
            
            // PROFILE IMAGE
            profilePicImage.layer.cornerRadius = 8
            profilePicImage.frame = CGRect(x: 15, y: 15, width: 30, height: 30)
            
            // USERNAME LABEL
            firstusernameButton.contentHorizontalAlignment = .left
            secondusernameButton.contentHorizontalAlignment = .left
            locationButton.contentHorizontalAlignment = .left
            locationButton.contentVerticalAlignment = .top
            
            let shareButtonWidth = 30
            upperRightShareButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - shareButtonWidth - 15, y: Int(profilePicImage.frame.minY), width: shareButtonWidth, height: shareButtonWidth)
            upperRightShareButton.contentMode = .scaleAspectFit
            let extraButtonWidths = Int(self.frame.width) - Int(profilePicImage.frame.maxY) - shareButtonWidth - 20
            if hasSubTitle == true {
                firstusernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: CGFloat(extraButtonWidths), height: 16)
                locationButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: firstusernameButton.frame.maxY, width: CGFloat(extraButtonWidths), height: 30)
            } else {
                firstusernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: CGFloat(extraButtonWidths), height: 16)
                firstusernameButton.center.y = profilePicImage.center.y
            }
            timeSincePostedLabel.frame = CGRect(x: firstusernameButton.frame.minX, y: firstusernameButton.frame.minY, width: UIScreen.main.bounds.width - firstusernameButton.frame.maxX, height: 20)
            timeSincePostedLabel.backgroundColor = .clear

            
            // post image
//            let mainPostWidth = UIScreen.main.bounds.width - 30
//            mainPostImage.contentMode = .scaleAspectFill
//            mainPostImage.frame = CGRect(x: 15, y: profilePicImage.frame.maxY + profilePicImage.frame.minY , width: mainPostWidth, height: mainPostWidth*1.25)
            
            let mainPostWidth = UIScreen.main.bounds.width
            mainPostImage.contentMode = .scaleAspectFill
            mainPostImage.frame = CGRect(x: 0, y: profilePicImage.frame.maxY + profilePicImage.frame.minY , width: mainPostWidth, height: mainPostWidth*1.25)
            

//            let subButtonY = mainPostImage.frame.maxY - 40
            let subButtonY = mainPostImage.frame.maxY + 15
            let subButtonWidths = 30
            

            self.likeButton.frame = CGRect(x: 15, y: Int(subButtonY), width: subButtonWidths, height: 25)
            
            self.commentBubbleButton.frame = CGRect(x: Int(likeButton.frame.maxX) + 10, y: Int(subButtonY), width: subButtonWidths, height: 25)
            self.shareToUserButton.frame = CGRect(x: Int(commentBubbleButton.frame.maxX), y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
//            self.likeButton.addBaseShadow()
            self.likeButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
            self.likeButton.layer.shadowOffset = CGSize(width: 0, height: 3)
            self.likeButton.layer.shadowOpacity = 0.4
            self.likeButton.layer.shadowRadius = 4
            
            self.commentBubbleButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
            self.commentBubbleButton.layer.shadowOffset = CGSize(width: 0, height: 3)
            self.commentBubbleButton.layer.shadowOpacity = 0.4
            self.commentBubbleButton.layer.shadowRadius = 4
            
            self.savePostButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - subButtonWidths - 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            self.secondusernameButton.frame = CGRect(x: 15, y: likeButton.frame.maxY+15, width: 5, height: 5)
//            self.secondusernameButton.backgroundColor = .blue
            
            self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY-2, width: UIScreen.main.bounds.width - 15 - secondusernameButton.frame.maxX, height: 40)
            
            self.viewCommentsButton.frame = CGRect(x: 15, y: captionLabel.frame.maxY+5, width: 5, height: 20)
            self.viewCommentsButton.alpha = 0
            
            
            
            self.mainPostImage.isUserInteractionEnabled = true
            // Single Tap
                let singleTap: UITapGestureRecognizer =  UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
                singleTap.numberOfTapsRequired = 1
            self.mainPostImage.addGestureRecognizer(singleTap)
            let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
                doubleTap.numberOfTapsRequired = 2
            self.mainPostImage.addGestureRecognizer(doubleTap)
            singleTap.require(toFail: doubleTap)
            singleTap.delaysTouchesBegan = true
            doubleTap.delaysTouchesBegan = true
            mainPostImage.layer.cornerRadius = 0
            
//            self.firstusernameButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
//            self.secondusernameButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
            
            likeButton.fadeIn()
            commentBubbleButton.fadeIn()
            upperRightShareButton.fadeIn()
            savePostButton.fadeIn()
        }
    }
    func updateCommentButtonLocation() {
        self.commentBubbleButton.frame = CGRect(x: self.likeButton.frame.maxX + 10, y: self.commentBubbleButton.frame.minY, width: self.commentBubbleButton.frame.width, height: self.commentBubbleButton.frame.height)
    }
    func likeButtonAnimateToRed() {
        self.updateCommentButtonLocation()
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
    func likePost(id: String, author: String) {
        if isCurrentlySavingData == false {
            Analytics.logEvent("like_post", parameters: [
              "postAuthor": userID,
              "postId": id,
              "currentUID": author
            ])
            isCurrentlySavingData = true
        let postsRef = db.collection("posts")
        let timestamp = NSDate().timeIntervalSince1970
//            let value: Double = 1
//            let incr = FieldValue.increment(value)
//
//            postsRef.document(userID).collection("posts").document(id).updateData(["likes_count":incr])
            postsRef.document(userID).collection("posts").document(id).collection("likes").document(author).setData([
            "uid": "\(userID)",
            "likedAtTimeStamp": Int(timestamp)
        ], merge: true) { err in
            print("* successfully liked post")
            self.isCurrentlySavingData = false
        }
        }
    }
    func unlikePost(id: String, author: String) {
        if isCurrentlySavingData == false {
            Analytics.logEvent("unlike_post", parameters: [
              "postAuthor": userID,
              "postId": id,
              "currentUID": author
            ])
            isCurrentlySavingData = true
        let postsRef = db.collection("posts")
        let timestamp = NSDate().timeIntervalSince1970
//        let value: Double = -1
//        let incr = FieldValue.increment(value)
//        postsRef.document(userID).collection("posts").document(id).updateData(["likes_count":incr])
        
        postsRef.document(userID).collection("posts").document(id).collection("likes").document(author).delete() {err in
            print("* done unliking post!")
            self.isCurrentlySavingData = false
        }
        
        }
    }
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if isCurrentlySavingData == false {
            
            print("Double Tap!")
            print("* like button pressed")
            let userIDz : String = (Auth.auth().currentUser?.uid)!
            Analytics.logEvent("double_tap_like_post", parameters: [
                "postAuthor": userID,
              "postId": postid,
              "currentUID": userIDz
            ])
            if self.likeButton.isLiked == false{
                print("* liking post \(postid)")
                likePost(id: postid, author: userIDz)
                
            } else {
                print("* unliking post \(postid)")
                unlikePost(id: postid, author: userIDz)
            }
            likeButtonAnimateToRed()
        }
        
    }
    func showCommentSection() {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
            if let navigator = self.findViewController()?.navigationController {
                vc.actualPost = self.actualPost
                vc.tmpImage = self.mainPostImage.image
                vc.originalPostID = self.postid
                vc.originalPostAuthorID = self.userID
                vc.currentUserUsername = self.currentUserUsername
                vc.currentUserProfilePic = self.currentUserProfilePic
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigator.pushViewController(vc, animated: true)

            }
        }
        
    }
    @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {

        print("Single Tap, presenting comment section")
        showCommentSection()

       }
    @IBAction func likeButtonPressed(_ sender: Any) {
        if isCurrentlySavingData == false {
        print("* like button pressed")
        let userID : String = (Auth.auth().currentUser?.uid)!
        if self.likeButton.isLiked == false{
            print("* liking post \(postid)")
            likePost(id: postid, author: userID)
        } else {
            print("* unliking post \(postid)")
            unlikePost(id: postid, author: userID)
        }
        likeButtonAnimateToRed()
        }
        
    }
    @IBAction func commentButtonPressed(_ sender: Any) {
        showCommentSection()
    }
    
}
struct imagePost {
    var username = ""
    var postID = ""
    var userID = ""
    var imageUrl = ""
    var userImageUrl = ""
    var caption = ""
    var commentCount = 0
    var likesCount = 0
    var savesCount = 0
    var location = ""
    var tags = [""]
    var createdAt = Double(0)
    var imageHash = ""
    var isLiked = false
    var isSaved = false
}
//, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource
class FeedViewController: UIViewController, UITableViewDelegate, SkeletonTableViewDataSource {
    
    weak open var prefetchDataSource: UITableViewDataSourcePrefetching?
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "ImagePostCell"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imagePosts?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImagePostCell", for: indexPath) as! ImagePostTableViewCell
        
        let post = imagePosts?[indexPath.row]
        if post?.location == "" {
            cell.styleCell(type: "imagePost", hasSubTitle: false)
        } else {
            cell.styleCell(type: "imagePost", hasSubTitle: true)
        }
        
        cell.firstusernameButton.setTitle(post?.username, for: .normal)
        cell.secondusernameButton.setTitle(post?.username, for: .normal)
        cell.firstusernameButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        cell.secondusernameButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        cell.viewCommentsButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)", size: 14)
        cell.captionLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
        cell.currentUserUsername = self.currentUserUsername
        cell.currentUserProfilePic = self.currentUserProfilePic
        cell.captionLabel.text = "\(post?.username ?? "")  \(post?.caption ?? "")"
        cell.timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
        let timeSince = Date(timeIntervalSince1970: TimeInterval(post?.createdAt ?? 0)).timeAgoDisplay()
        cell.timeSincePostedLabel.text = "\(post?.username ?? "")  • \(timeSince)"
        cell.firstusernameButton.sizeToFit()
        cell.firstusernameButton.frame = CGRect(x: cell.firstusernameButton.frame.minX, y: cell.firstusernameButton.frame.minY, width: cell.firstusernameButton.frame.width, height: 14)
        
        cell.actualPost = post!
        
        cell.timeSincePostedLabel.frame = CGRect(x: cell.firstusernameButton.frame.minX, y: cell.firstusernameButton.frame.minY, width: UIScreen.main.bounds.width - 30 - cell.firstusernameButton.frame.maxX, height: 14)
        let hash = post?.imageHash ?? ""
        print("* using image hash \(hash)")
        
        cell.likeButton.setDefaultImage()
        cell.likeButton.contentMode = .scaleAspectFit
        cell.likeButton.imageView?.contentMode = .scaleAspectFit
        if ((post?.isLiked) != nil) && post?.isLiked == true {
            cell.likeButton.setImage(cell.likeButton.likedImage, for: .normal)
            cell.likeButton.isLiked = true
        }
        cell.likeButton.setNewLikeAmount(to: post?.likesCount ?? 0)
        
        cell.updateCommentButtonLocation()
        
        cell.commentBubbleButton.setDefaultImage()
        cell.commentBubbleButton.contentMode = .scaleAspectFit
        cell.commentBubbleButton.imageView?.contentMode = .scaleAspectFit
//        if ((post?.isLiked) != nil) && post?.isLiked == true {
//            cell.likeButton.setImage(cell.likeButton.likedImage, for: .normal)
//            cell.likeButton.isLiked = true
//        }
        cell.commentBubbleButton.setNewLikeAmount(to: post?.commentCount ?? 0)
        
        cell.savePostButton.setDefaultImage()
        cell.savePostButton.contentMode = .scaleAspectFit
        cell.savePostButton.imageView?.contentMode = .scaleAspectFit
        if ((post?.isSaved) != nil) && post?.isSaved == true {
            cell.savePostButton.setImage(cell.savePostButton.likedImage, for: .normal)
            cell.savePostButton.isLiked = true
        }
        
        let hashedImage = UIImage(blurHash: hash, size: CGSize(width: 32, height: 32))
        cell.imageHash = hash
        cell.mainPostImage.image = hashedImage
        cell.setPostImage(fromUrl: post!.imageUrl)
        cell.setUserImage(fromUrl: post!.userImageUrl)
//        cell.mainPostImage.layer.cornerRadius = 8
        cell.locationButton.setTitle(post?.location, for: .normal)
        cell.viewCommentsButton.setTitle("View \(post?.commentCount ?? 0) comments", for: .normal)
        cell.postid = post!.postID
        cell.userID = post!.userID
        cell.viewCommentsButton.sizeToFit()
        cell.secondusernameButton.sizeToFit()
        cell.secondusernameButton.backgroundColor = self.view.backgroundColor
        cell.secondusernameButton.frame = CGRect(x: cell.secondusernameButton.frame.minX, y: cell.secondusernameButton.frame.minY, width: cell.secondusernameButton.frame.width, height: 14)
        
//        cell.likeButton.tintColor = UIColor.black
        cell.likeButton.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        cell.likeButton.layer.cornerRadius = 8
        
        cell.commentBubbleButton.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        cell.commentBubbleButton.layer.cornerRadius = 8
        
        cell.firstusernameButton.backgroundColor = cell.secondusernameButton.backgroundColor
        
        
        
        
        cell.selectionStyle = .none
        cell.backgroundColor = self.view.backgroundColor
//        cell.layer.cornerRadius = 12
        cell.clipsToBounds = true
        
        print("new post loading in: \(post!.postID)")
        return cell
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    let defaults = UserDefaults.standard
    
   
    @IBOutlet weak var storiesCollectionView: UICollectionView!
    @IBOutlet weak var postsTableView: UITableView!
    @IBOutlet weak var topGradientView: UIView!
    
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var MessagesButton: UIButton!
    @IBOutlet weak var addPostButton: UIButton!
    
    var imagePosts: [imagePost]? = []
    
    let queryCursor = 0 //used for pagination, where to start at
    private var db = Firestore.firestore()
    
    var hasReachedEndOfFeed = false
    
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        
        topWhiteView.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 90)
        self.topWhiteView.layer.masksToBounds = false
        self.topWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.topWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.topWhiteView.layer.shadowOpacity = 0.3
        self.topWhiteView.layer.shadowRadius = Constants.borderRadius
        
        addPostButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        addPostButton.frame = CGRect(x: 15, y: 45, width: 47, height: 35)
        
//        MessagesButton.addBaseShadow()
//        MessagesButton.layer.cornerRadius = Constants.borderRadius
        MessagesButton.frame = CGRect(x: UIScreen.main.bounds.width - 40 - 20, y: 45, width: 47, height: 35)
        MessagesButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
//        MessagesButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
//        MessagesButton.backgroundColor = hexStringToUIColor(hex: Constants.secondaryColor)
        
        postsTableView.delegate = self
        postsTableView.dataSource = self
        postsTableView.rowHeight = 700
        postsTableView.backgroundColor = .clear
        postsTableView.frame = CGRect(x: 0, y: 90, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 120)
        postsTableView.showsVerticalScrollIndicator = false
        
        topGradientView.frame = CGRect(x: 0, y: postsTableView.frame.minY, width: UIScreen.main.bounds.width, height: 40)
        topGradientView.alpha = 0
        postsTableView.separatorStyle = .none
        
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        let backButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        
        if Auth.auth().currentUser?.uid == nil {
        } else {
//            getPosts()
            let userID = Auth.auth().currentUser?.uid
            let followersRef = db.collection("followers")
            query = followersRef.whereField("followers", arrayContains: userID!).order(by: "last_post", descending: true).limit(to: 3)
//            print("* checking sub-followers/\()")
//            query = db.collectionGroup("sub-followers").whereField("uid", isEqualTo: userID ?? "").limit(to: 3)
            getPosts()
        }
        if Constants.isDebugEnabled {
            var window : UIWindow = UIApplication.shared.keyWindow!
            window.showDebugMenu()
        }
        
        postsTableView.isSkeletonable = true
        postsTableView.showAnimatedSkeleton(usingColor: .clouds, transition: .crossDissolve(0.25))
    }
    func getDocumentSize(data: [String : Any]) -> Int{
            
            var size = 0
            
            for (k, v) in  data {
                
                size += k.count + 1
                
                if let map = v as? [String : Any]{
                    size += getDocumentSize(data: map)
                } else if let array = v as? [String]{
                    for a in array {
                        size += a.count + 1
                    }
                } else if let s = v as? String{
                    size += s.count + 1
                }
        
            }
            
            return size + 100 //add 100 for document ID and what not
            
        }
    func getPosts() {
//        imagePosts = []
        //load next 5 posts + ad
        let userID = Auth.auth().currentUser?.uid
//        let groupsFollowersRef = db.collection("groups").document("followers").
        query.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let mainPostDispatchQueue = DispatchGroup()
                if querySnapshot!.isEmpty {
                    print("* detected empty feed")
                } else {
                    print("* posts returned: \(querySnapshot)")
                    mainPostDispatchQueue.enter()
                    for document in querySnapshot!.documents {
//                        print("* got feed: \(document.documentID) => \(document.data())")
                        let useID = document.documentID
                        let values = document.data()
                        mainPostDispatchQueue.enter()
                        self.documents += [document]
                        let last_post = (values["last_post"] as? [String: Any])?["id"] as! String
                        var post = Egg_.imagePost()
                        post.userID = useID
//                        print("* got post id: \(last_post)")
                        
                        // get more info on post based on post id and user id
                        self.db.collection("posts").document(useID).collection("posts").document(last_post).getDocument() {(postResult, err2) in
                            if let err2 = err2 {
                                print("Error getting documents: \(err2)")
                            } else {
                                let postVals = postResult?.data() as? [String: Any]
//                                print("got post details: \(postVals)")
                                print("* post size estimation: \(self.getDocumentSize(data: postVals!))")
                                post.postID = last_post
                                post.commentCount = postVals?["comments_count"] as? Int ?? 0 // fix this
                                post.likesCount = postVals?["likes_count"] as? Int ?? 0
                                post.imageUrl = postVals?["postImageUrl"] as? String ?? ""
                                post.location = postVals?["location"] as? String ?? ""
                                post.caption = postVals?["caption"] as? String ?? ""
                                post.tags = postVals?["tags"] as? [String] ?? [""]
                                post.createdAt = postVals?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                                post.imageHash = postVals?["imageHash"] as? String ?? ""
                                self.db.collection("posts").document(useID).collection("posts").document(last_post).collection("likes").whereField("uid", isEqualTo: userID!).limit(to: 1).getDocuments() { (likesSnapshot, err) in
                                    if likesSnapshot!.isEmpty {
                                        print("* user has not liked post")
                                    } else {
                                        post.isLiked = true
                                        print("* post is liked!")
                                    }
                                    // get more info on user (maybe story?)
                                    self.db.collection("user-locations").document(useID).getDocument() {(userResult, err3) in
                                        if let err3 = err3 {
                                            print("Error getting documents: \(err3)")
                                        } else {
                                            let userVals = userResult?.data() as? [String: Any]
    //                                        print("got more info on the user: \(userVals)")
                                            post.userImageUrl = userVals?["profileImageURL"] as? String ?? ""
                                            post.username = userVals?["username"] as? String ?? ""
                                            self.imagePosts?.append(post)
                                            mainPostDispatchQueue.leave()
                                            if querySnapshot!.documents.last == document {
    //                                            print("reached end of document list, refreshing tableview")
                                                self.db.collection("user-locations").document(Auth.auth().currentUser!.uid).getDocument() {(currentUserResult, err4) in
                                                    let currentuserVals = userResult?.data() as? [String: Any]
                                                    self.currentUserUsername = currentuserVals?["username"] as? String ?? ""
                                                    self.currentUserProfilePic = currentuserVals?["profileImageURL"] as? String ?? ""
                                                    
                                                    mainPostDispatchQueue.leave()
                                                }
                                                
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        
                    }
                    
                }
                mainPostDispatchQueue.notify(queue: .main) {
                    self.imagePosts = self.imagePosts!.sorted (by: {$0.createdAt > $1.createdAt})
                    print("* resorted posts from Higher createdAt to lower: \(self.imagePosts)")
                    if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                        print("* looks like we've reached the end of comments collection")
                        self.hasReachedEndOfFeed = true
                    } else {
                        DispatchQueue.main.async {
                            self.postsTableView.stopSkeletonAnimation()
                            self.view.hideSkeleton(reloadDataAfter: true, transition: .crossDissolve(0.25))
                            self.postsTableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            // Trigger pagination when scrolled to last cell
        // Feel free to adjust when you? want pagination to be triggered
        if (indexPath.row == (imagePosts?.count ?? 1) - 1) && hasReachedEndOfFeed == false {
                
            print("* fetching more comments. Current comment count: \((imagePosts?.count ?? 1)-1)")
                paginate()
            }
        }
    func paginate() {
            //This line is the main pagination code.
            //Firestore allows you to fetch document from the last queryDocument
        query = query.start(afterDocument: documents.last!).limit(to: 3)
        getPosts()
    }
    func addStoriesListener() {
        db.collection("stories").whereField("state", isEqualTo: "CA")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let cities = documents.map { $0["name"]! }
                print("Current cities in CA: \(cities)")
            }
    }
    let interactor = Interactor()

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser?.uid == nil {
//            // show login view
            print("not valid user, pushing login")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            vc.modalPresentationStyle = .fullScreen
            self.parent!.present(vc, animated: true)
        } else {
//            InitialGetPosts()
        }
//        logout()
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
}
func logout() {
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
    }
}
extension UIView {
    func addBaseShadow() {
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = Constants.borderRadius
        self.clipsToBounds = true
        self.layer.borderColor = UIColor.clear.cgColor
    }
    func addShadowWith(color: CGColor, offset: CGSize, opacity: Float) {
        self.layer.shadowColor = color
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = Constants.borderRadius
        self.clipsToBounds = true
    }
}
extension FeedViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))

        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day

        if secondsAgo < minute {
            if secondsAgo == 1 {
                return "\(secondsAgo) second ago"
            } else {
                return "\(secondsAgo) seconds ago"
            }
            
        } else if secondsAgo < hour {
            if secondsAgo / minute == 1 {
                return "\(secondsAgo / minute) minute ago"
            } else {
                return "\(secondsAgo / minute) minutes ago"
            }
            
        } else if secondsAgo < day {
            if secondsAgo / hour == 1 {
                return "\(secondsAgo / hour) hour ago"
            } else {
                return "\(secondsAgo / hour) hours ago"
            }
            
        } else if secondsAgo < week {
            if secondsAgo / day == 1 {
                return "\(secondsAgo / day) day ago"
            } else {
                return "\(secondsAgo / day) days ago"
            }
        }
        if secondsAgo / week == 1 {
            return "\(secondsAgo / week) week ago"
        } else {
            return "\(secondsAgo / week) weeks ago"
        }
        
    }
    func simplifiedTimeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))

        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day

        if secondsAgo < minute {
            return "\(secondsAgo)s"
            
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)m"
            
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)h"
            
        } else if secondsAgo < week {
            return "\(secondsAgo / day)d"
        }
        return "\(secondsAgo / week)w"
    }
}
