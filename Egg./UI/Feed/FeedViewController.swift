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
import NextLevel
import ViewAnimator
import DGElasticPullToRefresh
import GoogleMobileAds
import Zoomy

class imagePost {
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
    var thumbNailImageURL = ""
    var isLiked = false
    var isSaved = false
    var hasValidStory = false
    var previewProfilePics: [String] = []
    var previewUserNames: [String] = []
    var numOfLikeMindedLIkes: Int = 0
    var usernameToShow: String = ""
    var storageRefForThumbnailImage = ""
    var contentNature = 0 // 0 for image, 1 for video?
}
struct storyPost {
    var username = ""
    var postID = ""
    var userID = ""
    var imageUrl = ""
    var userImageUrl = ""
    var thumbNailImageURL = ""
    var viewCount = 0
    var location = ""
    var createdAt = Double(0)
    var imageHash = ""
    var isMyStory = false
    var isEmpty = false
    var author_full_name = ""
}
enum StorageType {
    case userDefaults
    case fileSystem
}
//, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource
class FeedViewController: UIViewController, UITableViewDelegate, SkeletonTableViewDataSource, GADNativeAdDelegate, GADNativeAdLoaderDelegate {
    // ==================================================== //
    // MARK: AD Stuffs
    // ==================================================== //
    weak open var prefetchDataSource: UITableViewDataSourcePrefetching?
    /// The native ads.
    var nativeAds = [GADNativeAd]()
    /// The ad loader that loads the native ads.
    var adLoader: GADAdLoader!
    /// The ad unit ID from the AdMob UI.
    let adUnitID = "ca-app-pub-2174656505812203/9454834911"
    var numReloads = 0
    // MARK: - GADAdLoaderDelegate
    public func adLoader(_ adLoader: GADAdLoader,
                         didReceive nativeAd: GADNativeAd) {
        print("* [AD DEBUG] received native ad \(nativeAd)")
        // Set ourselves as the native ad delegate to be notified of native ad events.
        nativeAd.delegate = self
        //        nativeAds.append(nativeAd)
        let latestVal = getIndexOfLatestAd()
        if latestVal == -1 {
            print("* first ad, appending")
            //            imagePosts?.append(nativeAd)
            if imagePosts!.count > 3 {
                                print("* greater than 3 posts")
                                imagePosts?.insert(nativeAd, at: 3)
                self.postsTableView.reloadData()
//                imagePosts?.append(nativeAd)
            }
        } else {
            if latestVal + 4 < imagePosts!.count {
                                print("* inserting ad at \(latestVal + 4)")
                
                                imagePosts?.insert(nativeAd, at: latestVal + 4)
                self.postsTableView.reloadData()
//                imagePosts?.append(nativeAd)
            } else {
                print("* not enough posts to put another ad")
            }
        }
    }
    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        // The adLoader has finished loading ads, and a new request can be sent.
        print("* [AD DEBUG] finished loading ads")
    }
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        
        print("* [AD DEBUG] \(adLoader) failed with error: \(error.localizedDescription)")
        //        print("* trying again")
        //        adLoader.load(GADRequest())
    }
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        // The native ad was shown.
        print("* [AD DEBUG] recorded impression")
    }
    
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        // The native ad was clicked on.
        print("* [AD DEBUG] ad has been clicked on")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        // The native ad will present a full screen view.
        print("* [AD DEBUG] presenting fullscreen view")
    }
    
    func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        // The native ad will dismiss a full screen view.
        print("* [AD DEBUG] will dismiss fullscreen view")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        // The native ad did dismiss a full screen view.
        print("* [AD DEBUG] did dismiss fullscreen view")
    }
    
    func nativeAdWillLeaveApplication(_ nativeAd: GADNativeAd) {
        // The native ad will cause the application to become inactive and
        // open a new application.
        print("* [AD DEBUG] OPENING NEW APPLICATION")
    }
    func getIndexOfLatestAd() -> Int {
        var retVal = -1
        var k=0
        for i in imagePosts! as [AnyObject] {
            if let _ = i as? GADNativeAd {
                retVal = k
            }
            k = k + 1
        }
        return retVal
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        if indexPath.row == 0 {
            return "storyHolderCell"
        } else {
            return "ImagePostCell"
        }
//        else if let _ = imagePosts?[indexPath.row-1] as? imagePost {
//            return "ImagePostCell"
//        } else {
//            return "FeedAdCell"
//        }
        
    }
    // ==================================================== //
    // MARK: tableView delegates
    // ==================================================== //
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ((imagePosts?.count ?? 0) + 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("* loading cell at index \(indexPath.row)")
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "storyHolderCell", for: indexPath) as! StoriesTableViewCell
            cell.storiesCollectionView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width / 3.5) * 1.777)
            print("* set collectionviewframe: \(cell.storiesCollectionView.frame)")
            return cell
        } else if let post = imagePosts?[indexPath.row-1] as? imagePost {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImagePostCell", for: indexPath) as! ImagePostTableViewCell
            
            cell.contentView.layer.cornerRadius = 8
            cell.contentView.clipsToBounds = true
            cell.contentView.backgroundColor = Constants.surfaceColor.hexToUiColor()
            cell.contentView.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
            cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
            cell.contentView.layer.shadowOpacity = 0.4
            cell.contentView.layer.shadowRadius = 12
            cell.contentView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
            cell.contentView.layer.borderWidth = 1
            
            
            cell.actualPost = post
            if post.location == "" {
                cell.styleCell(type: "imagePost", hasSubTitle: false)
            } else {
                cell.styleCell(type: "imagePost", hasSubTitle: true)
            }
            cell.tmpImageview.isHidden = true
            UIView.performWithoutAnimation {
                cell.firstusernameButton.setTitle(post.username, for: .normal)
                cell.secondusernameButton.setTitle(post.username, for: .normal)
            }
            cell.firstusernameButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
            cell.secondusernameButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
            //        cell.viewCommentsButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)", size: 14)
            cell.currentUserUsername = self.currentUserUsername
            cell.currentUserProfilePic = self.currentUserProfilePic
            
            cell.timeSincePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
            let timeSince = Date(timeIntervalSince1970: TimeInterval(post.createdAt ?? 0)).timeAgoDisplay()
            cell.timeSincePostedLabel.text = "\(post.username ?? "")    • \(timeSince)"
            cell.firstusernameButton.sizeToFit()
            cell.firstusernameButton.frame = CGRect(x: cell.firstusernameButton.frame.minX, y: cell.firstusernameButton.frame.minY, width: cell.firstusernameButton.frame.width, height: 14)
            
            
            
            cell.timeSincePostedLabel.frame = CGRect(x: cell.firstusernameButton.frame.minX, y: cell.firstusernameButton.frame.minY, width: cell.contentView.bounds.width - 30 - cell.firstusernameButton.frame.maxX, height: 14)
            let hash = post.imageHash ?? ""
            //        print("* using image hash \(hash)")
            
            cell.likeButton.setDefaultImage()
            cell.likeButton.contentMode = .scaleAspectFit
            cell.likeButton.imageView?.contentMode = .scaleAspectFit
            if ((post.isLiked) != nil) && post.isLiked == true {
                cell.likeButton.setImage(cell.likeButton.likedImage, for: .normal)
                cell.likeButton.isLiked = true
            }
            
            cell.updateCommentButtonLocation()
            
            cell.commentBubbleButton.setDefaultImage()
            cell.commentBubbleButton.contentMode = .scaleAspectFit
            cell.commentBubbleButton.imageView?.contentMode = .scaleAspectFit
            //        cell.commentBubbleButton.setNewLikeAmount(to: post?.commentCount ?? 0)
            
            cell.savePostButton.setDefaultImage()
            cell.savePostButton.contentMode = .scaleAspectFit
            cell.savePostButton.imageView?.contentMode = .scaleAspectFit
            if ((post.isSaved) != nil) && post.isSaved == true {
                cell.savePostButton.setImage(cell.savePostButton.likedImage, for: .normal)
                cell.savePostButton.isLiked = true
            }
            
            let hashedImage = UIImage(blurHash: hash, size: CGSize(width: 32, height: 32))
            cell.imageHash = hash
            cell.setPostImage(fromUrl: post.imageUrl)
            UIView.performWithoutAnimation {
                cell.locationButton.setTitle(post.location, for: .normal)
            }
            cell.postid = post.postID
            cell.userID = post.userID
            cell.secondusernameButton.sizeToFit()
            cell.secondusernameButton.frame = CGRect(x: cell.secondusernameButton.frame.minX, y: cell.secondusernameButton.frame.minY, width: cell.secondusernameButton.frame.width, height: 14)
            
            if ((post.hasValidStory) != nil) && post.hasValidStory == true {
                print("* valid story [post]")
                cell.profilePicImage.isUserInteractionEnabled = true
                cell.profilePicImage.condition = .init(display: .unseen, color: .custom(colors: [hexStringToUIColor(hex: Constants.primaryColor), .blue, hexStringToUIColor(hex: Constants.primaryColor).withAlphaComponent(0.6)]))
            } else {
                print("* no valid story [postt]")
                cell.profilePicImage.condition = .init(display: .none, color: .none)
            }
            if post.userImageUrl == "" {
                
                cell.profilePicImage.image = UIImage(named: "no-profile-img.jpeg")
                cell.profilePicImage.alpha = 0
                cell.profilePicImage.isHidden = false
                cell.profilePicImage.fadeIn()
            } else {
                cell.downloadImage(with: post.userImageUrl ?? "")
            }
            if Constants.isDebugEnabled {
                self.view.debuggingStyle = true
            }
            UIView.performWithoutAnimation {
                cell.likeButton.setTitle("", for: .normal)
            }
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            cell.parentViewController = self
            print("new post loading in: \(post.postID)")
            UIView.performWithoutAnimation {
                cell.commentBubbleButton.setTitle("", for: .normal)
            }
            cell.postIndex = indexPath.row-1
            addZoombehavior(for: cell.mainPostImage, settings: .instaZoomSettings)
            return cell
        } else {
            // show ad every fourth post
            let nativeAd = imagePosts?[indexPath.row-1] as! GADNativeAd
            nativeAd.rootViewController = self
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedAdTableViewCell", for: indexPath) as! FeedAdTableViewCell
            
            cell.styleCell(usingAd: nativeAd)
            cell.selectionStyle = .none
            cell.nativeAdView.nativeAd = nativeAd
            cell.backgroundColor = .clear
            cell.contentView.layer.cornerRadius = 8
            cell.contentView.clipsToBounds = true
            cell.contentView.backgroundColor = Constants.surfaceColor.hexToUiColor()
            cell.contentView.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
            cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
            cell.contentView.layer.shadowOpacity = 0.4
            cell.contentView.layer.shadowRadius = 12
            cell.contentView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
            cell.contentView.layer.borderWidth = 1
            return cell
        }
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return ((UIScreen.main.bounds.width / 3.5) * 1.7777) + 35
        } else {
            print("* returning 800 for estimated height")
            
            return 800
        }
        
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "searchHeader") as? TableHeader
        let header = UILabel(frame: CGRect(x: 20, y: 5, width: 100, height: 20))
        header.text = "Stories"
        header.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 20)
        return header
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    func getAllCells() -> [UITableViewCell] {
        
        var cells = [UITableViewCell]()
        // assuming tableView is your self.tableView defined somewhere
        for j in 0...postsTableView.numberOfRows(inSection: 0)-1
        {
            if let cell = postsTableView.cellForRow(at: NSIndexPath(row: j, section: 0) as IndexPath) {
                
                cells.append(cell)
            }
            
        }
        return cells
    }
    
    // ==================================================== //
    // MARK: IBOutlets
    // ==================================================== //
    
    let defaults = UserDefaults.standard
    
    
    @IBOutlet weak var storiesCollectionView: UICollectionView!
    @IBOutlet weak var postsTableView: UITableView!
    @IBOutlet weak var topGradientView: UIView!
    
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var MessagesButton: UIButton!
    @IBOutlet weak var addPostButton: UIButton!
    
    @IBOutlet weak var brodiesBanner: UIImageView!
    
    @IBOutlet weak var notificationsHolder: UIView!
    @IBOutlet weak var primaryRedNotifBar: UIView!
    @IBOutlet weak var triangleRedNotif: UIView!
    @IBOutlet weak var heartImage: UIImageView!
    @IBOutlet weak var numNewLikesLabel: UILabel!
    @IBOutlet weak var commentImage: UIImageView!
    @IBOutlet weak var numNewCommentsLabel: UILabel!
    @IBOutlet weak var personImage: UIImageView!
    @IBOutlet weak var numNewFollowsLabel: UILabel!
    
    var imagePosts: [AnyObject]? = []
    
    private var db = Firestore.firestore()
    
    var hasReachedEndOfFeed = false
    
    
    
    // ==================================================== //
    // MARK: public variables
    // ==================================================== //
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    
    var followingUIDs: [String] = [""]
    
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    // ==================================================== //
    // MARK: viewdidload
    // ==================================================== //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        MessagesButton.setTitle("", for: .normal)
        addPostButton.setTitle("", for: .normal)
        
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
        
        let brodieY = 40
        brodiesBanner.frame = CGRect(x: 0, y: brodieY, width: 80, height: Int(self.topWhiteView.frame.height) - brodieY - 5)
        brodiesBanner.center.x = self.topWhiteView.center.x
        //        MessagesButton.addBaseShadow()
        //        MessagesButton.layer.cornerRadius = Constants.borderRadius
        MessagesButton.frame = CGRect(x: UIScreen.main.bounds.width - 40 - 20, y: 45, width: 47, height: 35)
        MessagesButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        
        //        MessagesButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        //        MessagesButton.backgroundColor = hexStringToUIColor(hex: Constants.secondaryColor)
        
        postsTableView.delegate = self
        postsTableView.dataSource = self
        postsTableView.rowHeight = 900
        postsTableView.backgroundColor = .clear
        //        postsTableView.frame = CGRect(x: 0, y: topWhiteView.frame.maxY + 30, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 120)
        postsTableView.frame = CGRect(x: 0, y: topWhiteView.frame.maxY - 10, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 120 - 50)
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
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "36217ef7638df8c0785a5b7210b6660c", GADSimulatorID ]
        let options = GADMultipleAdsAdLoaderOptions()
        options.numberOfAds = 2
        
        let aspectRatio = GADNativeAdMediaAdLoaderOptions()
        aspectRatio.mediaAspectRatio = .square
        // Prepare the ad loader and start loading ads.
        adLoader = GADAdLoader(adUnitID: adUnitID,
                               rootViewController: self,
                               adTypes: [.native],
                               options: [aspectRatio])
        adLoader.delegate = self
        postsTableView.register(UINib(nibName: "FeedAdTableViewCell", bundle: nil),
                                forCellReuseIdentifier: "FeedAdTableViewCell")
        
        if Auth.auth().currentUser?.uid == nil {
        } else {
            self.db.collection("user-locations").document(Auth.auth().currentUser!.uid).getDocument() {(currentUserResult, err4) in
                let currentuserVals = currentUserResult?.data() as? [String: Any]
                self.currentUserUsername = currentuserVals?["username"] as? String ?? ""
                self.currentUserProfilePic = currentuserVals?["profileImageURL"] as? String ?? ""
                self.downloadLatestProfilePic(usingUrl: currentuserVals?["profileImageURL"] as? String ?? "")
            }
            //            getPosts()
            let userID = Auth.auth().currentUser?.uid
            let followersRef = db.collection("followers")
            query = followersRef.whereField("followers", arrayContains: userID!).whereField("last_post.createdAt", isNotEqualTo: false).order(by: "last_post.createdAt", descending: true).limit(to: 3)
            //            print("* checking sub-followers/\()")
            //            query = db.collectionGroup("sub-followers").whereField("uid", isEqualTo: userID ?? "").limit(to: 3)
            
            db.collection("following").document(userID!).getDocument {
                (document, error) in
                if let document = document, document.exists {
                    self.followingUIDs = ((document.data() as? [String: NSObject])?["following"] as? [String])!
                    print("* collected following IDs = \(self.followingUIDs)")
                }
            }
            getPosts()
        }
        if Constants.isDebugEnabled {
            //            var window : UIWindow = UIApplication.shared.keyWindow!
            //            window.showDebugMenu()
            self.view.debuggingStyle = true
        }
        postsTableView.reloadData()
        postsTableView.isSkeletonable = true
        postsTableView.showAnimatedSkeleton(usingColor: .clouds, transition: .crossDissolve(0.25))
        
        MessagesButton.backgroundColor = .clear
        Analytics.logEvent("initial_feed_loaded", parameters: nil)
        // Initialize tableView
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        //        loadingView.tintColor = UIColor(red: 78/255.0, green: 221/255.0, blue: 200/255.0, alpha: 1.0)
        loadingView.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        postsTableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            // Add your logic here
            // Do not forget to call dg_stopLoading() at the end
            self?.imagePosts?.removeAll()
            self?.documents.removeAll()
            self?.hasReachedEndOfFeed = false
            let userID = Auth.auth().currentUser?.uid
            let followersRef = self?.db.collection("followers")
            self?.query = followersRef?.whereField("followers", arrayContains: userID!).whereField("last_post.createdAt", isNotEqualTo: false).order(by: "last_post.createdAt", descending: true).limit(to: 3)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            let indexPath = IndexPath(row: 0, section: 0)
            let storyHolder = self?.postsTableView.cellForRow(at: indexPath)
            if let storyHolder = storyHolder as? StoriesTableViewCell {
                print("* RELOADING STORIES")
                storyHolder.reloadAllStoryComponents()
            }
            self?.numReloads = 0
            self?.getPosts()
        }, loadingView: loadingView)
        //        postsTableView.dg_setPullToRefreshFillColor(UIColor(red: 57/255.0, green: 67/255.0, blue: 89/255.0, alpha: 1.0))
        postsTableView.dg_setPullToRefreshFillColor(hexStringToUIColor(hex: Constants.secondaryColor))
        postsTableView.dg_setPullToRefreshBackgroundColor(postsTableView.backgroundColor!)
        
        getNotificationsCount()
        
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return ((UIScreen.main.bounds.width / 3.5) * 1.7777) + 35
        } else {
            if let _ = imagePosts?[indexPath.row-1] as? GADNativeAd {
                return UIScreen.main.bounds.width + 20 + 60 + 100
            } else {
                let post = imagePosts?[indexPath.row-1] as! imagePost
                let photoHeight = UIScreen.main.bounds.width * 1.25 + 20
                let userStuffheight = 15 + 7 + 40 + 10 + 20
                let captionFont = UIFont(name: "\(Constants.globalFont)", size: 14)
                let captionString = "\(post.username)  \(post.caption ?? "")"
                print("* cap string: \(captionString)")
                let captionWidth = UIScreen.main.bounds.width - 30
                let expectedLabelHeight = captionString.height(withConstrainedWidth: captionWidth, font: captionFont!)
                print("* expected label height: \(expectedLabelHeight)")
                
                
                var captionHeight = 0
                if expectedLabelHeight <= 20 {
                    captionHeight = 20
                } else if (expectedLabelHeight > 20) {
                    captionHeight = 40
                }
                
                var likedByHeight = 0
                if post.previewProfilePics.count > 0 {
                    likedByHeight = 8 + 25 + 10
                } else {
                    likedByHeight = 10
                }
                let commentButtonHeight = 30
                let estimatedHeight = Int(photoHeight) + userStuffheight + captionHeight + 12 + 10 + likedByHeight + commentButtonHeight + 50
                print("* returning total estimated height: \(estimatedHeight)")
                return CGFloat(estimatedHeight)
                //                return 800
            }
            
        }
        
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
    func fetchSimilarUIDs(likesUIDs: [String]) -> [String] {
        var ret: [String] = []
        if followingUIDs.count > likesUIDs.count {
            // loop through likes
            for i in likesUIDs {
                if followingUIDs.contains(i) && ret.contains(i) == false {
                    ret.append(i)
                }
            }
        } else {
            // loop through follows
            for i in followingUIDs {
                if likesUIDs.contains(i) && ret.contains(i) == false {
                    ret.append(i)
                }
            }
        }
        return ret
    }
    
    func downloadLatestProfilePic(usingUrl: String) {
        if usingUrl != "" {
            print("* getting current user profile id")
            let resource = ImageResource(downloadURL: URL(string: usingUrl)!)
            KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
                switch result {
                case .success(let value):
                    print("* successfully got profile pic!")
                    DispatchQueue.global(qos: .background).async {
                        self.store(image: value.image,
                                   forKey: "profilepic",
                                   withStorageType: StorageType.fileSystem)
                    }
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
            
        }
        
    }
    // ==================================================== //
    // MARK: get notifications
    // using:
    //      - notificationsHolder
    //      - primaryRedNotifBar
    //      - triangleRedNotif
    //      - heartImage
    //      - numNewLikesLabel
    //      - commentImage
    //      - numNewCommentsLabel
    //      - personImage
    //      - numNewFollowsLabel
    // ==================================================== //
    func getNotificationsCount() {
        let userID = Auth.auth().currentUser?.uid
        if userID != nil {
            let notifQuery = db.collection("notifications").document(userID!)
            notifQuery.getDocument() { [self] (document, error) in
                if let document = document {
                    let data = document.data() as? [String: AnyObject]
                    let totalCount = data?["notifications_count"] as? Int ?? 0
                    let commentsCount = data?["num_comments_notifications"] as? Int ?? 0
                    let followersCount = data?["num_followers_notifications"] as? Int ?? 0
                    let numPostLikes = data?["num_likes_notifications"] as? Int ?? 0
                    let numCommentLikes = data?["num_comments_likes_notifications"] as? Int ?? 0
                    if commentsCount == 0 && followersCount == 0 && numPostLikes == 0 && numCommentLikes == 0 {
                        print("* user has no new notifications")
                    } else {
                        let redNotificationsCircle = UIView(frame: CGRect(x: 0, y: (tabBarController?.tabBar.getFrameForTabAt(index: 3)!.maxY)! - 20, width: 15, height: 15))
                        redNotificationsCircle.backgroundColor = Constants.universalRed.hexToUiColor()
                        redNotificationsCircle.center.x = CGFloat(Int((tabBarController?.tabBar.getFrameForTabAt(index: 3)!.centerX) ?? 0))
                        print("* 3rd tab bar x: \(Int(tabBarController?.tabBar.getFrameForTabAt(index: 3)!.centerX ?? 0))")
                        // Circular view
                        redNotificationsCircle.layer.cornerRadius = view.layer.bounds.width / 2
                        redNotificationsCircle.clipsToBounds = true
                        print("* latest notifications data: \(data)")
                        tabBarController?.view.addSubview(redNotificationsCircle)
                        tabBarController?.view.bringSubviewToFront(redNotificationsCircle)
                        if Constants.isDebugEnabled {
                            self.view.debuggingStyle = true
                        }
                        let heartFrame = self.tabBarController?.tabBar.getFrameForTabAt(index: 3)
                        let viewHeight = 50
                        self.notificationsHolder.frame = CGRect(x: 0, y: Int(UIScreen.main.bounds.height) - 100 - viewHeight, width: 100, height: viewHeight)
                        styleNotificationsFor(likesCount: numPostLikes + numCommentLikes, commentCount: commentsCount, followersCount: followersCount)
    //                    styleNotificationsFor(likesCount: 12525626, commentCount: 230456, followersCount: 936793)
                        self.notificationsHolder.frame = CGRect(x: 0, y: Int(UIScreen.main.bounds.height) - 100 - viewHeight, width: Int(numNewFollowsLabel.frame.maxX) + 20, height: viewHeight)
                        self.notificationsHolder.center.x = (heartFrame?.center.x)!
                        self.primaryRedNotifBar.frame = CGRect(x: 5, y: 5, width: Int(notificationsHolder.frame.width) - 10, height: viewHeight - 10 - 5)
                        self.primaryRedNotifBar.layer.cornerRadius = 8
                        primaryRedNotifBar.layer.masksToBounds = false
                        self.primaryRedNotifBar.backgroundColor = Constants.universalRed.hexToUiColor()
                        addRedShadow()
                        triangleRedNotif.frame = CGRect(x: 0, y: primaryRedNotifBar.frame.maxY - 1, width: 20, height: 10)
                        triangleRedNotif.center.x = notificationsHolder.frame.width / 2
                        setDownTriangle()
                        
                        let oldNotifFrame = self.notificationsHolder.frame
                        let newNotif = CGRect(x: self.notificationsHolder.frame.minX, y: self.notificationsHolder.frame.minY + 110, width: self.notificationsHolder.frame.width - 20, height: self.notificationsHolder.frame.height)
                        self.notificationsHolder.frame = newNotif
                        self.notificationsHolder.alpha = 1
                        self.notificationsHolder.isHidden = false
                        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                            self.notificationsHolder.frame = oldNotifFrame
                                   self.view.layoutIfNeeded()
                               }) { (_) in
                                   // Follow up animations...
                                   let seconds = 3.0
                                   DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                                       // Put your code which should be executed with a delay here
                                       UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                                                self.notificationsHolder.frame = newNotif
                                                  self.view.layoutIfNeeded()
                                              }) { (_) in
                                              }
                                       
                                   }
                           }
                    }
                    
                    
                }
            }
        }
        
    }
    func styleNotificationsFor(likesCount: Int, commentCount: Int, followersCount: Int) {
        let imageWidthHeight = 15
        let padding = 10
        let minY = ((Int(primaryRedNotifBar.frame.height) - imageWidthHeight) / 2) + 2
        if likesCount > 0 {
            heartImage.frame = CGRect(x: (Int(primaryRedNotifBar.frame.height) - imageWidthHeight) / 2, y: minY, width: imageWidthHeight, height: imageWidthHeight)
            numNewLikesLabel.text = "\(Double(likesCount).shortStringRepresentation)"
            numNewLikesLabel.sizeToFit()
            numNewLikesLabel.frame = CGRect(x: Int(heartImage.frame.maxX) + 5, y: minY, width: Int(numNewLikesLabel.frame.width), height: imageWidthHeight)
        } else {
            heartImage.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            numNewLikesLabel.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        
        if commentCount > 0 {
            commentImage.frame = CGRect(x: Int(numNewLikesLabel.frame.maxX) + padding, y: minY, width: imageWidthHeight, height: imageWidthHeight)
            numNewCommentsLabel.text = "\(Double(commentCount).shortStringRepresentation)"
            numNewCommentsLabel.sizeToFit()
            numNewCommentsLabel.frame = CGRect(x: Int(commentImage.frame.maxX) + 5, y: minY, width: Int(numNewCommentsLabel.frame.width), height: imageWidthHeight)
        } else {
            commentImage.frame = CGRect(x: numNewLikesLabel.frame.maxX + 1, y: 0, width: 0, height: 0)
            numNewCommentsLabel.frame = CGRect(x: numNewLikesLabel.frame.maxX + 1, y: 0, width: 0, height: 0)
        }
        
        if followersCount > 0 {
            personImage.frame = CGRect(x: Int(numNewCommentsLabel.frame.maxX) + padding, y: minY, width: imageWidthHeight, height: imageWidthHeight)
            numNewFollowsLabel.text = "\(Double(followersCount).shortStringRepresentation)"
            numNewFollowsLabel.sizeToFit()
            numNewFollowsLabel.frame = CGRect(x: Int(personImage.frame.maxX) + 5, y: minY, width: Int(numNewFollowsLabel.frame.width), height: imageWidthHeight)
        } else {
            personImage.frame = CGRect(x: numNewCommentsLabel.frame.maxX + 1, y: 0, width: 0, height: 0)
            numNewFollowsLabel.frame = CGRect(x: numNewCommentsLabel.frame.maxX + 1, y: 0, width: 0, height: 0)
        }
    }
    func setDownTriangle(){
            let heightWidth = triangleRedNotif.frame.size.width
            let path = CGMutablePath()

            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x:heightWidth/2, y: heightWidth/2))
            path.addLine(to: CGPoint(x:heightWidth, y:0))
            path.addLine(to: CGPoint(x:0, y:0))

            let shape = CAShapeLayer()
            shape.path = path
        shape.fillColor = Constants.universalRed.hexToUiColor().cgColor

            triangleRedNotif.layer.insertSublayer(shape, at: 0)
    }
    func addRedShadow() {
        self.primaryRedNotifBar.layer.shadowColor = Constants.universalRed.hexToUiColor().withAlphaComponent(0.7).cgColor
        self.primaryRedNotifBar.layer.shadowOffset = CGSize(width: 2, height: 4)
        self.primaryRedNotifBar.layer.shadowOpacity = 0.4
        self.primaryRedNotifBar.layer.shadowRadius = 4
        self.primaryRedNotifBar.backgroundColor = Constants.universalRed.hexToUiColor()
        
        self.triangleRedNotif.layer.shadowColor = Constants.universalRed.hexToUiColor().withAlphaComponent(0.7).cgColor
        self.triangleRedNotif.layer.shadowOffset = CGSize(width: 2, height: 4)
        self.triangleRedNotif.layer.shadowOpacity = 0.4
        self.triangleRedNotif.layer.shadowRadius = 4
//        self.triangleRedNotif.backgroundColor = Constants.universalRed.hexToUiColor()
    }
    // ==================================================== //
    // MARK: getPosts
    // ==================================================== //
    func getPosts() {
        let tmpHolder = imagePosts
        //        imagePosts = []
        //load next 5 posts + ad
        let userID = Auth.auth().currentUser?.uid
        if numReloads == 0 || numReloads % 2 == 0 {
            //            adLoader.load(GADRequest())
        }
        
        numReloads += 1
        //        let groupsFollowersRef = db.collection("groups").document("followers").
        query.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let mainPostDispatchQueue = DispatchGroup()
                if querySnapshot!.isEmpty {
                    print("* detected empty feed")
                    self.hasReachedEndOfFeed = true
                    self.postsTableView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.25))
                } else {
                    print("* posts returned: \(querySnapshot?.documents)")
                    mainPostDispatchQueue.enter()
                    for document in querySnapshot!.documents {
                        print("* got feed: \(document.documentID) => \(document.data())")
                        let useID = document.documentID
                        let values = document.data()
                        self.documents += [document]
                        if (values["last_post"] as? [String: Any])?["id"] == nil {
                            print("* user has never posted")
                            if querySnapshot!.documents.last == document {
                                    mainPostDispatchQueue.leave()
                            }
                            return
                        } else {
                            mainPostDispatchQueue.enter()
                        }
                        
                        
                        let last_post = (values["last_post"] as? [String: Any])?["id"] as! String
                        var post = Egg_.imagePost()
                        post.userID = useID
                        //                        print("* got post id: \(last_post)")
                        
                        // get more info on post based on post id and user id
                        self.db.collection("posts").document(useID).collection("posts").document(last_post).getDocument() {(postResult, err2) in
                            if let err2 = err2 {
                                print("Error getting documents: \(err2)")
                                mainPostDispatchQueue.leave()
                            } else {
                                let postVals = postResult?.data() as? [String: Any]
                                print("* size of post document: \(self.getDocumentSize(data: postVals ?? [:])) bytes")
                                //                                print("got post details: \(postVals)")
                                print("* post size estimation: \(self.getDocumentSize(data: postVals!))")
                                post.postID = last_post
                                post.commentCount = postVals?["comments_count"] as? Int ?? 0 // fix this
                                post.likesCount = postVals?["likes_count"] as? Int ?? 0 //1256784
                                print("* [DEBUG] liekes ocunt: \(postVals?["likes_count"])")
                                post.imageUrl = postVals?["postImageUrl"] as? String ?? ""
                                post.location = postVals?["location"] as? String ?? ""
                                post.caption = postVals?["caption"] as? String ?? ""
                                post.tags = postVals?["tags"] as? [String] ?? [""]
                                post.createdAt = postVals?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                                post.imageHash = postVals?["imageHash"] as? String ?? ""
                                
                                let similarUIDS = self.fetchSimilarUIDs(likesUIDs: postVals?["likes"] as? [String] ?? [""])
                                post.numOfLikeMindedLIkes = similarUIDS.count
                                var firstThreToShow: [String] = similarUIDS
                                if similarUIDS.count > 3 {
                                    firstThreToShow = Array(similarUIDS[0...2])
                                }
                                
                                //                                post.previewProfilePics = firstThreToShow
                                var actualProfilePicURLS: [String] = []
                                let profilePicDispatchQueue = DispatchGroup()
                                for i in firstThreToShow {
                                    profilePicDispatchQueue.enter()
                                    self.db.collection("user-locations").document(i).getDocument { res, er in
                                        if let er = er {
                                            print("Error getting documents: \(er)")
                                        } else {
                                            let prof = res?.data()?["profileImageURL"] as? String ?? ""
                                            print("* got another profile pic: \(i) => \(prof)")
                                            actualProfilePicURLS.append(prof)
                                            if i == firstThreToShow.first {
                                                post.usernameToShow = res?.data()?["username"] as? String ?? ""
                                            }
                                        }
                                        profilePicDispatchQueue.leave()
                                    }
                                }
                                print("* fetched similar UIDs => \(similarUIDS)")
                                self.db.collection("posts").document(useID).collection("posts").document(last_post).collection("likes").whereField("uid", isEqualTo: userID!).limit(to: 1).getDocuments() { (likesSnapshot, err) in
                                    if likesSnapshot!.isEmpty || err != nil {
                                        print("* user has not liked post")
                                        post.isLiked = false
                                    } else {
                                        post.isLiked = true
                                        print("* post is liked!")
                                    }
                                    self.db.collection("saved").document((Auth.auth().currentUser?.uid)!).collection("all_posts").document(last_post).getDocument() { (docy, errzz) in
                                        var isSaved = false
                                        if docy?.exists == true {
                                            print("* post is saved!")
                                            isSaved = true
                                        } else {
                                            isSaved = false
                                        }
                                        if errzz != nil {
                                            isSaved = false
                                        }
                                        // get more info on user (maybe story?)
                                        self.db.collection("user-locations").document(useID).getDocument() {(userResult, err3) in
                                            if let err3 = err3 {
                                                print("Error getting documents: \(err3)")
                                                mainPostDispatchQueue.leave()
                                                if querySnapshot!.documents.last == document {
                                                    mainPostDispatchQueue.leave()
                                                }
                                            } else {
                                                let userVals = userResult?.data() as? [String: Any]
                                                //                                        print("got more info on the user: \(userVals)")
                                                post.userImageUrl = userVals?["profileImageURL"] as? String ?? ""
                                                post.username = userVals?["username"] as? String ?? ""
                                                var isValidStory = false
                                                //                                            print("* latest story timestamp: \(userVals?["latest_story_timestamp"])")
                                                if userVals?["latest_story_timestamp"] != nil {
                                                    //                                                print("* user has a recent story: \(userVals?["latest_story_timestamp"])")
                                                    if let timestamp: Timestamp = userVals?["latest_story_timestamp"] as? Timestamp {
                                                        let story_date: Date = timestamp.dateValue()
                                                        let timeToLive: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours
                                                        let isExpired = Date().timeIntervalSince(story_date) >= timeToLive
                                                        if isExpired != true {
                                                            print("* valid story!")
                                                            isValidStory = true
                                                        }
                                                    }
                                                    
                                                }
                                                post.isSaved = isSaved
                                                post.hasValidStory = isValidStory
                                                profilePicDispatchQueue.notify(queue: .main) {
                                                    post.previewProfilePics = actualProfilePicURLS
                                                    self.imagePosts?.append(post)
                                                }
                                                
                                                mainPostDispatchQueue.leave()
                                                if querySnapshot!.documents.last == document {
                                                    print("* reached end of list, fetching current info")
                                                    //                                            print("reached end of document list, refreshing tableview")
                                                    self.db.collection("user-locations").document(Auth.auth().currentUser!.uid).getDocument() {(currentUserResult, err4) in
                                                        let currentuserVals = currentUserResult?.data() as? [String: Any]
                                                        self.currentUserUsername = currentuserVals?["username"] as? String ?? ""
                                                        self.currentUserProfilePic = currentuserVals?["profileImageURL"] as? String ?? ""
                                                        self.downloadLatestProfilePic(usingUrl: currentuserVals?["profileImageURL"] as? String ?? "")
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
                    
                }
                mainPostDispatchQueue.notify(queue: .main) {
                    self.postsTableView.dg_stopLoading()
                    //                    self.imagePosts = self.imagePosts!.sorted (by: {$0.createdAt > $1.createdAt})\
                    self.imagePosts = self.imagePosts!.sorted(by: {(obj1, obj2) -> Bool in
                        if let im1 = obj1 as? imagePost {
                            if let im2 = obj2 as? imagePost {
                                return im1.createdAt > im2.createdAt
                            } else {
                                print("* found ad while sorting, returning false")
                                return false
                            }
                        } else {
                            print("* found ad while sorting, returning false")
                            return false
                        }
                    })
                    if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                        print("* looks like we've reached the end of comments collection")
                        self.hasReachedEndOfFeed = true
                    } else {
                        DispatchQueue.main.async {
                            self.adLoader.load(GADRequest())
                            if self.postsTableView.isSkeletonActive {
                                self.postsTableView.stopSkeletonAnimation()
                                self.postsTableView.hideSkeleton(reloadDataAfter: true, transition: .crossDissolve(0.25))
                            } else {
                                self.postsTableView.reloadData()
                            }
                            if self.imagePosts?.count ?? 4 < 3 {
                                var cells = self.postsTableView.visibleCells
                                cells.remove(at: 0)
                                let animation = AnimationType.from(direction: .bottom, offset: 60.0)
                                UIView.animate(views: cells, animations: [animation])
                                print("* only three cells, animating")
                            }
                            
                        }
                        
                    }
                }
            }
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Trigger pagination when scrolled to last cell
        // Feel free to adjust when you? want pagination to be triggered
        if (indexPath.row == (imagePosts?.count ?? 2) - 2) && hasReachedEndOfFeed == false {
            
            print("* fetching more comments. Current comment count: \((imagePosts?.count ?? 2)-2)")
            paginate()
        }
    }
    
    func openProfileForUser(withUID: String) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
            if let navigator = self.parent?.navigationController {
                vc.uidOfProfile = withUID
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigator.pushViewController(vc, animated: true)
                
            }
        }
    }
    func paginate() {
        //This line is the main pagination code.
        //Firestore allows you to fetch document from the last queryDocument
        query = query.start(afterDocument: documents.last!).limit(to: 3)
        Analytics.logEvent("feed_loaded_more", parameters: nil)
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
extension Double {
    func storySimplifiedTimeAgo() -> String {
        let now = Date(timeIntervalSince1970: self)
        let secondsAgo = Int(Date().timeIntervalSince(now))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        if secondsAgo < minute {
            return "\(secondsAgo)s ago"
            
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)m ago"
            
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)h ago"
            
        } else if secondsAgo < week {
            return "\(secondsAgo / day)d ago"
        }
        return "\(secondsAgo / week)w ago"
    }
}
extension UITableViewCell {
    func addSeparatorLineToTop(){
        
        let lineFrame = CGRect(x: 0, y: 0, width: bounds.size.width, height: 2)
        let line = UIView(frame: lineFrame)
        line.backgroundColor = UIColor.lightGray
        addSubview(line)
    }
}
extension UIViewController {
    func store(image: UIImage,
               forKey key: String,
               withStorageType storageType: StorageType) {
        if let pngRepresentation = image.pngData() {
            switch storageType {
            case .fileSystem:
                if let filePath = filePath(forKey: key) {
                    do {
                        try pngRepresentation.write(to: filePath,
                                                    options: .atomic)
                    } catch let err {
                        print("Saving results in error: ", err)
                    }
                }
            case .userDefaults:
                UserDefaults.standard.set(pngRepresentation,
                                          forKey: key)
            }
        }
    }
    
    func retrieveImage(forKey key: String,
                       inStorageType storageType: StorageType) -> UIImage? {
        switch storageType {
        case .fileSystem:
            if let filePath = self.filePath(forKey: key),
               let fileData = FileManager.default.contents(atPath: filePath.path),
               let image = UIImage(data: fileData) {
                return image
            }
        case .userDefaults:
            if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
               let image = UIImage(data: imageData) {
                return image
            }
        }
        
        return nil
    }
    
    func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                 in: .userDomainMask).first else {
            return nil
        }
        
        return documentURL.appendingPathComponent(key + ".png")
    }
    
    
}
extension FeedViewController: Zoomy.Delegate {
    
    func didBeginPresentingOverlay(for imageView: Zoomable) {
        postsTableView.isScrollEnabled = false
    }
    
    func didEndPresentingOverlay(for imageView: Zoomable) {
        postsTableView.isScrollEnabled = true
    }
}
extension Double {
    var shortStringRepresentation: String {
        if self.isNaN {
            return "NaN"
        }
        if self.isInfinite {
            return "\(self < 0.0 ? "-" : "+")Infinity"
        }
        let units = ["", "k", "M"]
        var interval = self
        var i = 0
        while i < units.count - 1 {
            if abs(interval) < 1000.0 {
                break
            }
            i += 1
            interval /= 1000.0
        }
        // + 2 to have one digit after the comma, + 1 to not have any.
        // Remove the * and the number of digits argument to display all the digits after the comma.
        return "\(String(format: "%0.*g", Int(log10(abs(interval))) + 2, interval))\(units[i])"
    }
}
