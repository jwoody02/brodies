//
//  ProfileViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 5/15/22.
//
import UIKit
import Foundation
import SwiftKeychainWrapper
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher
import FirebaseAnalytics
import SkeletonView
import NextLevel
import DGElasticPullToRefresh

class userProfileImagePosts: UICollectionViewCell {
    
    @IBOutlet weak var previewImage: DownloadableImageView!
    
    var actualPost = imagePost()
    var indexOfPost = -1
    var postid = ""
    var userID = ""
    var imageHash = ""
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    var isCurrentlySavingData = false
    
    var hasRetried = false
    private var db = Firestore.firestore()
    
    func stylePost() {
//        previewImage.frame = CGRect(x: 0, y: 0, width: (Int(UIScreen.main.bounds.width) - Constants.imagePadding * 4) / 3, height: (Int(UIScreen.main.bounds.width) - Constants.imagePadding * 4) / 3)
        previewImage.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        previewImage.contentMode = .scaleAspectFill
        if indexOfPost == 0 {
            self.roundCorners(corners: [.topLeft], radius: 12)
            
        }
        if indexOfPost == 3 {
            self.roundCorners(corners: [.topRight], radius: 12)
        }
        self.clipsToBounds = true
        self.previewImage.clipsToBounds = true
        
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImage.cancelLoadingImage()
    }
    func setPostImage(fromUrl: String) {
        self.previewImage.contentMode = .scaleAspectFill
        let url = URL(string: fromUrl)
        let processor = DownsamplingImageProcessor(size: CGSize(width: previewImage.frame.width, height: previewImage.frame.height))
        self.previewImage.kf.indicatorType = .activity
        self.previewImage.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.25)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                //                print("Job failed: \(error.localizedDescription)")
                print("* failure, pushing new photo")
                let storageRef = Storage.storage().reference().child("/post_thumbnails/\(self.actualPost.storageRefForThumbnailImage.replacingOccurrences(of: "post_photos/", with: ""))")
                storageRef.downloadURL { urlRes, error2 in
                    if error2 == nil {
                        print("* got url: \(urlRes)")
                        self.db.collection("posts").document(self.actualPost.userID).collection("posts").document(self.actualPost.postID).setData(["thumbnail_url": urlRes?.absoluteString as! String], merge: true)
                        
                        self.setPostImage(fromUrl: urlRes?.absoluteString as! String)
                    } else {
                        print("* error: \(error2)")
                    }
                    
                    
                }
                //                if self.hasRetried == false {
                //                    print("* job failed, attempting to fetch full res image")
                //                    self.hasRetried = true
                //                    self.setPostImage(fromUrl: self.actualPost.imageUrl)
                //                }
            }
        }
        //        self.previewImage.image = UIImage(named: "imm2.jpeg")
    }
}
class MyProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate {
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "previewPostProfileCell"
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagePosts?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //        previewPostProfileCell
        //        print("* loading new post: \(imagePosts?[indexPath.row].imageUrl ?? "")")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "previewPostProfileCell", for: indexPath) as! userProfileImagePosts
        cell.stylePost()
        cell.hasRetried = false
        cell.actualPost = imagePosts![indexPath.row]
        cell.backgroundColor = .white
        //        cell.previewImage.downloadWithUrlSession(at: cell, urlStr: imagePosts?[indexPath.row].thumbNailImageURL ?? "")
        cell.setPostImage(fromUrl: imagePosts?[indexPath.row].thumbNailImageURL ?? "")
        return cell
    }
           
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow:CGFloat = 3
        let spacingBetweenCells:CGFloat = 1
        
        let totalSpacing = (2 * self.spacing) + ((numberOfItemsPerRow - 1) * spacingBetweenCells) //Amount of total spacing in a row
        
        if let collection = self.postsCollectionView {
            let width = (collection.bounds.width - totalSpacing)/numberOfItemsPerRow
            return CGSize(width: width, height: width)
        }else{
            return CGSize(width: 0, height: 0)
        }
        
    }
    private let spacing:CGFloat = 1
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        print("* set selected path: \(self.selectedIndexPath)")
        self.performSegue(withIdentifier: "ShowPhotoPageView", sender: self)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if (indexPath.row == (imagePosts?.count ?? 1) - 1) && hasReachedEndOfFeed == false {
            
            print("* fetching more comments. Current comment count: \((imagePosts?.count ?? 1)-1)")
            paginate()
        }
    }
    func paginate() {
        //This line is the main pagination code.
        //Firestore allows you to fetch document from the last queryDocument
        query = query.start(afterDocument: documents.last!).limit(to: 12)
        getPosts()
    }
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var profilePicImage: IGStoryButton!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var actualFollowersLabel: UILabel!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var actualFollowingLabel: UILabel!
    @IBOutlet weak var postsCollectionView: UICollectionView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var addToStoryButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var upperRightThreeDotsbutton: UIButton!
    @IBOutlet weak var bellButton: UIButton!
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var SaveedButton: UIButton!
    
    @IBOutlet weak var tabBarView: UIView!
    
    @IBOutlet weak var editProfileButton: UIButton!
    
    let defaults = UserDefaults.standard
    
    var uidOfProfile = ""
    var isCurrentUser = false
    private var db = Firestore.firestore()
    
    var hasReachedEndOfFeed = false
    
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    
    var imagePosts: [imagePost]? = []
    var selectedIndexPath: IndexPath!
    
    public var isFollowing = false
    public var currentUsername = ""
    public var currentProfilePic = ""
    public var hasValidStory = false
    var isBlocked = false
    var userHasBlocked = false
    /// ViewController to display the story content
    private var storyVc: FAStoryViewController!
    
    var user = User(uid: "", username: "", profileImageUrl: "", bio: "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: "", hasValidStory: false, isFollowing: false)
    override func viewDidLoad() {
        super.viewDidLoad()
        //        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        self.view.backgroundColor = .white
        styleElements()
        addToStoryButton.setTitle("", for: .normal)
        profilePicImage.setTitle("", for: .normal)
        backButton.setTitle("", for: .normal)
        SaveedButton.setTitle("", for: .normal)
        postsCollectionView.isSkeletonable = true
        let layout = UICollectionViewFlowLayout()
       layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
       layout.minimumLineSpacing = spacing
       layout.minimumInteritemSpacing = spacing
       self.postsCollectionView?.collectionViewLayout = layout
        postsCollectionView.showAnimatedSkeleton(usingColor: .clouds, transition: .crossDissolve(0.25))
        if Auth.auth().currentUser?.uid == nil {
            //            // show login view
            print("not valid user, pushing login")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        } else {
            if uidOfProfile == "" || Auth.auth().currentUser?.uid == uidOfProfile {
                print("* detected current user")
                uidOfProfile = (Auth.auth().currentUser?.uid)!
                isCurrentUser = true
                backButton.isHidden = true
                settingsButton.isHidden = false
                upperRightThreeDotsbutton.isHidden = true
                bellButton.isHidden = true
                followButton.isHidden = true
                followButton.alpha = 0
                messageButton.isHidden = true
                messageButton.alpha = 0
            } else {
                print("* detected not current user: \(uidOfProfile) compard to \(Auth.auth().currentUser?.uid)")
                setUserImage(with: user.profileImageUrl)
                
                usernameLabel.text = "\(user.username)"
                usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
                usernameLabel.sizeToFit()
                usernameLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (usernameLabel.frame.width / 2), y: 50, width: usernameLabel.frame.width, height: usernameLabel.frame.height)
                
                
                fullNameLabel.text = "\(user.fullname)"
                fullNameLabel.sizeToFit()
                fullNameLabel.center.x = self.profilePicImage.center.x
                fullNameLabel.center.y = self.profilePicImage.center.y + 25
                addToStoryButton.isHidden = true
                settingsButton.isHidden = true
                upperRightThreeDotsbutton.isHidden = false
                bellButton.isHidden = false
            }
            
            let postsRef = db.collection("posts")
            query = postsRef.document(uidOfProfile).collection("posts").order(by: "createdAt", descending: true).limit(to: 12)
            Analytics.logEvent("view_profile", parameters: [
                "profileUID": uidOfProfile,
            ])
            getPosts()
            getFollowingFollowerInfo()
        }
        postsCollectionView.dataSource = self
        postsCollectionView.delegate = self
        let screenWidth = UIScreen.main.bounds.width
//        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: CGFloat(Constants.imagePadding), left: CGFloat(Constants.imagePadding), bottom: CGFloat(Constants.imagePadding), right: CGFloat(Constants.imagePadding))
//        layout.itemSize = CGSize(width: (Int(screenWidth) - Constants.imagePadding*4)/3, height: (Int(screenWidth) - Constants.imagePadding*4)/3)
//        layout.minimumInteritemSpacing = CGFloat(Constants.imagePadding)
//        layout.minimumLineSpacing = CGFloat(Constants.imagePadding)
//        postsCollectionView!.collectionViewLayout = layout
        
        updateForDebug()
        
        // Initialize tableView
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        //        loadingView.tintColor = UIColor(red: 78/255.0, green: 221/255.0, blue: 200/255.0, alpha: 1.0)
        loadingView.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        postsCollectionView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            // Add your logic here
            // Do not forget to call dg_stopLoading() at the end
            self?.imagePosts?.removeAll()
            self?.documents.removeAll()
            self?.hasReachedEndOfFeed = false
            let userID = Auth.auth().currentUser?.uid
            let postsRef = self?.db.collection("posts")
            self?.query = postsRef?.document(self!.uidOfProfile).collection("posts").order(by: "createdAt", descending: true).limit(to: 12)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            self?.getPosts()
        }, loadingView: loadingView)
        //        postsTableView.dg_setPullToRefreshFillColor(UIColor(red: 57/255.0, green: 67/255.0, blue: 89/255.0, alpha: 1.0))
        postsCollectionView.dg_setPullToRefreshFillColor(hexStringToUIColor(hex: Constants.secondaryColor))
        postsCollectionView.dg_setPullToRefreshBackgroundColor(hexStringToUIColor(hex: Constants.secondaryColor))
        postsCollectionView.isHidden = true
        followButton.isHidden = true
        messageButton.isHidden = true
        profilePicImage.isUserInteractionEnabled = true
    }
    @IBAction func NotificationsSettingPressed(_ sender: Any) {
        let vc = ProfileNotificationsPopup()
        vc.profileUID = self.uidOfProfile
        self.navigationController?.presentPanModal(vc)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
                    self.hasReachedEndOfFeed = true
                } else {
                    //                    print("* posts returned: \(querySnapshot)")
                    for document in querySnapshot!.documents {
                        let useID = document.documentID
                        let values = document.data()  as? [String: Any]
                        mainPostDispatchQueue.enter()
                        self.documents += [document]
                        var post = Egg_.imagePost()
                        post.userID = self.uidOfProfile
                        post.postID = useID
                        post.commentCount = values?["comments_count"] as? Int ?? 0 // fix this
                        post.likesCount = values?["likes_count"] as? Int ?? 0
                        post.imageUrl = values?["postImageUrl"] as? String ?? ""
                        post.thumbNailImageURL = values?["thumbnail_url"] as? String ?? ""
                        post.location = values?["location"] as? String ?? ""
                        post.caption = values?["caption"] as? String ?? ""
                        post.tags = values?["tags"] as? [String] ?? [""]
                        post.createdAt = values?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                        post.imageHash = values?["imageHash"] as? String ?? ""
                        post.username = self.user.username
                        post.storageRefForThumbnailImage = values?["storage_ref"] as? String ?? ""
                        self.imagePosts?.append(post) // delete if use likes thing
                        mainPostDispatchQueue.leave() // delete if use likes thing again
                        
                        //                        self.db.collection("posts").document(self.uidOfProfile).collection("posts").document(useID).collection("likes").whereField("uid", isEqualTo: userID!).limit(to: 1).getDocuments() { (likesSnapshot, err) in
                        //                            if likesSnapshot!.isEmpty {
                        //                                print("* user has not liked post")
                        //                            } else {
                        //                                post.isLiked = true
                        //                                print("* post is liked!")
                        //                            }
                        //                            self.imagePosts?.append(post)
                        //                            mainPostDispatchQueue.leave()
                        //                        }
                        
                    }
                    mainPostDispatchQueue.notify(queue: .main) {
                        self.imagePosts = self.imagePosts!.sorted (by: {$0.createdAt > $1.createdAt})
                        //                        print("* resorted posts from Higher createdAt to lower: \(self.imagePosts)")
                        if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                            print("* looks like we've reached the end of posts collection")
                            self.hasReachedEndOfFeed = true
                        } else {
                            DispatchQueue.main.async {
                                self.postsCollectionView.dg_stopLoading()
                                self.postsCollectionView.stopSkeletonAnimation()
                                self.postsCollectionView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.25))
                                print("* reloading data")
                                self.postsCollectionView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    func updateForDebug() {
        if Constants.isDebugEnabled {
            //            var window : UIWindow = UIApplication.shared.keyWindow!
            //            window.showDebugMenu()
            self.view.debuggingStyle = true
        }
    }
    func styleElements() {
        self.topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        let profilePicWidth = 50
        self.profilePicImage.frame = CGRect(x: (Int(UIScreen.main.bounds.width) / 2) - (profilePicWidth / 2), y: 90, width: profilePicWidth, height: profilePicWidth)
        self.profilePicImage.layer.cornerRadius = 12
        
        let paddingBetween = 30
        actualFollowersLabel.sizeToFit()
        actualFollowersLabel.frame = CGRect(x: self.profilePicImage.frame.minX - actualFollowersLabel.frame.width - CGFloat(paddingBetween), y: 0, width: actualFollowersLabel.frame.width, height: actualFollowersLabel.frame.height)
        actualFollowersLabel.center.y = self.profilePicImage.center.y + 12
        
        
        followersButton.sizeToFit()
        followersButton.center.x = actualFollowersLabel.center.x
        followersButton.center.y = self.profilePicImage.center.y - 10
        
        actualFollowingLabel.sizeToFit()
        actualFollowingLabel.frame = CGRect(x: self.profilePicImage.frame.maxX + CGFloat(paddingBetween), y: 0, width: actualFollowingLabel.frame.width, height: actualFollowingLabel.frame.height)
        actualFollowingLabel.center.y = self.actualFollowersLabel.center.y
        
        followingButton.sizeToFit()
        followingButton.center.x = actualFollowingLabel.center.x
        followingButton.center.y = self.followersButton.center.y
        
        let addStoryButtonWidth = 18
        addToStoryButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        addToStoryButton.backgroundColor = hexStringToUIColor(hex: Constants.secondaryColor)
        addToStoryButton.layer.cornerRadius = 4
        addToStoryButton.clipsToBounds = true
        
        addToStoryButton.frame = CGRect(x: (Int(UIScreen.main.bounds.width) / 2) - (addStoryButtonWidth / 2), y: Int(profilePicImage.frame.maxY) - (addStoryButtonWidth / 2), width: addStoryButtonWidth, height: addStoryButtonWidth)
        //        applyStoryBorderColor()
        
        postsCollectionView.frame = CGRect(x: 0, y: topWhiteView.frame.maxY-15, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - topWhiteView.frame.maxY - 10)
        
        backButton.frame = CGRect(x: 0, y: 30, width: 50, height: 60)
        backButton.tintColor = .darkGray
        
        topWhiteView.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        self.topWhiteView.layer.masksToBounds = false
        self.topWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.topWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.topWhiteView.layer.shadowOpacity = 0.3
        self.topWhiteView.layer.shadowRadius = Constants.borderRadius
        
        bioLabel.isHidden = true
        
        postsCollectionView.backgroundColor = .white
        postsCollectionView.showsVerticalScrollIndicator = false
        followersButton.clipsToBounds = true
        
        let refWidth = 40
        let refY = 42
//        settingsButton.setTitle("", for: .normal)
//        settingsButton.layer.cornerRadius = 8
//        settingsButton.tintColor = Constants.primaryColor.hexToUiColor()
//        settingsButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - refWidth, y: refY, width: refWidth, height: refWidth)
        settingsButton.setTitle("", for: .normal)
        settingsButton.layer.cornerRadius = 12
        settingsButton.backgroundColor = Constants.secondaryColor.hexToUiColor()
        settingsButton.tintColor = Constants.primaryColor.hexToUiColor()
        settingsButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - refWidth - 20, y: refY, width: refWidth, height: refWidth)
        
        upperRightThreeDotsbutton.setTitle("", for: .normal)
        upperRightThreeDotsbutton.layer.cornerRadius = 8
        upperRightThreeDotsbutton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - refWidth - 10, y: refY, width: refWidth, height: refWidth)
        
        bellButton.setTitle("", for: .normal)
        bellButton.layer.cornerRadius = 8
        bellButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - (refWidth * 2) - (10), y: refY, width: refWidth, height: refWidth)
    }
    @IBAction func settingsTapped(_ sender: Any) {
        let vc = SettingsPopupController()
        vc.parentVC = self
        self.navigationController?.presentPanModal(vc)
    }
    @IBAction func threeDotsTapped(_ sender: Any) {
        let vc = ThreeDotsOnProfileController()
        vc.profileUID = self.uidOfProfile
        vc.profileUserName = self.currentUsername
        vc.parentVC = self
        vc.isBlocked = userHasBlocked
        self.navigationController?.presentPanModal(vc)
    }
    // Usage: insert view.pushTransition right before changing content
    
    @IBAction func followButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        print("* follow button pressed")
        let currentFollow = Int((followersButton.titleLabel?.text!)!)
        if followButton.titleLabel?.text == "Follow" {
            followersButton.pushScrollingTransitionUp(0.2) // Invoke before changing content
            followersButton.setTitle("\(((currentFollow ?? 0) + 1).roundedWithAbbreviations)", for: .normal)
            print("* following user")
            
            styleForFollowing()
            if user.isPrivate ?? false {
                followButton.setTitle("Requested", for: .normal)
            }
            let timestamp = NSDate().timeIntervalSince1970
            self.db.collection("user-locations").document(userID!).getDocument { (document, err) in
                print("* doc: \(document)")
                if ((document?.exists) != nil) && document?.exists == true {
                    let data = document?.data()! as [String: AnyObject]
                    print("* adding to followers/\(self.uidOfProfile)/sub-followers/\(userID!)")
                    self.db.collection("followers").document(self.uidOfProfile).collection("sub-followers").document(userID!).setData(["uid": userID!, "timestamp": Int(timestamp), "username": data["username"] as? String ?? ""]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("succesfully followed user!")
                        }
                    }
                }
            }
            
        } else {
            print("* unfollowing user")
            followersButton.pushScrollingTransitionDown(0.2) // Invoke before changing content
            followersButton.setTitle("\(((currentFollow ?? 0) - 1).roundedWithAbbreviations)", for: .normal)
            styleForNotFollowing()
            self.db.collection("followers").document(uidOfProfile).collection("sub-followers").document(userID!).delete() { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("succesfully unfollowed user!")
                }
            }
        }
    }
    @IBAction func goBackPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        navigationController?.delegate = self
        _ = navigationController?.popViewController(animated: true)
    }
    func applyStoryBorderColor() {
        profilePicImage.layer.borderWidth = 2
        //        profilePicImage.layer.masksToBounds = false
        profilePicImage.layer.borderColor = hexStringToUIColor(hex: Constants.primaryColor).cgColor
    }
    func setUserImage(`with` urlString : String) {
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        
        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.profilePicImage.image = value.image
                self.profilePicImage.fadeIn()
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    func getFollowingFollowerInfo() {
        let userID : String = (Auth.auth().currentUser?.uid)!
        print("* checking following/\(userID)/sub-following/\(uidOfProfile)")
        db.collection("following").document(userID).collection("sub-following").document(uidOfProfile).getDocument { (document, err) in
            print("* doc: \(document)")
            if ((document?.exists) != nil) && document?.exists == true {
                print("* current user is following user")
                self.styleForFollowing()
                self.isFollowing = true
            } else {
                print("* current user has not followed user [snap empty]")
                self.styleForNotFollowing()
                self.isFollowing = false
            }
            
            
            self.messageButton.setTitle("Message", for: .normal)
            self.messageButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
            self.messageButton.tintColor = .black
            self.messageButton.clipsToBounds = true
            self.messageButton.layer.cornerRadius = 8
            
            self.editProfileButton.setTitle("Edit Profile", for: .normal)
            self.editProfileButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
            self.editProfileButton.tintColor = .black
            self.editProfileButton.clipsToBounds = true
            self.editProfileButton.layer.cornerRadius = 8
            
            if self.isCurrentUser == false {
                self.followButton.fadeIn()
                self.messageButton.fadeIn()
            }
            self.updatebasicInfo()
        }
    }
    public func styleForFollowing() {
        self.followButton.setTitle("Unfollow", for: .normal)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
        self.followButton.tintColor = .black
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 8
//        self.followButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        self.followButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        self.followButton.setImage(UIImage(systemName: "chevron.down")?.applyingSymbolConfiguration(.init(pointSize: 8, weight: .semibold, scale: .medium))?.image(withTintColor: .black), for: .normal)
//        self.followButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//        let spacing = CGFloat(-10); // the amount of spacing to appear between image and title
//        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: -2, right: 0)
//        
//        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    }
    public func styleForNotFollowing() {
        self.followButton.setTitle("Follow", for: .normal)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: Constants.primaryColor)
        self.followButton.tintColor = .white
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 8
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.followButton.setImage(nil, for: .normal)
    }
    func updatebasicInfo() {
        print("* collecting data on uid: \(uidOfProfile)")
        db.collection("blocked").document(Auth.auth().currentUser!.uid).collection("blocked_users").document(uidOfProfile).getDocument() { [self] (documentz, error2) in
            if (documentz != nil && documentz!.exists) || error2 != nil || documentz == nil {
                print("* user has blocked this user")
                userHasBlocked = true
                postsCollectionView.isHidden = true
                followButton.isHidden = true
                messageButton.isHidden = true
                usernameLabel.text = "Blocked User"
                self.usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
                self.usernameLabel.sizeToFit()
                self.usernameLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (self.usernameLabel.frame.width / 2), y: 50, width: self.usernameLabel.frame.width, height: self.usernameLabel.frame.height)
                self.usernameLabel.isHidden = false
                fullNameLabel.isHidden = true
                self.profilePicImage.isHidden = true
                self.followersButton.isHidden = true
                self.bioLabel.isHidden = true
                self.followingButton.isHidden = true
            } else {
                print("* current user hasnt blocked, checking other way around")
                db.collection("blocked").document(uidOfProfile).collection("blocked_users").document(Auth.auth().currentUser!.uid).getDocument() { [self] (document2, errork) in
                    if (document2 != nil && document2!.exists) || errork != nil || document2 == nil {
                        print("* looks like user of profile has blocked current user")
                        isBlocked = true
                        postsCollectionView.isHidden = true
                        self.profilePicImage.isHidden = true
                        self.followersButton.isHidden = true
                        self.bioLabel.isHidden = true
                        self.followingButton.isHidden = true
                        self.fullNameLabel.isHidden = true
                        self.usernameLabel.isHidden = false
                        followButton.isHidden = true
                        messageButton.isHidden = true
                        usernameLabel.text = "User not found"
                        self.usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
                        self.usernameLabel.sizeToFit()
                        self.usernameLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (self.usernameLabel.frame.width / 2), y: 50, width: self.usernameLabel.frame.width, height: self.usernameLabel.frame.height)
                    } else {
                        print("* current user isn't blocked, continuing")
                        db.collection("user-locations").document(uidOfProfile).getDocument() { [self] (document, error) in
                            if let document = document {
                                self.user.uid = self.uidOfProfile
                                let data = document.data()! as [String: AnyObject]
                                self.postsCollectionView.isHidden = false
                                self.postsCollectionView.alpha = 1
                                self.fullNameLabel.isHidden = false
                                self.bioLabel.isHidden = false
                                self.user.profileImageUrl = data["profileImageURL"] as? String ?? ""
                                currentProfilePic = self.user.profileImageUrl
                                self.user.username = data["username"] as? String ?? ""
                                self.user.fullname = data["full_name"] as? String ?? ""
                                self.user.isPrivate = data["isPrivate"] as? Bool ?? false
                                print("* is user private: \(self.user.isPrivate)")
                                if self.user.isPrivate! && Auth.auth().currentUser?.uid != uidOfProfile && self.isFollowing == false {
                                    self.postsCollectionView.isHidden = true
                                    self.postsCollectionView.alpha = 0
                                    self.postsCollectionView.isUserInteractionEnabled = false
                                }
                                db.collection("pending-followers").document(uidOfProfile).collection("sub-pending-followers").document(Auth.auth().currentUser!.uid).getDocument() { [self] (pendingDoc, pendingError) in
                                    if let pendingDoc = pendingDoc {
                                        if pendingDoc.exists {
                                            styleForFollowing()
                                            followButton.setTitle("Requested", for: .normal)
                                        }
                                    }
                                }
                                if self.user.profileImageUrl == "" {
                                    profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
                                    print("* no profile pic, defaulting iamge")
                                    profilePicImage.fadeIn()
                                } else {
                                    self.setUserImage(with: self.user.profileImageUrl)
                                }
                                
                                
                                self.usernameLabel.text = "\(self.user.username)"
                                
                                currentUsername = self.user.username
                                self.usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
                                self.usernameLabel.sizeToFit()
                                self.usernameLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (self.usernameLabel.frame.width / 2), y: 50, width: self.usernameLabel.frame.width, height: self.usernameLabel.frame.height)
                                
                                
                                self.fullNameLabel.text = "\(self.user.fullname)"
                                self.fullNameLabel.sizeToFit()
                                self.fullNameLabel.center.x = self.profilePicImage.center.x
                                self.fullNameLabel.center.y = self.profilePicImage.center.y + 50
                                print("* got new user: \(self.user)")
                                
                                var mainString = data["full_name"] as? String ?? ""
                                let stringToColor = "|"
                                let addBioToColor = " Add something here"
                                //                if data["biline"] as? String ?? "" == "" {
                                //                    print("* detected no biline")
                                //                    if self.isCurrentUser == true {
                                //                        mainString = "\(mainString) | Add something here"
                                //                    }
                                //                }
                                mainString = "\(mainString)  |  \(Int(data["brodie_score"] as? Int ?? 0).delimiter)"
                                let range = (mainString as NSString).range(of: stringToColor)
                                let rangeForBio = (mainString as NSString).range(of: addBioToColor)
                                let LighterFont = UIFont(name: "\(Constants.globalFont)-LightItalic", size: 14)!
                                
                                let mutableAttributedString = NSMutableAttributedString.init(string: mainString)
                                mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.lightGray, range: range)
                                mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.lightGray.withAlphaComponent(0.7), range: rangeForBio)
                                mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: LighterFont, range: rangeForBio)
                                self.fullNameLabel.attributedText = mutableAttributedString
                                self.fullNameLabel.sizeToFit()
                                self.fullNameLabel.center.x = self.profilePicImage.center.x
                                self.fullNameLabel.center.y = self.profilePicImage.center.y + 50
                                
                                var bioString = data["bio"] as? String ?? ""
                                if bioString == "" {
                                    print("* detected no bio")
                                    if self.isCurrentUser == true {
                                        bioString = "Add a bio in profile settings"
                                        let LighterFont = UIFont(name: "\(Constants.globalFont)-LightItalic", size: 14)!
                                        self.bioLabel.font = LighterFont
                                        self.bioLabel.text = bioString
                                        self.bioLabel.textColor = UIColor.lightGray.withAlphaComponent(0.7)
                                        self.bioLabel.fadeIn()
                                        followButton.isHidden = true
                                        messageButton.isHidden = true
                                        let tmp = self.actualFollowingLabel.frame.maxX - self.actualFollowersLabel.frame.minX
                                        self.bioLabel.frame = CGRect(x: self.actualFollowersLabel.frame.minX, y: fullNameLabel.frame.maxY + 10, width: tmp, height: 60)
                                        self.bioLabel.textAlignment = .center
                                    } else {
                                        self.bioLabel.isHidden = true
                                        print("* making bio label really small")
                                        self.bioLabel.frame = CGRect(x: self.actualFollowersLabel.frame.minX, y: fullNameLabel.frame.maxY + 10, width: self.actualFollowingLabel.frame.maxX - self.actualFollowersLabel.frame.minX, height: 5)
                                    }
                                } else {
                                    self.bioLabel.text = bioString
                                    self.bioLabel.textColor = UIColor.black
//                                    let attributedString = NSMutableAttributedString(string: bioString).withLineSpacing(2)
//                                    attributedString.setF(font: UIFont(name: "\(Constants.globalFont)", size: 13)!, color: UIColor.black)
//                                    self.bioLabel.attributedText = attributedString
                                    self.bioLabel.setLineSpacing(lineSpacing: 4.0)
                                    self.bioLabel.numberOfLines = 3
                                    self.bioLabel.font = UIFont(name: "\(Constants.globalFont)", size: 13)!
                                    self.bioLabel.fadeIn()
                                    let tmp = self.actualFollowingLabel.frame.maxX - self.actualFollowersLabel.frame.minX
                                    self.bioLabel.frame = CGRect(x: self.actualFollowersLabel.frame.minX, y: fullNameLabel.frame.maxY + 10, width: tmp, height: 60)
                                }
//                                self.bioLabel.sizeToFit()
                                
                                //                self.bioLabel.isHidden = false
                                
                                let buttonsWidth = 130
                                let buttonsHeight = 35
                                let paddingBetween = 10
                                let buttonsY = self.bioLabel.frame.maxY + 15
                                let followx = (Int(UIScreen.main.bounds.width) / 2) - (paddingBetween/2) - buttonsWidth
                                
                                messageButton.frame = CGRect(x: (Int(UIScreen.main.bounds.width) / 2) + (paddingBetween/2), y: Int(buttonsY), width: buttonsWidth, height:buttonsHeight)
                                followButton.frame = CGRect(x: followx, y: Int(buttonsY), width:  Int(buttonsWidth), height: buttonsHeight)
                                followButton.isHidden = false
                                messageButton.isHidden = false
                                if Auth.auth().currentUser?.uid == uidOfProfile {
                                    print("* current user, adding edit profile button")
                                    editProfileButton.frame = CGRect(x: (Int(UIScreen.main.bounds.width) / 2) + (paddingBetween/2), y: Int(buttonsY), width: 140, height:buttonsHeight)
                                    editProfileButton.center.x = UIScreen.main.bounds.width / 2
                                    editProfileButton.fadeIn()
                                }
                                //                messageButton.isHidden = false
                                //                followButton.isHidden = false
                                
                                //                tabBarView.frame = CGRect(x: 0, y: followButton.frame.maxY + 20, width: UIScreen.main.bounds.width, height: 50)
                                tabBarView.frame = CGRect(x: 0, y: followButton.frame.maxY + 20, width: 0, height: 0)
                                topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: tabBarView.frame.maxY)
                                tabBarView.layer.cornerRadius = 12
                                postsCollectionView.frame = CGRect(x: 0, y: topWhiteView.frame.maxY - 8, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - topWhiteView.frame.maxY - 5)
                                if uidOfProfile != "" && Auth.auth().currentUser?.uid != uidOfProfile {
                                    postsCollectionView.frame = CGRect(x: 0, y: topWhiteView.frame.maxY - 8, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - topWhiteView.frame.maxY + 8)
                                }
                                
                                var isValidStory = false
                                if data["latest_story_timestamp"] != nil {
                                    print("* user has a recent story: \(data["latest_story_timestamp"])")
                                    if let timestamp: Timestamp = data["latest_story_timestamp"] as? Timestamp {
                                        let story_date: Date = timestamp.dateValue()
                                        let timeToLive: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours
                                        print("* time since (hours): \(Date().timeIntervalSince(story_date))")
                                        let isExpired = Date().timeIntervalSince(story_date) >= timeToLive
                                        if isExpired != true {
                                            print("* valid story!")
                                            isValidStory = true
                                        }
                                    }
                                    
                                }
                                if isValidStory {
                                    print("* valid story")
                                    profilePicImage.isUserInteractionEnabled = true
                                    profilePicImage.condition = .init(display: .unseen, color: .custom(colors: [hexStringToUIColor(hex: Constants.primaryColor), .blue, hexStringToUIColor(hex: Constants.primaryColor).withAlphaComponent(0.6)]))
                                    hasValidStory = true
                                } else if (addToStoryButton.isHidden == false) {
                                    hasValidStory = false
                                    print("* no valid story")
                                    profilePicImage.condition = .init(display: .none, color: .none)
                                    var yourViewBorder = CAShapeLayer()
                                    yourViewBorder.strokeColor = hexStringToUIColor(hex: Constants.primaryColor).cgColor
                                    yourViewBorder.lineDashPattern = [4, 3]
                                    yourViewBorder.frame = profilePicImage.bounds
                                    yourViewBorder.fillColor = nil
                                    yourViewBorder.path = UIBezierPath(roundedRect: profilePicImage.bounds, cornerRadius: profilePicImage.layer.cornerRadius).cgPath
                                    profilePicImage.layer.addSublayer(yourViewBorder)
                                } else {
                                    hasValidStory = false
                                    profilePicImage.condition = .init(display: .none, color: .none)
                                }
                                
                                db.collection("followers").document(uidOfProfile).getDocument() {(userResult, err4) in
                                    let userVals = userResult?.data() as? [String: Any]
                                    let followerCount = userVals?["followers_count"] as? Int ?? 0
                                    self.followersButton.setTitle("\(followerCount.roundedWithAbbreviations)", for: .normal)
                                    //                    self.followersButton.sizeToFit()
                                    self.followersButton.frame = CGRect(x: actualFollowersLabel.frame.minX, y: 0, width: self.actualFollowersLabel.frame.width, height: 25)
                                    self.followersButton.center.x = self.actualFollowersLabel.center.x
                                    self.followersButton.center.y = self.profilePicImage.center.y - 10
                                    print("* FOLLOWERS COUNT [z]: \(followerCount)")
                                    self.followersButton.fadeIn()
                                }
                                db.collection("following").document(uidOfProfile).getDocument() {(userResult, err4) in
                                    let userVals = userResult?.data() as? [String: Any]
                                    let followingCount = userVals?["following_count"] as? Int ?? 0
                                    print("* FOLLOWING COUNT [z]: \(followingCount)")
                                    self.followingButton.setTitle("\(followingCount.roundedWithAbbreviations)", for: .normal)
                                    //                    self.followingButton.titleLabel?.text = "\(followingCount)"
                                    self.followingButton.frame = CGRect(x: actualFollowingLabel.frame.minX, y: 0, width: self.actualFollowingLabel.frame.width, height: 25)
                                    self.followingButton.center.x = self.actualFollowingLabel.center.x
                                    self.followingButton.center.y = self.followersButton.center.y
                                    self.followingButton.fadeIn()
                                }
                                followingButton.isUserInteractionEnabled = true
                                followingButton.backgroundColor = .clear
                                followersButton.isUserInteractionEnabled = true
                                followersButton.backgroundColor = .clear
                                
                            } else {
                                print("* some error collecting info on user")
                            }
                            
                        }
                    }
                }
                
            }
        }
        
    }
    @IBAction func editProfilePressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "editProfileVC") as? EditProfileVC {
            print("* opening profile list")
            self.navigationController?.pushViewController(vc, animated: true)
           
            
        }
    }
    @IBAction func addToStoryPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        print("pushing camera view")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController
        vc?.modalPresentationStyle = .fullScreen
        NextLevel.shared.devicePosition = .back
        var parentCollectionView = self.view.findViewController()
        parentCollectionView?.present(vc!, animated: true)
    }
    @IBAction func followingPressed(_ sender: Any) {
        let currentFollow = Int((followingButton.titleLabel?.text!)!) ?? 0
        print("* following button pressed")
        openFollowingList(withUID: uidOfProfile, numFollowing: currentFollow)
    }
    @IBAction func followersPressed(_ sender: Any) {
        let currentFollow = Int((followersButton.titleLabel?.text!)!) ?? 0
        print("* follower button pressed")
        openFollowersList(withUID: uidOfProfile, numFollowers: currentFollow)
    }
    func openFollowingList(withUID: String, numFollowing: Int) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userListViewController") as? userListViewController {
            vc.userConfig = userListConfig(type: "following", originalAuthorID: withUID, postID: "", numberToPutInFront: numFollowing)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    func openFollowersList(withUID: String, numFollowers: Int) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userListViewController") as? userListViewController {
            vc.userConfig = userListConfig(type: "followers", originalAuthorID: withUID, postID: "", numberToPutInFront: numFollowers)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            navigationController?.pushViewController(vc, animated: true)
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
    @IBAction func profilePicTingTapped(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        openStoryForuser()
    }
    func openStoryForuser() {
        let now = NSDate().timeIntervalSince1970
        let oneDayAgo = now - (60 * 60 * 24)
        let storiesRef = db.collection("stories")
        let userStories = storiesRef.document(uidOfProfile).collection("stories").whereField("createdAt", isLessThan: now).whereField("createdAt", isGreaterThan: oneDayAgo).order(by: "createdAt", descending: false).limit(to: 20)
        
        userStories.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let mainPostDispatchQueue = DispatchGroup()
                if querySnapshot!.isEmpty {
                    print("* detected empty story for \(self.uidOfProfile)")
                } else {
                    for document in querySnapshot!.documents {
                        print("* \(document.documentID) => \(document.data())")
                        let values = document.data()  as? [String: Any]
                        var storyToPresent = storyPost()
                        storyToPresent.imageUrl = values?["storyImageUrl"] as? String ?? ""
                        storyToPresent.createdAt = values?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                        storyToPresent.userID = document.documentID
                        storyToPresent.userImageUrl = self.currentProfilePic
                        storyToPresent.username = self.currentUsername
                        storyToPresent.author_full_name = self.fullNameLabel.text ?? ""
                        
                        if document == querySnapshot?.documents.last {
                            print("* reached last story, presenting")
                            self.storyVc = FAStoryViewController()
                            self.storyVc.delegate = self
//                            self.storyVc.story = FAStory(
                    
                            self.storyVc.modalPresentationStyle = .overFullScreen
                            self.storyVc.modalPresentationCapturesStatusBarAppearance = true
                    
                            self.present(self.storyVc, animated: true)
                        }
                        
                    }
                }
            }
        }

    }
    let interactor = Interactor()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.tabBarController?.navigationItem.hidesBackButton = true
        navigationController?.navigationItem.hidesBackButton = true
        if let destinationViewController = segue.destination as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
        if segue.identifier == "ShowPhotoPageView" {
            let nav = self.navigationController
            let vc = segue.destination as! PhotoPageContainerViewController
            nav?.delegate = vc.transitionController
            vc.transitionController.fromDelegate = self
            vc.transitionController.toDelegate = vc
            vc.delegate = self
            vc.currentIndex = self.selectedIndexPath.row
            vc.parentProfileController = self
            vc.username = self.currentUsername
            vc.hasValidStory = self.hasValidStory
            vc.imageUrl = self.currentProfilePic
            vc.isFollowing = self.isFollowing
            vc.imagePosts = self.imagePosts
            vc.profileUID = self.uidOfProfile
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if #available(iOS 11, *) {
            //Do nothing
        }
        else {
            
            //Support for devices running iOS 10 and below
            
            //Check to see if the view is currently visible, and if so,
            //animate the frame transition to the new orientation
            if self.viewIfLoaded?.window != nil {
                
                coordinator.animate(alongsideTransition: { _ in
                    
                    //This needs to be called inside viewWillTransition() instead of viewWillLayoutSubviews()
                    //for devices running iOS 10.0 and earlier otherwise the frames for the view and the
                    //collectionView will not be calculated properly.
                    self.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                    self.postsCollectionView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                    
                }, completion: { _ in
                    
                    //Invalidate the collectionViewLayout
                    self.postsCollectionView.collectionViewLayout.invalidateLayout()
                    
                })
                
            }
            //Otherwise, do not animate the transition
            else {
                
                self.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                self.postsCollectionView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                
                //Invalidate the collectionViewLayout
                self.postsCollectionView.collectionViewLayout.invalidateLayout()
                
            }
        }
        
    }
    
    func getImageViewFromCollectionViewCell(for selectedIndexPath: IndexPath) -> UIImageView {
        
        //Get the array of visible cells in the collectionView
        let visibleCells = self.postsCollectionView.indexPathsForVisibleItems
        
        //If the current indexPath is not visible in the collectionView,
        //scroll the collectionView to the cell to prevent it from returning a nil value
        if !visibleCells.contains(self.selectedIndexPath) {
            
            //Scroll the collectionView to the current selectedIndexPath which is offscreen
            self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredVertically, animated: false)
            
            //Reload the items at the newly visible indexPaths
            self.postsCollectionView.reloadItems(at: self.postsCollectionView.indexPathsForVisibleItems)
            self.postsCollectionView.layoutIfNeeded()
            
            //Guard against nil values
            guard let guardedCell = (self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts) else {
                //Return a default UIImageView
                return UIImageView(frame: CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0))
            }
            //The PhotoCollectionViewCell was found in the collectionView, return the image
            return guardedCell.previewImage
        }
        else {
            
            //Guard against nil return values
            guard let guardedCell = self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts else {
                //Return a default UIImageView
                return UIImageView(frame: CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0))
            }
            //The PhotoCollectionViewCell was found in the collectionView, return the image
            return guardedCell.previewImage
        }
        
    }
    
    //This function prevents the collectionView from accessing a deallocated cell. In the
    //event that the cell for the selectedIndexPath is nil, a default CGRect is returned in its place
    func getFrameFromCollectionViewCell(for selectedIndexPath: IndexPath) -> CGRect {
        
        //Get the currently visible cells from the collectionView
        let visibleCells = self.postsCollectionView.indexPathsForVisibleItems
        
        //If the current indexPath is not visible in the collectionView,
        //scroll the collectionView to the cell to prevent it from returning a nil value
        if !visibleCells.contains(self.selectedIndexPath) {
            
            //Scroll the collectionView to the cell that is currently offscreen
            self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredVertically, animated: false)
            
            //Reload the items at the newly visible indexPaths
            self.postsCollectionView.reloadItems(at: self.postsCollectionView.indexPathsForVisibleItems)
            self.postsCollectionView.layoutIfNeeded()
            
            //Prevent the collectionView from returning a nil value
            guard let guardedCell = (self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts) else {
                return CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0)
            }
            
            return guardedCell.frame
        }
        //Otherwise the cell should be visible
        else {
            //Prevent the collectionView from returning a nil value
            guard let guardedCell = (self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts) else {
                return CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0)
            }
            //The cell was found successfully
            return guardedCell.frame
        }
    }
}
extension MyProfileViewController: FAStoryDelegate, FAStoryViewControllerDelegate {
    func dismissButtonImage() -> UIImage? {
        nil
    }
    
    var borderWidth: CGFloat? {
        return 0
    }
    
    var borderColorUnseen: UIColor? {
        UIColor.blue.withAlphaComponent(0.5)
    }
    
    var borderColorSeen: UIColor? {
        .clear
    }
    
    func didSelect(row: Int) {
        
    }
    
    
}
extension MyProfileViewController: PhotoPageContainerViewControllerDelegate {
    
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int) {
        self.selectedIndexPath = IndexPath(row: currentIndex, section: 0)
        self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredVertically, animated: false)
    }
}
extension MyProfileViewController: UIViewControllerTransitioningDelegate {
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return DismissAnimator()
//    }
//
//    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        return interactor.hasStarted ? interactor : nil
//    }
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let t = ModalPresentationAnimator(duration: 0.3, dismiss: false, topDistance: 0, rasterizing: false)
        t.delegate = self
        return t
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let _transition = ModalPresentationAnimator(duration: 0.3, dismiss: true, topDistance: 0, rasterizing: false)
        
        _transition.delegate = self
        
        //
        // Check the interaction controller
        //
        if let _interactor = (dismissed as? FAStoryViewController)?.dismissInteractionController {
            _transition.dismissInteractionController = _interactor
        } else if let _interactor = (dismissed as? FAStoryContainer)?.dismissInteractionController {
            _transition.dismissInteractionController = _interactor
        }
        return _transition
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let animator = animator as? MainTransitionAnimator,
            let interactionController = animator.dismissInteractionController,
            interactionController.interactionInProgress
            else {
                return nil
        }
        return interactionController
    }
}
extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
extension UIView {
    func pushScrollingTransitionUp(_ duration:CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
                                                            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = CATransitionSubtype.fromTop
        animation.duration = duration
        layer.add(animation, forKey: nil)
    }
    func pushScrollingTransitionDown(_ duration:CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
                                                            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = CATransitionSubtype.fromBottom
        animation.duration = duration
        layer.add(animation, forKey: nil)
    }
}
extension Int {
    var roundedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 10000
        let million = number / 1000000
        if million >= 1.0 {
            return "\(round(million*10)/10)M"
        }
        else if thousand >= 1.0 {
            return "\(round(thousand*10)/10)K"
        }
        else {
            if number >= 1000 {
                return "\(self.delimiter)"
            } else {
                return "\(self)"
            }
            
        }
    }
}
extension Int {
    private static var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        return numberFormatter
    }()
    
    var delimiter: String {
        return Int.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
extension MyProfileViewController: ZoomAnimatorDelegate {
    
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
        print("* [trans] transition will start")
    }
    
    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
        let cell = self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as! userProfileImagePosts
        
        let cellFrame = self.postsCollectionView.convert(cell.frame, to: self.view)
        
        if cellFrame.minY < self.postsCollectionView.contentInset.top {
            self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .top, animated: false)
        } else if cellFrame.maxY > self.view.frame.height - self.postsCollectionView.contentInset.bottom {
            self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .bottom, animated: false)
        }
        print("* [trans] transition did end")
    }
    
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        
        //Get a guarded reference to the cell's UIImageView
        let referenceImageView = getImageViewFromCollectionViewCell(for: self.selectedIndexPath)
        print("* [trans] setting reference image")
        return referenceImageView
    }
    
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        
        self.view.layoutIfNeeded()
        self.postsCollectionView.layoutIfNeeded()
        
        //Get a guarded reference to the cell's frame
        let unconvertedFrame = getFrameFromCollectionViewCell(for: self.selectedIndexPath)
        
        let cellFrame = self.postsCollectionView.convert(unconvertedFrame, to: self.view)
        
        if cellFrame.minY < self.postsCollectionView.contentInset.top {
            return CGRect(x: cellFrame.minX, y: self.postsCollectionView.contentInset.top, width: cellFrame.width, height: cellFrame.height - (self.postsCollectionView.contentInset.top - cellFrame.minY))
        }
        print("* [trans] reference imageview frame in trans view")
        print("* [trans] returning \(cellFrame)")
        print("* top view comtroller: \(UIApplication.topViewController())")
        if let _ = UIApplication.topViewController() as? PhotoPageContainerViewController {
            zoomAnimator.transitionImageView?.isHidden = false
            return cellFrame
        } else {
            print("* DETECTED NON PROFILE TOP VIEW")
            zoomAnimator.transitionImageView?.isHidden = true
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        
    }
    
}
extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
extension NSMutableAttributedString {
    func withLineSpacing(_ spacing: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.lineSpacing = spacing
        attributedString.addAttribute(.paragraphStyle,
                                      value: paragraphStyle,
                                      range: NSRange(location: 0, length: string.count))
        return NSAttributedString(attributedString: attributedString)
    }
}
extension NSMutableAttributedString {
    func setFontFace(font: UIFont, color: UIColor? = nil) {
        beginEditing()
        self.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: self.length)
        ) { (value, range, stop) in

            if let f = value as? UIFont,
              let newFontDescriptor = f.fontDescriptor
                .withFamily(font.familyName)
                .withSymbolicTraits(f.fontDescriptor.symbolicTraits) {

                let newFont = UIFont(
                    descriptor: newFontDescriptor,
                    size: font.pointSize
                )
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
                if let color = color {
                    removeAttribute(
                        .foregroundColor,
                        range: range
                    )
                    addAttribute(
                        .foregroundColor,
                        value: color,
                        range: range
                    )
                }
            }
        }
        endEditing()
    }
}
extension UILabel {

    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {

        guard let labelText = self.text else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        paragraphStyle.alignment = NSTextAlignment.center
        let attributedString:NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

        // (Swift 4.2 and above) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))


        // (Swift 4.1 and 4.0) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        attributedString.setFontFace(font: UIFont(name: "\(Constants.globalFont)", size: 13)!, color: .black)
        
        self.attributedText = attributedString
    }
}



// ==================================================== //
// MARK: UIViewControllerTransitioningDelegate
// ==================================================== //
extension MyProfileViewController: ModalPresentationAnimatorProtocol {

    
    func didComplete(_ completed: Bool, isDismissal: Bool) {
        if completed && isDismissal, storyVc != nil {
            storyVc = nil
        }
    }
    
}

