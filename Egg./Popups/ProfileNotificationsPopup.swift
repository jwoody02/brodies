//
//  ProfileNotificationsPopup.swift
//  Egg.
//
//  Created by Jordan Wood on 8/21/22.
//

import UIKit
import PanModal
import Presentr
import FirebaseFirestore
import FirebaseAuth
import SPAlert


class ProfileNotificationsPopup: UIViewController {
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    // NOTIFICATIONS VIEW
    internal var notificationsBackbutton: UIButton?
    
    
    internal var settingsLabel: UILabel?
    
    internal var individualNotificationsView: UIView?
    
    internal var likesNotificationsView: UIButton?
    internal var likesNotificationsLabel: UILabel?
    internal var likesNotificationsCheckbox: AIFlatSwitch?
    
    internal var commentsNotificationsView: UIButton?
    internal var commentsNotificationsLabel: UILabel?
    internal var commentsNotificationsCheckbox: AIFlatSwitch?
    
    var notificationsSettings : [String: Bool] = ["posts_enabled" : false, "new_stories":false]
    var profileUID = ""
    private var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        setupNotificationsView()
        actuallyLoadSettings()
    }
    func setupNotificationsView() {
        self.settingsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let settingsLabel = self.settingsLabel {
            settingsLabel.text = "Push Notifications"
            settingsLabel.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 25)
            settingsLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
            settingsLabel.textColor = .darkGray
            settingsLabel.textAlignment = .center
            self.view.addSubview(settingsLabel)
        }
    
        
        self.individualNotificationsView = UIView(frame: CGRect(x: 15, y: self.settingsLabel!.frame.maxY + 20, width: UIScreen.main.bounds.width - 30, height: 100))
        if let individualNotificationsView = individualNotificationsView {
            individualNotificationsView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
            individualNotificationsView.layer.shadowOffset = CGSize(width: 0, height: 4)
            individualNotificationsView.layer.shadowRadius = 12
            individualNotificationsView.layer.cornerRadius = 12
            individualNotificationsView.layer.shadowOpacity = 0.1
            individualNotificationsView.clipsToBounds = true
            individualNotificationsView.isUserInteractionEnabled = true
            individualNotificationsView.alpha = 0
            self.likesNotificationsView = UIButton(frame: CGRect(x: 0, y: 0, width: individualNotificationsView.frame.width, height: 50))
            if let likesNotificationsView = self.likesNotificationsView {
                likesNotificationsView.alpha = 1
                likesNotificationsView.addTarget(self, action: #selector(likesNotificationsPressed(_:)), for: .touchUpInside)
                likesNotificationsView.backgroundColor = Constants.surfaceColor.hexToUiColor()
                likesNotificationsView.isUserInteractionEnabled = true
                self.likesNotificationsLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.likesNotificationsView!.frame.width - 15 - 30, height: self.likesNotificationsView!.frame.height))
                if let likesNotificationsLabel = self.likesNotificationsLabel {
                    likesNotificationsLabel.center.y = self.likesNotificationsView!.frame.height / 2
                    likesNotificationsLabel.text = "New Posts"
                    likesNotificationsLabel.isUserInteractionEnabled = false
                    likesNotificationsLabel.textColor = Constants.textColor.hexToUiColor()
                    likesNotificationsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                    self.likesNotificationsView?.addSubview(likesNotificationsLabel)
                }
                let checkboxWid = 20
                let checkboxY = (Int(likesNotificationsLabel!.frame.height) / 2) - checkboxWid / 2
                self.likesNotificationsCheckbox = AIFlatSwitch(frame: CGRect(x: Int(likesNotificationsView.frame.width) - checkboxWid - checkboxY, y: checkboxY, width: checkboxWid, height: checkboxWid))
                if let likesNotificationsCheckbox = self.likesNotificationsCheckbox {
                    likesNotificationsCheckbox.isUserInteractionEnabled = false
                    self.likesNotificationsView?.addSubview(likesNotificationsCheckbox)
                }
                self.individualNotificationsView?.addSubview(likesNotificationsView)
            }
            
            self.commentsNotificationsView = UIButton(frame: CGRect(x: 0, y: likesNotificationsView!.frame.maxY, width: individualNotificationsView.frame.width, height: 50))
            if let commentsNotificationsView = self.commentsNotificationsView {
                commentsNotificationsView.alpha = 1
                commentsNotificationsView.addTarget(self, action: #selector(commentsNotificationsPressed(_:)), for: .touchUpInside)
                commentsNotificationsView.backgroundColor = Constants.surfaceColor.hexToUiColor()
                commentsNotificationsView.isUserInteractionEnabled = true
                self.commentsNotificationsLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.commentsNotificationsView!.frame.width - 15 - 30, height: self.commentsNotificationsView!.frame.height))
                if let commentsNotificationsLabel = self.commentsNotificationsLabel {
                    commentsNotificationsLabel.center.y = self.commentsNotificationsView!.frame.height / 2
                    commentsNotificationsLabel.text = "New Stories"
                    commentsNotificationsLabel.isUserInteractionEnabled = false
                    commentsNotificationsLabel.textColor = Constants.textColor.hexToUiColor()
                    commentsNotificationsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                    self.commentsNotificationsView?.addSubview(commentsNotificationsLabel)
                }
                let checkboxWid = 20
                let checkboxY = (Int(commentsNotificationsLabel!.frame.height) / 2) - checkboxWid / 2
                self.commentsNotificationsCheckbox = AIFlatSwitch(frame: CGRect(x: Int(commentsNotificationsView.frame.width) - checkboxWid - checkboxY, y: checkboxY, width: checkboxWid, height: checkboxWid))
                if let commentsNotificationsCheckbox = self.commentsNotificationsCheckbox {
                    commentsNotificationsCheckbox.isUserInteractionEnabled = false
                    self.commentsNotificationsView?.addSubview(commentsNotificationsCheckbox)
                }
                self.individualNotificationsView?.addSubview(commentsNotificationsView)
            }
            
            
            
            self.view.addSubview(individualNotificationsView)
        }
    }
    @objc internal func commentsNotificationsPressed(_ button: UIButton) {
        print("* comment pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        if notificationsSettings["new_stories"] == false {
            self.db.collection("posts").document(profileUID).collection("story_notifications").document(userID!).setData(["stories_enabled":true])
            commentsNotificationsCheckbox?.setSelected(true, animated: true)
            notificationsSettings["new_stories"] = true
        } else {
            self.db.collection("FCMTokens").document(userID!).setData(["comments_enabled": false], merge: true)
            self.db.collection("posts").document(profileUID).collection("story_notifications").document(userID!).delete()
            commentsNotificationsCheckbox?.setSelected(false, animated: true)
            notificationsSettings["new_stories"] = false
        }
    }
    @objc internal func likesNotificationsPressed(_ button: UIButton) {
        print("* likes tapped")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        if notificationsSettings["posts_enabled"] == false {
            self.db.collection("posts").document(profileUID).collection("post_notifications").document(userID!).setData(["posts_enabled":true])
            likesNotificationsCheckbox?.setSelected(true, animated: true)
            notificationsSettings["posts_enabled"] = true
        } else {
            self.db.collection("posts").document(profileUID).collection("post_notifications").document(userID!).delete()
            likesNotificationsCheckbox?.setSelected(false, animated: true)
            notificationsSettings["posts_enabled"] = false
        }
    }
    func showNotificationsStuffs() {
       print("* showing notification stuffs")
        settingsLabel?.text = "Push Notifications"
        settingsLabel?.center.x = self.view.center.x
        settingsLabel?.fadeIn()
        individualNotificationsView?.fadeIn()
//        notificationsBackbutton?.fadeIn()
    }
    func actuallyLoadSettings() {
        let userID = Auth.auth().currentUser?.uid
        print("* checking /posts/\(self.profileUID)/post_notifications/\(userID!)")
        self.db.collection("posts").document(self.profileUID).collection("post_notifications").document(userID!).getDocument { (result, error) in
            print("* is post enabled: \((result?.exists ?? false) == true && error == nil)")
            if (result?.exists ?? false) == true && error == nil {
                self.notificationsSettings["posts_enabled"] = true
                self.likesNotificationsCheckbox?.setSelected(true, animated: false)
            } else {
                self.notificationsSettings["posts_enabled"] = false
                self.likesNotificationsCheckbox?.setSelected(false, animated: false)
            }
            self.db.collection("posts").document(self.profileUID).collection("story_notifications").document(userID!).getDocument { (result, error) in
                print("* is story enabled: \((result?.exists ?? false) == true && error == nil)")
                if (result?.exists ?? false) == true && error == nil {
                    self.notificationsSettings["new_stories"] = true
                    self.commentsNotificationsCheckbox?.setSelected(true, animated: false)
                } else {
                    self.notificationsSettings["new_stories"] = false
                    self.commentsNotificationsCheckbox?.setSelected(false, animated: false)
                }
                self.showNotificationsStuffs()
            }
        }
}
}
    extension ProfileNotificationsPopup: PanModalPresentable {

        override var preferredStatusBarStyle: UIStatusBarStyle {
            return .lightContent
        }

        var panScrollable: UIScrollView? {
            return nil
        }

        var longFormHeight: PanModalHeight {
            let actualHeight = 300
            
            return .maxHeightWithTopInset(UIScreen.main.bounds.height-CGFloat(actualHeight))
        }

        var anchorModalToLongForm: Bool {
            return false
        }
    }


