//
//  PhotoZoomViewController.swift
//  FluidPhoto
//
//  Created by Masamichi Ueta on 2016/12/23.
//  Copyright © 2016 Masmichi Ueta. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics
import Zoomy

protocol PhotoZoomViewControllerDelegate: class {
    func photoZoomViewController(_ photoZoomViewController: PhotoZoomViewController, scrollViewDidScroll scrollView: UIScrollView)
}

class PhotoZoomViewController: UIViewController {
    
    @IBOutlet weak var mainPostImage: UIImageView!
    @IBOutlet weak var profilePicImage: IGStoryButton!
    @IBOutlet weak var firstusernameButton: UIButton!
    @IBOutlet weak var secondusernameButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    
    @IBOutlet weak var viewCommentsButton: UIButton!
    @IBOutlet weak var upperRightShareButton: UIButton!
    
    
    @IBOutlet weak var likeButton: HeartButton!
    @IBOutlet weak var commentBubbleButton: CommentButton!
    @IBOutlet weak var shareToUserButton: ShareUserButton!
    @IBOutlet weak var savePostButton: SaveButton!
    
    @IBOutlet weak var viewLikesView: UIView! // contained for # of likes + profile pics and usernames
    
    @IBOutlet weak var likesLabel: UILabel! // label that'll contain likes count and usernames if applicable
    @IBOutlet weak var tmpViewLikesButton: UIButton! // just used to listen for view likes click
    
    @IBOutlet weak var tmpRightArrow: UIButton!
    @IBOutlet weak var otherLikesbutton: UIButton!
    @IBOutlet weak var profilePicView1: UIImageView! // imageview1 that'll contain profile pic
    @IBOutlet weak var profilePicView2: UIImageView! // imageview2 that'll contain profile pic
    @IBOutlet weak var profilePicView3: UIImageView! // imageview3 that'll contain profile pic
    
    weak var delegate: PhotoZoomViewControllerDelegate?
    
    var image: UIImage!
    var actualPost = imagePost()
    var postIndex: Int = 0
    private var db = Firestore.firestore()
    var postid = ""
    var userID = ""
    var imageHash = ""
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    var otherLikesCount = 0
    var isCurrentlySavingData = false
    let shouldMakeRed = true
    
    var shouldOpenCommentSection = false
    var commentToOpen = ""
    var replyToOpen = ""
    
    var uidsOfLikes: [String] = []
    var pageContainer: PhotoPageContainerViewController?
    var profileViewController: UIViewController?

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.imageView.image = self.image
        downloadTomain(with: actualPost.imageUrl)
        self.mainPostImage.frame = CGRect(x: 0,
                                      y: 70,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.width*1.25)
        self.mainPostImage.center.y = self.view.center.y
        print("[DEBUG] CURRENT INDEX: \(postIndex)")
        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        if let parentVC = self.parent {
            if let parentOfParent = parentVC.parent {
                if let pageContaineree = parentOfParent as? PhotoPageContainerViewController {
                    pageContainer = pageContaineree
                    if let prof = pageContaineree.parentProfileController {
                        profileViewController = prof
                    }
                    
                }
                
            }
            
        }
        addZoombehavior(for: mainPostImage, settings: .instaZoomSettings)
        currentUserUsername = pageContainer?.username ?? ""
        actualPost.username = currentUserUsername
        currentUserProfilePic = pageContainer?.imageUrl ?? ""
        actualPost.userImageUrl = currentUserProfilePic
        actualPost.hasValidStory = pageContainer?.hasValidStory ?? false
        print("* got current user: \(currentUserUsername)")
        styleMore()
        let userIDz = Auth.auth().currentUser?.uid
        let proUID = (pageContainer?.profileUID)!
        self.db.collection("posts").document(proUID).collection("posts").document(actualPost.postID).collection("likes").whereField("uid", isEqualTo: userIDz!).limit(to: 1).getDocuments() { (likesSnapshot, err) in
            if likesSnapshot!.isEmpty || err != nil {
                print("* user has not liked post")
                self.styleForUnLikedBigView()
                self.actualPost.isLiked = false
            } else {
                self.actualPost.isLiked = true
                self.likeButton.setImage(self.likeButton.likedImage, for: .normal)
                self.likeButton.isLiked = true
//                self.makeBigOlLikesViewRed()
                self.styleForLikedBigView()
                print("* post is liked!")
            }
            self.pageContainer?.imagePosts?[self.postIndex].isLiked = self.actualPost.isLiked
            if let profileViewControllerz = self.profileViewController as? MyProfileViewController {
                profileViewControllerz.imagePosts?[self.postIndex].isLiked = self.actualPost.isLiked
                self.profileViewController = profileViewControllerz
            } else if let profileViewControllerz = self.profileViewController as? SavedPostsViewController {
                profileViewControllerz.imagePosts[self.postIndex].isLiked = self.actualPost.isLiked
                self.profileViewController = profileViewControllerz
            }
            
            if self.shouldOpenCommentSection == true {
                print("* popping up comment section")
                self.showCommentSection()
            }
            self.viewCommentsButton.isHidden = false
        }
        self.db.collection("saved").document((Auth.auth().currentUser?.uid)!).collection("all_posts").document(actualPost.postID).getDocument() { (docy, errzz) in
            var isSaved = false
            if docy?.exists == true {
                print("* post is saved!")
                self.savePostButton.setImage(self.savePostButton.likedImage, for: .normal)
                isSaved = true
            } else {
                isSaved = false
            }
            if errzz != nil {
                isSaved = false
            }
            self.actualPost.isSaved = isSaved
            
            self.savePostButton.isLiked = isSaved
            self.pageContainer?.imagePosts?[self.postIndex].isSaved = self.actualPost.isSaved
            if let profileViewControllerz = self.profileViewController as? MyProfileViewController {
                profileViewControllerz.imagePosts?[self.postIndex].isSaved = self.actualPost.isSaved
                self.profileViewController = profileViewControllerz
            } else if let profileViewControllerz = self.profileViewController as? SavedPostsViewController {
                profileViewControllerz.imagePosts[self.postIndex].isSaved = self.actualPost.isSaved
                self.profileViewController = profileViewControllerz
            }
            
            
            // ADD SAVED TAPPED CODE
        }
    }
    @IBAction func savedPressed(_ sender: Any) {
        let userID : String = (Auth.auth().currentUser?.uid)!
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        savePostButton.flipLikedState()
        if actualPost.isSaved == true {
            if let profileViewControllerz = self.profileViewController as? MyProfileViewController {
                profileViewControllerz.imagePosts?[self.postIndex].isSaved = false
                self.profileViewController = profileViewControllerz
            } else if let profileViewControllerz = self.profileViewController as? SavedPostsViewController {
                profileViewControllerz.imagePosts[self.postIndex].isSaved = false
                self.profileViewController = profileViewControllerz
            }
//            (parentViewController?.imagePosts?[postIndex] as! imagePost).isSaved = false
            actualPost.isSaved = false
            savePostButton.isLiked = false
            db.collection("saved").document(userID).collection("all_posts").document(actualPost.postID).delete()
            savePostButton.setImage(savePostButton.unlikedImage, for: .normal)
        } else {
//            (parentViewController?.imagePosts?[postIndex] as! imagePost).isSaved = true
            if let profileViewControllerz = self.profileViewController as? MyProfileViewController {
                profileViewControllerz.imagePosts?[self.postIndex].isSaved = true
                self.profileViewController = profileViewControllerz
            } else if let profileViewControllerz = self.profileViewController as? SavedPostsViewController {
                profileViewControllerz.imagePosts[self.postIndex].isSaved = true
                self.profileViewController = profileViewControllerz
            }
            actualPost.isSaved = true
            db.collection("saved").document(userID).collection("all_posts").document(actualPost.postID).setData(["postID": actualPost.postID, "authorID": actualPost.userID, "timestamp": Date().timeIntervalSince1970])
            savePostButton.isLiked = true
            savePostButton.setImage(savePostButton.likedImage, for: .normal)
            let vc = AddToCollectionPopup()
            vc.actualPost = actualPost
            self.navigationController?.presentPanModal(vc)
//            UIView.animate(withDuration: 0.2, animations: { //1
//
//                self.popupSaved()
//            }, completion: { (finished: Bool) in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                   // Code you want to be delayed
//                    UIView.animate(withDuration: 0.2) {
//                        self.resetSavedPopup()
//                    }
//
//                }
//            })
           
            
        }
    }
    @IBAction func threeDotsPressed(_ sender: Any) {
        let vc = ThreeDotsOnPostController()
        vc.postID = self.actualPost.postID
        vc.authorOfPost = self.actualPost.userID
        self.presentPanModal(vc)
    }
    func styleMore() {
        if actualPost.location == "" {
            styleCell(type: "imagePost", hasSubTitle: false)
        } else {
            styleCell(type: "imagePost", hasSubTitle: true)
        }
        print("* POST USERNAME: \(actualPost.username)")
        firstusernameButton.setTitle(actualPost.username , for: .normal)
        secondusernameButton.setTitle(actualPost.username , for: .normal)
        firstusernameButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        secondusernameButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
    
        timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
        let timeSince = Date(timeIntervalSince1970: TimeInterval(actualPost.createdAt ?? 0)).timeAgoDisplay()
        timeSincePostedLabel.text = "\(currentUserUsername)  • \(timeSince)"
        firstusernameButton.sizeToFit()
        firstusernameButton.frame = CGRect(x: firstusernameButton.frame.minX, y: firstusernameButton.frame.minY, width: firstusernameButton.frame.width, height: 14)
        firstusernameButton.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
            
        
        timeSincePostedLabel.frame = CGRect(x: firstusernameButton.frame.minX, y: firstusernameButton.frame.minY, width: UIScreen.main.bounds.width - 30 - firstusernameButton.frame.maxX, height: 14)
//        let hash = post?.imageHash ?? ""
//        print("* using image hash \(hash)")
        
        likeButton.setDefaultImage()
        likeButton.contentMode = .scaleAspectFit
        likeButton.imageView?.contentMode = .scaleAspectFit
        if (actualPost.isLiked == true) {
            likeButton.setImage(likeButton.likedImage, for: .normal)
            likeButton.isLiked = true
        }
//        cell.likeButton.setNewLikeAmount(to: post?.likesCount ?? 0)
        
        updateCommentButtonLocation()
        
        commentBubbleButton.setDefaultImage()
        commentBubbleButton.contentMode = .scaleAspectFit
        commentBubbleButton.imageView?.contentMode = .scaleAspectFit
//        cell.commentBubbleButton.setNewLikeAmount(to: post?.commentCount ?? 0)
        
        savePostButton.setDefaultImage()
        savePostButton.contentMode = .scaleAspectFit
        savePostButton.imageView?.contentMode = .scaleAspectFit
        if (actualPost.isSaved == true) {
            savePostButton.setImage(savePostButton.likedImage, for: .normal)
            savePostButton.isLiked = true
        }
        
//        let hashedImage = UIImage(blurHash: hash, size: CGSize(width: 32, height: 32))
        locationButton.setTitle(actualPost.location, for: .normal)
        postid = actualPost.postID
        userID = actualPost.userID
//        cell.viewCommentsButton.sizeToFit()
        secondusernameButton.sizeToFit()
        secondusernameButton.backgroundColor = self.view.backgroundColor
        secondusernameButton.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY, width: secondusernameButton.frame.width, height: 14)
        
//        cell.likeButton.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
//        cell.likeButton.layer.cornerRadius = 8
        
//        cell.commentBubbleButton.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
//        cell.commentBubbleButton.layer.cornerRadius = 8
        
        firstusernameButton.backgroundColor = secondusernameButton.backgroundColor
            if (actualPost.hasValidStory == true) {
                print("* valid story [post]")
                profilePicImage.isUserInteractionEnabled = true
                profilePicImage.condition = .init(display: .unseen, color: .custom(colors: [hexStringToUIColor(hex: Constants.primaryColor), .blue, hexStringToUIColor(hex: Constants.primaryColor).withAlphaComponent(0.6)]))
            } else {
                print("* no valid story [postt]")
                profilePicImage.condition = .init(display: .none, color: .none)
            }
            if actualPost.userImageUrl == "" {
                
                profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
                profilePicImage.alpha = 0
                profilePicImage.isHidden = false
                profilePicImage.fadeIn()
            } else {
                downloadImage(with: actualPost.userImageUrl)
            }
        if Constants.isDebugEnabled {
            self.view.debuggingStyle = true
        }
        
            likeButton.setTitle("", for: .normal)
            commentBubbleButton.setTitle("", for: .normal)
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
    func downloadTomain(`with` urlString : String){
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)

        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
//                print("Image: \(value.image). Got from: \(value.cacheType)")
                self.mainPostImage.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    override func viewSafeAreaInsetsDidChange() {
        
        //When this view's safeAreaInsets change, propagate this information
        //to the previous ViewController so the collectionView contentInsets
        //can be updated accordingly. This is necessary in order to properly
        //calculate the frame position for the dismiss (swipe down) animation

        if #available(iOS 11, *) {
            
            //Get the parent view controller (ViewController) from the navigation controller
            guard let parentVC = self.navigationController?.viewControllers.first as? MyProfileViewController else {
                return
            }
            
            //Update the ViewController's left and right local safeAreaInset variables
            //with the safeAreaInsets for this current view. These will be used to
            //update the contentInsets of the collectionView inside ViewController
//            parentVC.currentLeftSafeAreaInset = self.view.safeAreaInsets.left
//            parentVC.currentRightSafeAreaInset = self.view.safeAreaInsets.right
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func styleCell(type: String, hasSubTitle: Bool) {
        profilePicImage.setTitle("", for: .normal)
        shareToUserButton.setTitle("", for: .normal)
        savePostButton.setTitle("", for: .normal)
        tmpRightArrow.setTitle("", for: .normal)
        otherLikesbutton.setTitle("", for: .normal)
        upperRightShareButton.setTitle("", for: .normal)
        tmpViewLikesButton.setTitle("", for: .normal)
        
        otherLikesbutton.isHidden = true
        profilePicView1.isHidden = true
        profilePicView2.isHidden = true
        profilePicView3.isHidden = true
        navigationController?.navigationBar.isHidden = true
        if type == "imagePost" {
            
            // PROFILE IMAGE
            profilePicImage.layer.cornerRadius = 8
            profilePicImage.frame = CGRect(x: 15, y: 120, width: 40, height: 40)
            
            // USERNAME LABEL
            firstusernameButton.contentHorizontalAlignment = .left
            secondusernameButton.contentHorizontalAlignment = .left
            locationButton.contentHorizontalAlignment = .left
            locationButton.contentVerticalAlignment = .top
            
            let shareButtonWidth = 30
            upperRightShareButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - shareButtonWidth - 15, y: Int(profilePicImage.frame.minY) + 5, width: shareButtonWidth, height: shareButtonWidth)
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

            
            let mainPostWidth = UIScreen.main.bounds.width
            mainPostImage.contentMode = .scaleAspectFill
//            mainPostImage.frame = CGRect(x: 0, y: profilePicImage.frame.maxY + 15 , width: mainPostWidth, height: mainPostWidth*1.25)
            

//            let subButtonY = mainPostImage.frame.maxY - 40
            let subButtonY = mainPostImage.frame.maxY + 10
            let subButtonWidths = 30
            

            self.likeButton.frame = CGRect(x: 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            
            self.commentBubbleButton.frame = CGRect(x: Int(likeButton.frame.maxX) + 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            self.shareToUserButton.frame = CGRect(x: Int(commentBubbleButton.frame.maxX) + 9, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            
            
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
            doubleTap.delaysTouchesBegan = false
            mainPostImage.layer.cornerRadius = 0
            
//            self.firstusernameButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
//            self.secondusernameButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
            
            likeButton.isHidden = false
            commentBubbleButton.isHidden = false
            upperRightShareButton.isHidden = false
            savePostButton.isHidden = false
            shareToUserButton.isHidden = false
                
            viewLikesView.frame = CGRect(x: 15, y: likeButton.frame.maxY + 10, width: 200, height: 40)
            styleForUnLikedBigView()
            viewLikesView.isHidden = false
            
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
                otherLikesbutton.isHidden = false
            } else if actualPost.numOfLikeMindedLIkes != 0 {
                likesString = "liked by \(actualPost.usernameToShow)"
                otherLikesbutton.isHidden = false
            }
            print("* using string: \(likesString)")
            otherLikesbutton.setTitle(likesString, for: .normal)
            otherLikesbutton.frame = CGRect(x: profilePicView3.frame.maxX + 5, y: profilePicView1.frame.minY, width: UIScreen.main.bounds.width - profilePicView3.frame.maxX - 15 - 15, height: profilePicView3.frame.height)
            otherLikesbutton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 13)
            otherLikesbutton.isHidden = false
            tmpViewLikesButton.frame = CGRect(x: 0, y: 0, width: self.viewLikesView.frame.width, height: self.viewLikesView.frame.height)
            
            self.secondusernameButton.frame = CGRect(x: 15, y: profilePicView1.frame.maxY+10, width: 5, height: 5)
            
//            self.secondusernameButton.backgroundColor = .blue
            let captionFont = UIFont(name: "\(Constants.globalFont)", size: 14)
            let captionString = "\(actualPost.username)  \(actualPost.caption)"
            captionLabel.font = captionFont
            captionLabel.text = captionString
            let captionWidth = UIScreen.main.bounds.width - 15 - secondusernameButton.frame.maxX
            
            let expectedLabelHeight = captionString.height(withConstrainedWidth: captionWidth, font: captionFont!)
            print("* expected label height: \(expectedLabelHeight)")
            if expectedLabelHeight < 20 {
                self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY-2, width: captionWidth, height: 20)
            } else if (expectedLabelHeight > 40) {
                self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY-2, width: captionWidth, height: 40)
                self.captionLabel.addTrailing(with: "...", moreText: "more", moreTextFont: captionLabel.font, moreTextColor: .lightGray)
            } else {
                self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY-2, width: captionWidth, height: 40)
            }
//
            
            self.viewCommentsButton.frame = CGRect(x: 15, y: captionLabel.frame.maxY+15, width: 5, height: 20)
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
                self.likeButton.isLiked = true
                styleForLikedBigView()
                tmpRightArrow.tintColor = .white
            } else if actualPost.isLiked == false {
                self.likeButton.isLiked = false
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
        actualPost.isLiked = self.likeButton.isLiked
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
        self.tmpRightArrow.tintColor = .white
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
        print("* upadting post at \(postIndex)")
        if self.likeButton.isLiked {
            if shouldMakeRed {
                styleForLikedBigView()
            }
            self.tmpRightArrow.tintColor = .white
            likesLabel.pushScrollingTransitionUp(0.2) // Invoke before changing content
            likesLabel.text = "\(((Int(currentval) ?? 0) + 1).delimiter) likes" // roundedWithAbbreviations if want k/M for likes
            if let profileViewControllerz = self.profileViewController as? MyProfileViewController {
                profileViewControllerz.imagePosts?[postIndex].likesCount = ((Int(currentval) ?? 0) + 1)
                profileViewControllerz.imagePosts?[postIndex].isLiked = true
                self.profileViewController = profileViewControllerz
            } else if let profileViewControllerz = self.profileViewController as? SavedPostsViewController {
                profileViewControllerz.imagePosts[postIndex].likesCount = ((Int(currentval) ?? 0) + 1)
                profileViewControllerz.imagePosts[postIndex].isLiked = true
                self.profileViewController = profileViewControllerz
            }
            
            pageContainer?.imagePosts?[postIndex].likesCount = ((Int(currentval) ?? 0) + 1)
            pageContainer?.imagePosts?[postIndex].isLiked = true
//            animateUpLikes()
        } else {
            styleForUnLikedBigView()
            self.tmpRightArrow.tintColor = .lightGray
            if ((Int(currentval) ?? 1) - 1) >= 0 {
                likesLabel.pushScrollingTransitionDown(0.2) // Invoke before changing content
                likesLabel.text = "\(((Int(currentval) ?? 1) - 1).delimiter) likes" // roundedWithAbbreviations if want k/M for likes
                if let profileViewControllerz = self.profileViewController as? MyProfileViewController {
                    profileViewControllerz.imagePosts?[postIndex].likesCount = ((Int(currentval) ?? 1) - 1)
                    profileViewControllerz.imagePosts?[postIndex].isLiked = false
                    self.profileViewController = profileViewControllerz
                } else if let profileViewControllerz = self.profileViewController as? SavedPostsViewController {
                    profileViewControllerz.imagePosts[postIndex].likesCount = ((Int(currentval) ?? 1) - 1)
                    profileViewControllerz.imagePosts[postIndex].isLiked = false
                    self.profileViewController = profileViewControllerz
                }
//                profileViewController?.imagePosts?[postIndex].likesCount = ((Int(currentval) ?? 1) - 1)
//                profileViewController?.imagePosts?[postIndex].isLiked = false
                pageContainer?.imagePosts?[postIndex].likesCount = ((Int(currentval) ?? 1) - 1)
                pageContainer?.imagePosts?[postIndex].isLiked = false
            }
            
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
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.hidesBackButton = true
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
//        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
//            vc.actualPost = self.actualPost
//            vc.tmpImage = self.mainPostImage.image
//            vc.originalPostID = self.postid
//            vc.originalPostAuthorID = self.userID
//            vc.currentUserUsername = self.currentUserUsername
//            vc.currentUserProfilePic = self.currentUserProfilePic
//            if shouldSetFirstResponder {
//                vc.commentTextField.becomeFirstResponder()
//            }
//            let generator = UIImpactFeedbackGenerator(style: .medium)
//            generator.impactOccurred()
//            navigationController?.pushViewController(vc, animated: true)
//
//        }
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "NewCommentSection") as? CommentSectionPopup {
//        let vc = CommentSectionPopup()
            vc.actualPost = self.actualPost
            vc.originalPostID = self.postid
            vc.originalPostAuthorID = self.userID
            vc.currentUserUsername = self.currentUserUsername
            vc.currentUserProfilePic = self.currentUserProfilePic
            if commentToOpen != "" {
                vc.highlightCommentUID = commentToOpen
            }
            if replyToOpen != "" {
                vc.replyToOpen = replyToOpen
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
            if let navigator = self.navigationController {
                navigator.presentPanModal(vc)
            }
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
                    self.profilePicView1.alpha = 1
                    self.profilePicView1.isHidden = false
                } else if intoIndex == 1 {
                    self.profilePicView2.image = value.image
                    self.profilePicView2.alpha = 1
                    self.profilePicView2.isHidden = false
                } else if intoIndex == 2 {
                    self.profilePicView3.image = value.image
                    self.profilePicView3.alpha = 1
                    self.profilePicView3.isHidden = false
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
                self.profilePicImage.alpha = 1
                self.profilePicImage.isHidden = false
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}

extension PhotoZoomViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mainPostImage
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.photoZoomViewController(self, scrollViewDidScroll: scrollView)
    }
}
