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
import Kingfisher

class MyProfileViewController: UIViewController {
    
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var actualFollowersLabel: UILabel!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var actualFollowingLabel: UILabel!
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var addToStoryButton: UIButton!
    
    let defaults = UserDefaults.standard
    
    var uidOfProfile = ""
    var isCurrentUser = false
    
    private var db = Firestore.firestore()
    var user = User(uid: "", username: "", profileImageUrl: "", bio: "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: "")
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        styleElements()
        
        
        if Auth.auth().currentUser?.uid == nil {
//            // show login view
            print("not valid user, pushing login")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        } else {
            if uidOfProfile == "" {
                uidOfProfile = (Auth.auth().currentUser?.uid)!
                isCurrentUser = true
                updatebasicInfo()
            } else {
                setUserImage(fromUrl: user.profileImageUrl)
                
                usernameLabel.text = "\(user.username)"
                usernameLabel.sizeToFit()
                usernameLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (usernameLabel.frame.width / 2), y: 50, width: usernameLabel.frame.width, height: usernameLabel.frame.height)
                usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
                
                fullNameLabel.text = "\(user.fullname)"
                fullNameLabel.sizeToFit()
                fullNameLabel.center.x = self.profilePicImage.center.x
                fullNameLabel.center.y = self.profilePicImage.center.y + self.profilePicImage.frame.width
            }
        }
        if Constants.isDebugEnabled {
            var window : UIWindow = UIApplication.shared.keyWindow!
            window.showDebugMenu()
        }
    }
    func styleElements() {
        self.topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300)
        let profilePicWidth = 50
        self.profilePicImage.frame = CGRect(x: (Int(UIScreen.main.bounds.width) / 2) - (profilePicWidth / 2), y: 100, width: profilePicWidth, height: profilePicWidth)
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
        
    }
    func applyStoryBorderColor() {
        profilePicImage.layer.borderWidth = 2
        profilePicImage.layer.borderColor = hexStringToUIColor(hex: Constants.primaryColor).cgColor
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
    func updatebasicInfo() {
        print("* collecting data on uid: \(uidOfProfile)")
        db.collection("user-locations").document(uidOfProfile).getDocument() { (document, error) in
            if let document = document {
                self.user.uid = self.uidOfProfile
                let data = document.data()! as [String: AnyObject]
                
                self.user.profileImageUrl = data["profileImageURL"] as? String ?? ""
                self.user.username = data["username"] as? String ?? ""
                self.user.fullname = data["full_name"] as? String ?? ""
                
                self.setUserImage(fromUrl: self.user.profileImageUrl)
                
                self.usernameLabel.text = "\(self.user.username)"
                self.usernameLabel.sizeToFit()
                self.usernameLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (self.usernameLabel.frame.width / 2), y: 50, width: self.usernameLabel.frame.width, height: self.usernameLabel.frame.height)
                self.usernameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
                
                self.fullNameLabel.text = "\(self.user.fullname)"
                self.fullNameLabel.sizeToFit()
                self.fullNameLabel.center.x = self.profilePicImage.center.x
                self.fullNameLabel.center.y = self.profilePicImage.center.y + self.profilePicImage.frame.width + 20
                print("* got new user: \(self.user)")
                
            } else {
                print("* some error collecting info on user")
            }
            
        }
    }
    func updateFollowersAndFollowing() {
        
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
    let interactor = Interactor()

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
    }
}
extension MyProfileViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
