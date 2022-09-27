//
//  PhotoPageContainerViewController.swift
//  FluidPhoto
//
//  Created by Masamichi Ueta on 2016/12/23.
//  Copyright © 2016 Masmichi Ueta. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseFirestore
import FirebaseAuth

protocol PhotoPageContainerViewControllerDelegate: class {
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int)
}

class PhotoPageContainerViewController: UIViewController, UIGestureRecognizerDelegate {

    enum ScreenMode {
        case full, normal
    }
    var currentMode: ScreenMode = .normal
    
    weak var delegate: PhotoPageContainerViewControllerDelegate?
    
    var pageViewController: UIPageViewController {
        return self.children[0] as! UIPageViewController
    }
    
    var currentViewController: PhotoZoomViewController {
        return self.pageViewController.viewControllers![0] as! PhotoZoomViewController
    }
    
    var imagePosts: [imagePost]? = []
    var currentIndex = 0
    var nextIndex: Int?
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var secondTopLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    var singleTapGestureRecognizer: UITapGestureRecognizer!
    
    var transitionController = ZoomTransitionController()
    
    var isFollowing = false
    var username = ""
    var profileUID = ""
    var imageUrl = ""
    var hasValidStory = false
    var shouldHideFollowbutton = true
    var shouldOpenCommentSection = false // should we open comment section once everything has loaded?
    var commentToOpen = ""
    var replyToOpen = ""
    
    var parentProfileController: UIViewController?
    
    private var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        self.navigationItem.setHidesBackButton(true, animated: true)
//        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanWith(gestureRecognizer:)))
//        self.panGestureRecognizer.delegate = self
//        self.pageViewController.view.addGestureRecognizer(self.panGestureRecognizer)

//        self.singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTapWith(gestureRecognizer:)))
//        self.pageViewController.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        
        styleTopAndBottom()
        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(PhotoZoomViewController.self)") as! PhotoZoomViewController
        vc.delegate = self
        vc.postIndex = self.currentIndex
        vc.actualPost = (self.imagePosts?[self.currentIndex])!
        vc.shouldOpenCommentSection = self.shouldOpenCommentSection
        vc.commentToOpen = self.commentToOpen
        vc.replyToOpen = self.replyToOpen
        let viewControllers = [
            vc
        ]
        navigationController?.navigationBar.isHidden = true
        self.pageViewController.setViewControllers(viewControllers, direction: .forward, animated: true, completion: nil)
    }
    @IBAction func goBackPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
//        navigation navigationController?.delegate = self
        _ = navigationController?.popViewController(animated: true)
    }
    func styleTopAndBottom() {
        topWhiteView.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
        self.topWhiteView.layer.masksToBounds = false
        self.topWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.topWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.topWhiteView.layer.shadowOpacity = 0.3
        self.topWhiteView.layer.shadowRadius = Constants.borderRadius
        backButton.setTitle("", for: .normal)
        
        backButton.frame = CGRect(x: 0, y: 35, width: 50, height: 60)
        backButton.tintColor = .darkGray
        
        topLabel.font = UIFont(name: Constants.globalFontMedium, size: 12)
        topLabel.text = "\(imagePosts?[0].username ?? "")"
        if imagePosts?[0].username ?? "" == "" {
            topLabel.text = "\(self.username)"
        }
        topLabel.textColor = .lightGray
        topLabel.sizeToFit()
//        topLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (topLabel.frame.width / 2), y: 50, width: topLabel.frame.width, height: topLabel.frame.height)
        topLabel.frame = CGRect(x: backButton.frame.maxX, y: 50, width: topLabel.frame.width, height: topLabel.frame.height)
        
        
        secondTopLabel.font = UIFont(name: Constants.globalFontBold, size: 12)
        secondTopLabel.text = "Posts"
        secondTopLabel.textColor = .black
        secondTopLabel.sizeToFit()
//        secondTopLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (secondTopLabel.frame.width / 2), y: topLabel.frame.maxY + 5, width: secondTopLabel.frame.width, height: secondTopLabel.frame.height)
        secondTopLabel.frame = CGRect(x: topLabel.frame.minX, y: topLabel.frame.maxY, width: secondTopLabel.frame.width, height: secondTopLabel.frame.height)
        
        
        
        if isFollowing {
            styleForFollowing()
        } else {
            styleForNotFollowing()
        }
        let buttonsWidth = 100
        let buttonsHeight = 35
        let paddingBetween = 10
        let buttonsY = 50
        let followx = (Int(UIScreen.main.bounds.width)) - buttonsWidth - 15
        let userIDz = Auth.auth().currentUser?.uid
        if profileUID == userIDz || shouldHideFollowbutton == true {
            followButton.isHidden = true
        }
        followButton.frame = CGRect(x: followx, y: Int(buttonsY), width:  Int(buttonsWidth), height: buttonsHeight)
    }
    @IBAction func followButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        print("* follow button pressed")
        if followButton.titleLabel?.text == "Follow" {
            styleForFollowing()
            if let parentProfileController = self.parentProfileController as? MyProfileViewController {
                parentProfileController.styleForFollowing()
                parentProfileController.isFollowing = true
            } else if let parentProfileController = self.parentProfileController as? SavedPostsViewController {
                print("* we are in saved posts view controller")
            }
            
            let timestamp = NSDate().timeIntervalSince1970
            self.db.collection("user-locations").document(userID!).getDocument { (document, err) in
                print("* doc: \(document)")
                if ((document?.exists) != nil) && document?.exists == true {
                    let data = document?.data()! as [String: AnyObject]
                    self.db.collection("followers").document(self.profileUID).collection("sub-followers").document(userID!).setData(["uid": userID!, "timestamp": Int(timestamp), "username": data["username"] as? String ?? ""]) { err in
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
            
            styleForNotFollowing()
            if let parentProfileController = self.parentProfileController as? MyProfileViewController {
                parentProfileController.styleForNotFollowing()
                parentProfileController.isFollowing = false
            } else {
                
            }
            
            self.db.collection("followers").document(self.profileUID).collection("sub-followers").document(userID!).delete() { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("succesfully unfollowed user!")
                }
            }
        }
    }
    func styleForFollowing() {
        self.followButton.setTitle("Following", for: .normal)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
        self.followButton.tintColor = .black
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 8
        self.followButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.followButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.followButton.setImage(UIImage(systemName: "chevron.down")?.applyingSymbolConfiguration(.init(pointSize: 8, weight: .semibold, scale: .medium))?.image(withTintColor: .black), for: .normal)
        self.followButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        let spacing = CGFloat(-10); // the amount of spacing to appear between image and title
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: -2, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    }
    func styleForNotFollowing() {
        self.followButton.setTitle("Follow", for: .normal)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: Constants.primaryColor)
        self.followButton.tintColor = .white
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 8
        self.followButton.setImage(nil, for: .normal)
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: self.view)
            
            var velocityCheck : Bool = false
            
            if UIDevice.current.orientation.isLandscape {
                velocityCheck = velocity.x < 0
            }
            else {
                velocityCheck = velocity.y < 0
            }
            if velocityCheck {
                return false
            }
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
//        if otherGestureRecognizer == self.currentViewController.scrollView.panGestureRecognizer {
//            if self.currentViewController.scrollView.contentOffset.y == 0 {
//                return true
//            }
//        }
        
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
//            self.currentViewController.scrollView.isScrollEnabled = false
            self.transitionController.isInteractive = true
            let _ = self.navigationController?.popViewController(animated: true)
        case .ended:
            if self.transitionController.isInteractive {
//                self.currentViewController.scrollView.isScrollEnabled = true
                self.transitionController.isInteractive = false
                self.transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        default:
            if self.transitionController.isInteractive {
                self.transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        }
    }
    
    @objc func didSingleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        if self.currentMode == .full {
            changeScreenMode(to: .normal)
            self.currentMode = .normal
        } else {
            changeScreenMode(to: .full)
            self.currentMode = .full
        }

    }
    
    func changeScreenMode(to: ScreenMode) {
        if to == .full {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: {
//                            self.view.backgroundColor = .black
                self.view.backgroundColor = self.hexStringToUIColor(hex: Constants.backgroundColor)
                            
            }, completion: { completed in
            })
        } else {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: {
                            if #available(iOS 13.0, *) {
                                self.view.backgroundColor = .systemBackground
                            } else {
                                self.view.backgroundColor = .white
                            }
            }, completion: { completed in
            })
        }
    }
}

extension PhotoPageContainerViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if currentIndex == 0 {
            return nil
        }
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(PhotoZoomViewController.self)") as! PhotoZoomViewController
        vc.delegate = self
        vc.actualPost = (self.imagePosts?[currentIndex - 1])!
        vc.postIndex = currentIndex - 1
        vc.shouldOpenCommentSection = self.shouldOpenCommentSection
        vc.commentToOpen = self.commentToOpen
        vc.replyToOpen = self.replyToOpen
        return vc
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if currentIndex == ((self.imagePosts?.count ?? 1) - 1) {
            return nil
        }
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(PhotoZoomViewController.self)") as! PhotoZoomViewController
        vc.delegate = self
        vc.actualPost = (self.imagePosts?[currentIndex + 1])!
        vc.postIndex = currentIndex + 1
        vc.shouldOpenCommentSection = self.shouldOpenCommentSection
        vc.commentToOpen = self.commentToOpen
        vc.replyToOpen = self.replyToOpen
        return vc
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        guard let nextVC = pendingViewControllers.first as? PhotoZoomViewController else {
            return
        }
        
        self.nextIndex = nextVC.postIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if (completed && self.nextIndex != nil) {

            self.currentIndex = self.nextIndex!
            self.delegate?.containerViewController(self, indexDidUpdate: self.currentIndex)
        }
        
        self.nextIndex = nil
    }
    
}

extension PhotoPageContainerViewController: PhotoZoomViewControllerDelegate {
    
    func photoZoomViewController(_ photoZoomViewController: PhotoZoomViewController, scrollViewDidScroll scrollView: UIScrollView) {
        if scrollView.zoomScale != scrollView.minimumZoomScale && self.currentMode != .full {
            self.changeScreenMode(to: .full)
            self.currentMode = .full
        }
    }
}

extension PhotoPageContainerViewController: ZoomAnimatorDelegate {
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        return CGRect(x: 0, y: 0, width: 0, height: 0) // fix this in future
    }
    

    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
    }

    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
    }

    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        return self.currentViewController.mainPostImage
    }

//    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
//        return self.currentViewController.scrollView.convert(self.currentViewController.imageView.frame, to: self.currentViewController.view)
//    }
}
