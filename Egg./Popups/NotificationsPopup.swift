//
//  NotificationsPopup.swift
//  Egg.
//
//  Created by Jordan Wood on 8/17/22.
//

import UIKit
import PanModal
import Presentr
import FirebaseFirestore
import FirebaseAuth
import SPAlert


class NotificationsPOpup: UIViewController {
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    // NOTIFICATIONS VIEW
    internal var notificationsBackbutton: UIButton?
    
    internal var allNotificationsView: UIButton?
    internal var allNotificationsLabel: UILabel?
    internal var allNotificationsCheckbox: AIFlatSwitch?
    
    
    internal var settingsLabel: UILabel?
    
    internal var individualNotificationsView: UIView?
    
    internal var likesNotificationsView: UIButton?
    internal var likesNotificationsLabel: UILabel?
    internal var likesNotificationsCheckbox: AIFlatSwitch?
    
    internal var commentsNotificationsView: UIButton?
    internal var commentsNotificationsLabel: UILabel?
    internal var commentsNotificationsCheckbox: AIFlatSwitch?
    
    internal var followersNotificationsView: UIButton?
    internal var followersNotificationsLabel: UILabel?
    internal var followersNotificationsCheckbox: AIFlatSwitch?
    
    internal var mentionsNotificationsView: UIButton?
    internal var mentionsNotificationsLabel: UILabel?
    internal var mentionsNotificationsCheckbox: AIFlatSwitch?
    
    var notificationsSettings : [String: Bool] = ["likes_enabled" : true, "comments_enabled":true, "followers_enabled":true, "mentions_enabled":true]
    var postID = ""
    var postAuthorID = ""
    var reportType = ""
    var reportDescription = ""
    var isPostReport = true
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
        self.allNotificationsView = UIButton(frame: CGRect(x: 15, y: self.settingsLabel!.frame.maxY + 20, width: UIScreen.main.bounds.width - 30, height: 50))
        if let allNotificationsView = self.allNotificationsView {
            allNotificationsView.addReportShadow()
            allNotificationsView.alpha = 0
            allNotificationsView.addTarget(self, action: #selector(allnotificationsPressed(_:)), for: .touchUpInside)
            allNotificationsView.backgroundColor = Constants.surfaceColor.hexToUiColor()
            allNotificationsView.isUserInteractionEnabled = true
            allNotificationsView.layer.cornerRadius = 12
            self.allNotificationsLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.allNotificationsView!.frame.width - 15 - 30, height: self.allNotificationsView!.frame.height))
            if let allNotificationsLabel = self.allNotificationsLabel {
                allNotificationsLabel.center.y = self.allNotificationsView!.frame.height / 2
                allNotificationsLabel.text = "All Notifications"
                allNotificationsLabel.isUserInteractionEnabled = false
                allNotificationsLabel.textColor = Constants.textColor.hexToUiColor()
                allNotificationsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.allNotificationsView?.addSubview(allNotificationsLabel)
            }
            let checkboxWid = 20
            let checkboxY = (Int(allNotificationsView.frame.height) / 2) - checkboxWid / 2
            self.allNotificationsCheckbox = AIFlatSwitch(frame: CGRect(x: Int(allNotificationsView.frame.width) - checkboxWid - checkboxY, y: checkboxY, width: checkboxWid, height: checkboxWid))
            if let allNotificationsCheckbox = self.allNotificationsCheckbox {
                allNotificationsCheckbox.isUserInteractionEnabled = false
                self.allNotificationsView?.addSubview(allNotificationsCheckbox)
            }
            self.view.addSubview(allNotificationsView)
        }
    
        
        self.individualNotificationsView = UIView(frame: CGRect(x: 15, y: self.allNotificationsView!.frame.maxY + 20, width: UIScreen.main.bounds.width - 30, height: 200))
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
                    likesNotificationsLabel.center.y = self.allNotificationsView!.frame.height / 2
                    likesNotificationsLabel.text = "Likes"
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
                    commentsNotificationsLabel.text = "Comments"
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
            
            self.followersNotificationsView = UIButton(frame: CGRect(x: 0, y: commentsNotificationsView!.frame.maxY, width: individualNotificationsView.frame.width, height: 50))
            if let followersNotificationsView = self.followersNotificationsView {
                followersNotificationsView.alpha = 1
                followersNotificationsView.addTarget(self, action: #selector(followersNotificationsPressed(_:)), for: .touchUpInside)
                followersNotificationsView.backgroundColor = Constants.surfaceColor.hexToUiColor()
                followersNotificationsView.isUserInteractionEnabled = true
                self.followersNotificationsLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.followersNotificationsView!.frame.width - 15 - 30, height: self.followersNotificationsView!.frame.height))
                if let followersNotificationsLabel = self.followersNotificationsLabel {
                    followersNotificationsLabel.center.y = self.followersNotificationsView!.frame.height / 2
                    followersNotificationsLabel.text = "New Followers"
                    followersNotificationsLabel.isUserInteractionEnabled = false
                    followersNotificationsLabel.textColor = Constants.textColor.hexToUiColor()
                    followersNotificationsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                    self.followersNotificationsView?.addSubview(followersNotificationsLabel)
                }
                let checkboxWid = 20
                let checkboxY = (Int(followersNotificationsLabel!.frame.height) / 2) - checkboxWid / 2
                self.followersNotificationsCheckbox = AIFlatSwitch(frame: CGRect(x: Int(followersNotificationsView.frame.width) - checkboxWid - checkboxY, y: checkboxY, width: checkboxWid, height: checkboxWid))
                if let followersNotificationsCheckbox = self.followersNotificationsCheckbox {
                    followersNotificationsCheckbox.isUserInteractionEnabled = false
                    self.followersNotificationsView?.addSubview(followersNotificationsCheckbox)
                }
                self.individualNotificationsView?.addSubview(followersNotificationsView)
            }
            
            self.mentionsNotificationsView = UIButton(frame: CGRect(x: 0, y: followersNotificationsView!.frame.maxY, width: individualNotificationsView.frame.width, height: 50))
            if let mentionsNotificationsView = self.mentionsNotificationsView {
                mentionsNotificationsView.alpha = 1
                mentionsNotificationsView.addTarget(self, action: #selector(mentionsNotificationsPressed(_:)), for: .touchUpInside)
                mentionsNotificationsView.backgroundColor = Constants.surfaceColor.hexToUiColor()
                mentionsNotificationsView.isUserInteractionEnabled = true
                self.mentionsNotificationsLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.mentionsNotificationsView!.frame.width - 15 - 30, height: self.mentionsNotificationsView!.frame.height))
                if let mentionsNotificationsLabel = self.mentionsNotificationsLabel {
                    mentionsNotificationsLabel.center.y = self.mentionsNotificationsView!.frame.height / 2
                    mentionsNotificationsLabel.text = "Mentions"
                    mentionsNotificationsLabel.isUserInteractionEnabled = false
                    mentionsNotificationsLabel.textColor = Constants.textColor.hexToUiColor()
                    mentionsNotificationsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                    self.mentionsNotificationsView?.addSubview(mentionsNotificationsLabel)
                }
                let checkboxWid = 20
                let checkboxY = (Int(mentionsNotificationsLabel!.frame.height) / 2) - checkboxWid / 2
                self.mentionsNotificationsCheckbox = AIFlatSwitch(frame: CGRect(x: Int(mentionsNotificationsView.frame.width) - checkboxWid - checkboxY, y: checkboxY, width: checkboxWid, height: checkboxWid))
                if let mentionsNotificationsCheckbox = self.mentionsNotificationsCheckbox {
                    mentionsNotificationsCheckbox.isUserInteractionEnabled = false
                    self.mentionsNotificationsView?.addSubview(mentionsNotificationsCheckbox)
                }
                self.individualNotificationsView?.addSubview(mentionsNotificationsView)
            }
            
            self.view.addSubview(individualNotificationsView)
        }
    }
    @objc internal func mentionsNotificationsPressed(_ button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        print("* mention tapped")
        let userID = Auth.auth().currentUser?.uid
        if notificationsSettings["mentions_enabled"] == false {
            self.db.collection("FCMTokens").document(userID!).setData(["mentions_enabled": true], merge: true)
            mentionsNotificationsCheckbox?.setSelected(true, animated: true)
            notificationsSettings["mentions_enabled"] = true
        } else {
            self.db.collection("FCMTokens").document(userID!).setData(["mentions_enabled": false], merge: true)
            mentionsNotificationsCheckbox?.setSelected(false, animated: true)
            notificationsSettings["mentions_enabled"] = false
        }
        resetCheckboxes()
    }
    @objc internal func followersNotificationsPressed(_ button: UIButton) {
        print("* followers pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        if notificationsSettings["followers_enabled"] == false {
            self.db.collection("FCMTokens").document(userID!).setData(["followers_enabled": true], merge: true)
            followersNotificationsCheckbox?.setSelected(true, animated: true)
            notificationsSettings["followers_enabled"] = true
        } else {
            self.db.collection("FCMTokens").document(userID!).setData(["followers_enabled": false], merge: true)
            followersNotificationsCheckbox?.setSelected(false, animated: true)
            notificationsSettings["followers_enabled"] = false
        }
        resetCheckboxes()
    }
    @objc internal func commentsNotificationsPressed(_ button: UIButton) {
        print("* comment pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        if notificationsSettings["comments_enabled"] == false {
            self.db.collection("FCMTokens").document(userID!).setData(["comments_enabled": true], merge: true)
            commentsNotificationsCheckbox?.setSelected(true, animated: true)
            notificationsSettings["comments_enabled"] = true
        } else {
            self.db.collection("FCMTokens").document(userID!).setData(["comments_enabled": false], merge: true)
            commentsNotificationsCheckbox?.setSelected(false, animated: true)
            notificationsSettings["comments_enabled"] = false
        }
        resetCheckboxes()
    }
    @objc internal func likesNotificationsPressed(_ button: UIButton) {
        print("* likes tapped")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        if notificationsSettings["likes_enabled"] == false {
            self.db.collection("FCMTokens").document(userID!).setData(["likes_enabled": true], merge: true)
            likesNotificationsCheckbox?.setSelected(true, animated: true)
            notificationsSettings["likes_enabled"] = true
        } else {
            self.db.collection("FCMTokens").document(userID!).setData(["likes_enabled": false], merge: true)
            likesNotificationsCheckbox?.setSelected(false, animated: true)
            notificationsSettings["likes_enabled"] = false
        }
        resetCheckboxes()
    }
    @objc internal func allnotificationsPressed(_ button: UIButton) {
        print("* all notifs pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        if notificationsSettings["likes_enabled"] == false || notificationsSettings["comments_enabled"] == false || notificationsSettings["followers_enabled"] == false || notificationsSettings["mentions_enabled"] == false {
            notificationsSettings = ["likes_enabled" : true, "comments_enabled":true, "followers_enabled":true, "mentions_enabled":true]
            self.db.collection("FCMTokens").document(userID!).setData(["likes_enabled": true, "comments_enabled": true, "followers_enabled": true, "mentions_enabled":true], merge: true)
            if likesNotificationsCheckbox?.isSelected == false {
                likesNotificationsCheckbox?.setSelected(true, animated: true)
            }
            if commentsNotificationsCheckbox?.isSelected == false {
                commentsNotificationsCheckbox?.setSelected(true, animated: true)
            }
            if followersNotificationsCheckbox?.isSelected == false {
                followersNotificationsCheckbox?.setSelected(true, animated: true)
            }
            if mentionsNotificationsCheckbox?.isSelected == false {
                mentionsNotificationsCheckbox?.setSelected(true, animated: true)
            }
        } else {
            notificationsSettings = ["likes_enabled" : false, "comments_enabled":false, "followers_enabled":false, "mentions_enabled":false]
            self.db.collection("FCMTokens").document(userID!).setData(["likes_enabled": false, "comments_enabled": false, "followers_enabled": false, "mentions_enabled":false], merge: true)
            if likesNotificationsCheckbox?.isSelected == true {
                likesNotificationsCheckbox?.setSelected(false, animated: true)
            }
            if commentsNotificationsCheckbox?.isSelected == true {
                commentsNotificationsCheckbox?.setSelected(false, animated: true)
            }
            if followersNotificationsCheckbox?.isSelected == true {
                followersNotificationsCheckbox?.setSelected(false, animated: true)
            }
            if mentionsNotificationsCheckbox?.isSelected == true {
                mentionsNotificationsCheckbox?.setSelected(false, animated: true)
            }
        }
        
        resetCheckboxes()
    }
    func resetCheckboxes() {
        if notificationsSettings["likes_enabled"] == true && notificationsSettings["comments_enabled"] == true && notificationsSettings["followers_enabled"] == true && notificationsSettings["mentions_enabled"] == true {
            if allNotificationsCheckbox?.isSelected == false {
                allNotificationsCheckbox?.setSelected(true, animated: true)
            }
            
        } else {
            if allNotificationsCheckbox?.isSelected == true {
                allNotificationsCheckbox?.setSelected(false, animated: true)
            }
            
        }
    }
    func showNotificationsStuffs() {
       print("* showing notification stuffs")
        settingsLabel?.text = "Push Notifications"
        settingsLabel?.center.x = self.view.center.x
        settingsLabel?.fadeIn()
        allNotificationsView?.fadeIn()
        allNotificationsLabel?.fadeIn()
        allNotificationsCheckbox?.fadeIn()
        individualNotificationsView?.fadeIn()
//        notificationsBackbutton?.fadeIn()
    }
    func actuallyLoadSettings() {
        let userID = Auth.auth().currentUser?.uid
        db.collection("FCMTokens").document(userID!).getDocument() { [self] (document, error) in
            if let document = document {
                if let data = document.data() as? [String: AnyObject] {
                    let likesEnabled = data["likes_enabled"] as? Bool ?? true
                    let commentsEnabled = data["comments_enabled"] as? Bool ?? true
                    let followersEnabled = data["followers_enabled"] as? Bool ?? true
                    let mentionsEnabled = data["mentions_enabled"] as? Bool ?? true
                    if likesEnabled == false {
                        notificationsSettings["likes_enabled"] = false
                    } else {
                        likesNotificationsCheckbox?.setSelected(true, animated: true)
                    }
                    if commentsEnabled == false {
                        notificationsSettings["comments_enabled"] = false
                    } else {
                        commentsNotificationsCheckbox?.setSelected(true, animated: true)
                    }
                    if followersEnabled == false {
                        notificationsSettings["followers_enabled"] = false
                    } else {
                        followersNotificationsCheckbox?.setSelected(true, animated: true)
                    }
                    if mentionsEnabled == false {
                        notificationsSettings["mentions_enabled"] = false
                    } else {
                        mentionsNotificationsCheckbox?.setSelected(true, animated: true)
                    }

                }

                }
            resetCheckboxes()
            self.showNotificationsStuffs()
    }
}
}
    extension NotificationsPOpup: PanModalPresentable {

        override var preferredStatusBarStyle: UIStatusBarStyle {
            return .lightContent
        }

        var panScrollable: UIScrollView? {
            return nil
        }

        var longFormHeight: PanModalHeight {
            let actualHeight = 680
            
            return .maxHeightWithTopInset(UIScreen.main.bounds.height-CGFloat(actualHeight))
        }

        var anchorModalToLongForm: Bool {
            return false
        }
    }

