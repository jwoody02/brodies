//
//  PostsViewer.swift
//  Egg.
//
//  Created by Jordan Wood on 7/30/22.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import FirebaseAnalytics

class PostsViewerViewController: UIViewController {
    @IBOutlet weak var profilePicImage: IGStoryButton!
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
    @IBOutlet weak var shareToUserButton: ShareUserButton!
    @IBOutlet weak var savePostButton: SaveButton!
    
    @IBOutlet weak var viewLikesView: UIView! // contained for # of likes + profile pics and usernames
    @IBOutlet weak var likesLabel: UILabel! // label that'll contain likes count and usernames if applicable
    @IBOutlet weak var profilePicView1: UIImageView! // imageview1 that'll contain profile pic
    @IBOutlet weak var profilePicView2: UIImageView! // imageview2 that'll contain profile pic
    @IBOutlet weak var profilePicView3: UIImageView! // imageview3 that'll contain profile pic
    
    @IBOutlet weak var tmpImageview: UIImageView! // just used for skeleton views
    @IBOutlet weak var tmpViewLikesButton: UIButton! // just used to listen for view likes click
    
    @IBOutlet weak var tmpRightArrow: UIButton!
    @IBOutlet weak var otherLikesbutton: UIButton!
    
    @IBOutlet weak var HolderView: UIView!
    
    var postid = ""
    var userID = ""
    var imageHash = ""
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    var otherLikesCount = 0
    var isCurrentlySavingData = false
    let shouldMakeRed = true
    
    private var db = Firestore.firestore()
    
    var uidsOfLikes: [String] = []
    
    var actualPost = imagePost()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HolderView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
    }
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
        otherLikesbutton.isHidden = true
        profilePicView1.isHidden = true
        profilePicView2.isHidden = true
        profilePicView3.isHidden = true
        if type == "imagePost" {
            self.view.backgroundColor = .clear
//            self.layer.cornerRadius = Constants.borderRadius
            
            // PROFILE IMAGE
            profilePicImage.layer.cornerRadius = 8
            profilePicImage.frame = CGRect(x: 15, y: 7, width: 40, height: 40)
            
            // USERNAME LABEL
            firstusernameButton.contentHorizontalAlignment = .left
            secondusernameButton.contentHorizontalAlignment = .left
            locationButton.contentHorizontalAlignment = .left
            locationButton.contentVerticalAlignment = .top
            
            let shareButtonWidth = 30
            upperRightShareButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - shareButtonWidth - 15, y: Int(profilePicImage.frame.minY), width: shareButtonWidth, height: shareButtonWidth)
            upperRightShareButton.contentMode = .scaleAspectFit
            let extraButtonWidths = Int(self.view.frame.width) - Int(profilePicImage.frame.maxY) - shareButtonWidth - 20
            if hasSubTitle == true {
                firstusernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY + 4, width: CGFloat(extraButtonWidths), height: 16)
                locationButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: firstusernameButton.frame.maxY, width: CGFloat(extraButtonWidths), height: 30)
            } else {
                firstusernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: CGFloat(extraButtonWidths), height: 16)
                firstusernameButton.center.y = profilePicImage.center.y
            }
            locationButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 13)
            timeSincePostedLabel.frame = CGRect(x: firstusernameButton.frame.minX, y: firstusernameButton.frame.minY, width: UIScreen.main.bounds.width - firstusernameButton.frame.maxX, height: 20)
            timeSincePostedLabel.backgroundColor = .clear

            
            // post image
//            let mainPostWidth = UIScreen.main.bounds.width - 30
//            mainPostImage.contentMode = .scaleAspectFill
//            mainPostImage.frame = CGRect(x: 15, y: profilePicImage.frame.maxY + profilePicImage.frame.minY , width: mainPostWidth, height: mainPostWidth*1.25)
            
            let mainPostWidth = UIScreen.main.bounds.width
            mainPostImage.contentMode = .scaleAspectFill
            mainPostImage.frame = CGRect(x: 0, y: profilePicImage.frame.maxY + 15 , width: mainPostWidth, height: mainPostWidth*1.25)
            

//            let subButtonY = mainPostImage.frame.maxY - 40
            let subButtonY = mainPostImage.frame.maxY + 10
            let subButtonWidths = 30
            

            self.likeButton.frame = CGRect(x: 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
//            self.likeButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
//            self.likeButton.layer.shadowOffset = CGSize(width: 0, height: 3)
//            self.likeButton.layer.shadowOpacity = 0.4
//            self.likeButton.layer.shadowRadius = 4
            
            self.commentBubbleButton.frame = CGRect(x: Int(likeButton.frame.maxX) + 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            self.shareToUserButton.frame = CGRect(x: Int(commentBubbleButton.frame.maxX) + 9, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            
            
//            self.commentBubbleButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
//            self.commentBubbleButton.layer.shadowOffset = CGSize(width: 0, height: 3)
//            self.commentBubbleButton.layer.shadowOpacity = 0.4
//            self.commentBubbleButton.layer.shadowRadius = 4
            
            self.savePostButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - subButtonWidths - 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            
            
            
            
            self.mainPostImage.isUserInteractionEnabled = true
            // Single Tap
//                let singleTap: UITapGestureRecognizer =  UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
//                singleTap.numberOfTapsRequired = 1
//            self.mainPostImage.addGestureRecognizer(singleTap)
            let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
                doubleTap.numberOfTapsRequired = 2
            self.mainPostImage.addGestureRecognizer(doubleTap)
//            singleTap.require(toFail: doubleTap)
//            singleTap.delaysTouchesBegan = true
            doubleTap.delaysTouchesBegan = true
            mainPostImage.layer.cornerRadius = 0
            
//            self.firstusernameButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
//            self.secondusernameButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
            
            likeButton.fadeIn()
            commentBubbleButton.fadeIn()
            upperRightShareButton.fadeIn()
            savePostButton.fadeIn()
            shareToUserButton.fadeIn()
                
            viewLikesView.frame = CGRect(x: 15, y: likeButton.frame.maxY + 10, width: 200, height: 40)
            styleForUnLikedBigView()
            viewLikesView.fadeIn()
            
            if actualPost.likesCount == 1 {
                likesLabel.text = "\(actualPost.likesCount.delimiter) like"
            } else {
                likesLabel.text = "\(actualPost.likesCount.delimiter) likes"
            }
            likesLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 16)
            likesLabel.textColor = .black
            print("* received profile pics: \(actualPost.previewProfilePics)")
            
            likesLabel.frame = CGRect(x: 15, y: 5, width: 0, height: 0)
            likesLabel.sizeToFit()
            likesLabel.frame = CGRect(x: 15, y: 0, width: self.likesLabel.frame.width, height: viewLikesView.frame.height)
            tmpRightArrow.frame = CGRect(x: likesLabel.frame.maxX + 5, y: 1, width: 20, height: viewLikesView.frame.height)
            self.viewLikesView.frame = CGRect(x: self.viewLikesView.frame.minX, y: self.viewLikesView.frame.minY, width: self.tmpRightArrow.frame.maxX + 5, height: self.viewLikesView.frame.height)
            
            let profWidthheight = 25
            let profY = self.viewLikesView.frame.maxY + 8
            profilePicView1.frame = CGRect(x: 15, y: self.viewLikesView.frame.maxY, width: 0, height: 0)
            
            var likesString = ""
            if actualPost.previewProfilePics.count == 0 {
                
            } else if actualPost.previewProfilePics.count == 1 {
                print("* creating profile pic")
                profilePicView1.styleForMiniProfilePic()
                profilePicView1.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView2.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView3.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                handleProfileUrl(url: actualPost.previewProfilePics[0], forIndex: 0)
                
                
            } else if actualPost.previewProfilePics.count == 2 {
                profilePicView1.styleForMiniProfilePic()
                profilePicView1.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView2.styleForMiniProfilePic()
                profilePicView2.frame = CGRect(x: Int(profilePicView1.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView3.frame = CGRect(x: Int(profilePicView1.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                
                handleProfileUrl(url: actualPost.previewProfilePics[0], forIndex: 0)
                handleProfileUrl(url: actualPost.previewProfilePics[1], forIndex: 1)
                
                
            } else {
                profilePicView1.styleForMiniProfilePic()
                profilePicView1.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView2.styleForMiniProfilePic()
                profilePicView2.frame = CGRect(x: Int(profilePicView1.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView3.styleForMiniProfilePic()
                profilePicView3.frame = CGRect(x: Int(profilePicView2.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                
                handleProfileUrl(url: actualPost.previewProfilePics[0], forIndex: 0)
                handleProfileUrl(url: actualPost.previewProfilePics[1], forIndex: 1)
                handleProfileUrl(url: actualPost.previewProfilePics[2], forIndex: 2)
            }
            if actualPost.numOfLikeMindedLIkes > 1 {
                likesString = "liked by \(actualPost.usernameToShow) + \(actualPost.numOfLikeMindedLIkes - 1) more"
                otherLikesbutton.fadeIn()
            } else if actualPost.numOfLikeMindedLIkes != 0 {
                likesString = "liked by \(actualPost.usernameToShow)"
                otherLikesbutton.fadeIn()
            }
            print("* using string: \(likesString)")
            otherLikesbutton.setTitle(likesString, for: .normal)
            otherLikesbutton.frame = CGRect(x: profilePicView3.frame.maxX + 5, y: profilePicView1.frame.minY, width: UIScreen.main.bounds.width - profilePicView3.frame.maxX - 15 - 15, height: profilePicView3.frame.height)
            otherLikesbutton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 13)
            otherLikesbutton.isHidden = false
            tmpViewLikesButton.frame = CGRect(x: 0, y: 0, width: self.viewLikesView.frame.width, height: self.viewLikesView.frame.height)
            
            self.secondusernameButton.frame = CGRect(x: 15, y: profilePicView1.frame.maxY+10, width: 5, height: 5)
            
//            self.secondusernameButton.backgroundColor = .blue
            captionLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
            captionLabel.text = "\(actualPost.username)  \(actualPost.caption)"
            self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY-2, width: UIScreen.main.bounds.width - 15 - secondusernameButton.frame.maxX, height: 40)
//            self.captionLabel.addTrailing(with: "... ", moreText: "more", moreTextFont: captionLabel.font, moreTextColor: .lightGray)
            
            self.viewCommentsButton.frame = CGRect(x: 15, y: captionLabel.frame.maxY+5, width: 5, height: 20)
            self.viewCommentsButton.alpha = 1
            self.viewCommentsButton.layer.cornerRadius = 8
            self.viewCommentsButton.backgroundColor = Constants.secondaryColor.hexToUiColor()
            self.viewCommentsButton.tintColor = Constants.primaryColor.hexToUiColor()
            viewCommentsButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 15)
            self.viewCommentsButton.setTitle("\(actualPost.commentCount.delimiter) Comments", for: .normal)
            self.viewCommentsButton.titleLabel?.textColor = viewCommentsButton.tintColor
            viewCommentsButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
            viewCommentsButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            viewCommentsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
            self.viewCommentsButton.sizeToFit()
            viewCommentsButton.frame = CGRect(x: viewCommentsButton.frame.minX, y: viewCommentsButton.frame.minY, width: viewCommentsButton.frame.width + 25, height: viewCommentsButton.frame.height + 5)
            
            tmpRightArrow.tintColor = .lightGray
            
            if shouldMakeRed && actualPost.isLiked {
//                self.viewLikesView.backgroundColor = hexStringToUIColor(hex: Constants.universalRed)
//                self.likesLabel.textColor = .white
                styleForLikedBigView()
                tmpRightArrow.tintColor = .white
            }
        }
    }
    func handleProfileUrl(url: String, forIndex: Int) {
        if url == "" {
            if forIndex == 0 {
                profilePicView1.image = UIImage(named: "no-profile-img.jpeg")
            } else if forIndex == 1 {
                profilePicView2.image = UIImage(named: "no-profile-img.jpeg")
            } else if forIndex == 2 {
                profilePicView3.image = UIImage(named: "no-profile-img.jpeg")
            }
        } else {
            putProfileImage(url: url, intoIndex: forIndex)
        }
    }
    func updateCommentButtonLocation() {
        self.commentBubbleButton.frame = CGRect(x: self.likeButton.frame.maxX + 10, y: self.commentBubbleButton.frame.minY, width: self.commentBubbleButton.frame.width, height: self.commentBubbleButton.frame.height)
    }
    func likeButtonAnimateToRed() {
//        self.updateCommentButtonLocation()
//        if self.likeButton.isLiked {
//            self.likeButton.setNewLikeAmount(to: self.likeButton.likesCount - 1)
//            self.likeButton.sizeToFit()
//        } else {
//            self.likeButton.setNewLikeAmount(to: self.likeButton.likesCount + 1)
//            self.likeButton.sizeToFit()
//        }
        self.likeButton.flipLikedState()
        makeBigOlLikesViewRed()
        let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
    }
    func animateUpLikes() {
        UIView.animate(withDuration: 0.1, animations: {
            let newScale = 1.3
            self.viewLikesView.transform = self.viewLikesView.transform.scaledBy(x: newScale, y: newScale)
        }, completion: { _ in
          UIView.animate(withDuration: 0.1, animations: {
              self.viewLikesView.transform = CGAffineTransform.identity
              
          })
            
        })
    }
    func styleForLikedBigView() {
        self.viewLikesView.layer.shadowColor = Constants.universalRed.hexToUiColor().withAlphaComponent(0.7).cgColor
        self.viewLikesView.layer.shadowOffset = CGSize(width: 2, height: 4)
        self.viewLikesView.layer.shadowOpacity = 0.4
        self.viewLikesView.layer.shadowRadius = 4
        self.viewLikesView.layer.cornerRadius = 8
        self.viewLikesView.backgroundColor = Constants.universalRed.hexToUiColor()
        self.likesLabel.textColor = .white
    }
    func styleForUnLikedBigView() {
        self.viewLikesView.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        self.viewLikesView.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.viewLikesView.layer.shadowOpacity = 0.4
        self.viewLikesView.layer.shadowRadius = 4
        self.viewLikesView.layer.cornerRadius = 8
        self.viewLikesView.backgroundColor = hexStringToUIColor(hex: "#e8e8e8")
        self.likesLabel.textColor = .black
    }
    func makeBigOlLikesViewRed() {
        
        print("* should make red!")
        let originalLikesLabelX = self.likesLabel.frame.minX
        print("* is liked button liked: \(self.likeButton.isLiked)")
        let currentval = (likesLabel.text?.replacingOccurrences(of: " likes", with: "") ?? "0").replacingOccurrences(of: " like", with: "").replacingOccurrences(of: ",", with: "")
        if self.likeButton.isLiked {
            if shouldMakeRed {
                styleForLikedBigView()
            }
            self.tmpRightArrow.tintColor = .white
            likesLabel.pushScrollingTransitionUp(0.2) // Invoke before changing content
            likesLabel.text = "\(((Int(currentval) ?? 0) + 1).delimiter) likes" // roundedWithAbbreviations if want k/M for likes
//            animateUpLikes()
        } else {
            styleForUnLikedBigView()
            self.tmpRightArrow.tintColor = .lightGray
            likesLabel.pushScrollingTransitionDown(0.2) // Invoke before changing content
            likesLabel.text = "\(((Int(currentval) ?? 1) - 1).delimiter) likes" // roundedWithAbbreviations if want k/M for likes
//            animateDownLikes()
        }
        
        
        likesLabel.sizeToFit()
        likesLabel.frame = CGRect(x: originalLikesLabelX, y: 0, width: self.likesLabel.frame.width, height: viewLikesView.frame.height)
//        self.viewLikesView.frame = CGRect(x: self.viewLikesView.frame.minX, y: self.viewLikesView.frame.minY, width: self.likesLabel.frame.maxX + 15, height: self.viewLikesView.frame.height)
        self.viewLikesView.frame = CGRect(x: self.viewLikesView.frame.minX, y: self.viewLikesView.frame.minY, width: self.tmpRightArrow.frame.maxX + 5, height: self.viewLikesView.frame.height)
    }
    
    @IBAction func viewLikesTapped(_ sender: Any) {
        openLikesList(authorID: actualPost.userID, numLikes: actualPost.likesCount, postID: actualPost.postID)
    }
    
    func openLikesList(authorID: String, numLikes: Int, postID: String) {
        print("* open likes list")
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userListViewController") as? userListViewController {
            vc.userConfig = userListConfig(type: "likes", originalAuthorID: authorID, postID: postID, numberToPutInFront: numLikes)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            self.navigationController?.pushViewController(vc, animated: true)
        }
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
            let userIDz = Auth.auth().currentUser?.uid
//            postsRef.document(userID).collection("posts").document(id).updateData(["likes_count":incr])
            self.db.collection("user-locations").document(userIDz!).getDocument { (document, err) in
                print("* doc: \(document)")
                if ((document?.exists) != nil) && document?.exists == true {
                    let data = document?.data()! as! [String: AnyObject]
                    let usrname = data["username"] as? String ?? ""
                    postsRef.document(self.userID).collection("posts").document(id).collection("likes").document(userIDz!).setData([
                    "uid": "\(author)",
                    "likedAtTimeStamp": Int(timestamp),
                    "username":usrname
                ], merge: true) { err in
                    print("* successfully liked post")
                    self.isCurrentlySavingData = false
                }
                }
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
    func showCommentSection(shouldSetFirstResponder: Bool = false) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
//            if let navigator = self.findViewController()?.navigationController {
                vc.actualPost = self.actualPost
                vc.tmpImage = self.mainPostImage.image
                vc.originalPostID = self.postid
                vc.originalPostAuthorID = self.userID
                vc.currentUserUsername = self.currentUserUsername
                vc.currentUserProfilePic = self.currentUserProfilePic
                if shouldSetFirstResponder {
                    vc.commentTextField.becomeFirstResponder()
                }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            navigationController?.pushViewController(vc, animated: true)

//            }
        }
        
    }
    @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {

        print("Single Tap, presenting comment section")
        showCommentSection()

       }
    func openProfileForUser(withUID: String) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
                vc.uidOfProfile = withUID
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            navigationController?.pushViewController(vc, animated: true)

        }
    }
    @IBAction func userNameButtonTapped(_ sender: Any) {
        openProfileForUser(withUID: actualPost.userID)
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
    func putProfileImage(url: String, intoIndex: Int) {
        guard let url = URL.init(string: url) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        let processor = DownsamplingImageProcessor(size: CGSize(width: profilePicView1.frame.width, height: profilePicView1.frame.height))
        KingfisherManager.shared.retrieveImage(with: resource, options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .cacheOriginalImage
        ], progressBlock: nil) { result in
            switch result {
            case .success(let value):
                if intoIndex == 0 {
                    self.profilePicView1.image = value.image
                    self.profilePicView1.alpha = 0
                    self.profilePicView1.isHidden = false
                    self.profilePicView1.fadeIn()
                } else if intoIndex == 1 {
                    self.profilePicView2.image = value.image
                    self.profilePicView2.alpha = 0
                    self.profilePicView2.isHidden = false
                    self.profilePicView2.fadeIn()
                } else if intoIndex == 2 {
                    self.profilePicView3.image = value.image
                    self.profilePicView3.alpha = 0
                    self.profilePicView3.isHidden = false
                    self.profilePicView3.fadeIn()
                }
                
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
                self.profilePicImage.alpha = 0
                self.profilePicImage.isHidden = false
                self.profilePicImage.fadeIn()
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
