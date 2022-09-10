//
//  SettingsPopup.swift
//  Egg.
//
//  Created by Jordan Wood on 8/14/22.
//
import UIKit
import PanModal
import Presentr
import FirebaseFirestore
import FirebaseAuth
import SPAlert
import FirebaseAnalytics

class SettingsPopupController: UIViewController, UITextViewDelegate {
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    
    private var db = Firestore.firestore()
    
    internal var settingsLabel: UILabel?
    
    internal var profileImage: UIImageView?
    internal var profileButton: UIButton?
    internal var profileLabel: UILabel?
    internal var profileArrow: UIImageView?
    
    internal var blockedAccountsImage: UIImageView?
    internal var blockedAccountsButton: UIButton?
    internal var blockedAccountsLabel: UILabel?
    internal var blockedAccountsArrow: UIImageView?
    
    internal var savedImage: UIImageView?
    internal var savedButton: UIButton?
    internal var savedLabel: UILabel?
    internal var savedArrow: UIImageView?
    
    internal var notificationsImage: UIImageView?
    internal var notificationsButton: UIButton?
    internal var notificationsLabel: UILabel?
    internal var notificationsArrow: UIImageView?
    
    internal var privacyPolicyImage: UIImageView?
    internal var privacyPolicyButton: UIButton?
    internal var privacyPolicyLabel: UILabel?
    internal var privacyPolicyArrow: UIImageView?
    
    internal var termsImage: UIImageView?
    internal var termsButton: UIButton?
    internal var termsLabel: UILabel?
    internal var termsArrow: UIImageView?
    
    internal var communityImage: UIImageView?
    internal var communityButton: UIButton?
    internal var communityLabel: UILabel?
    internal var communityArrow: UIImageView?
    
    internal var logooutImage: UIImageView?
    internal var logoutButton: UIButton?
    internal var logoutLabel: UILabel?
    
    
    // NOTIFICATIONS VIEW
    internal var notificationsBackbutton: UIButton?
    
    internal var allNotificationsView: UIButton?
    internal var allNotificationsLabel: UILabel?
    internal var allNotificationsCheckbox: AIFlatSwitch?
    
    
    
    
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
    
    var presenter = Presentr(presentationType: .alert)
    var parentVC = MyProfileViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        bigThreeButtonWidths = (Int(self.view.frame.width) - interButtonPadding*4) / 3
        Analytics.logEvent("settings_opened", parameters: nil)
        setupUI()
//        self.dismissDetail()
    }
    func setupUI() {
        
        self.settingsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let settingsLabel = self.settingsLabel {
            settingsLabel.text = "Settings"
            settingsLabel.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 25)
            settingsLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 18)
            settingsLabel.textColor = .darkGray
            settingsLabel.textAlignment = .center
            self.view.addSubview(settingsLabel)
        }
        self.profileButton = UIButton(frame: CGRect(x: 15, y: self.settingsLabel!.frame.maxY + 20, width: UIScreen.main.bounds.width - 30, height: 50))
        if let profileButton = self.profileButton {
            profileButton.addReportShadow()
            profileButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            profileButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            profileButton.isUserInteractionEnabled = true
            profileButton.layer.cornerRadius = 12
            
            self.profileImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let profileImage = profileImage {
                profileImage.image = UIImage(systemName: "person")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .light, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                profileImage.tintColor = Constants.textColor.hexToUiColor()
                profileImage.center.y = profileButton.frame.height / 2
                profileImage.contentMode = .scaleAspectFit
                self.profileButton?.addSubview(profileImage)
            }
            let profButtonMax = (self.profileImage?.frame.maxX)! + 10
            self.profileLabel = UILabel(frame: CGRect(x: profButtonMax, y: 0, width: profileButton.frame.width - 15 - 30, height: self.profileButton!.frame.height))
            if let profileLabel = self.profileLabel {
                profileLabel.center.y = self.profileButton!.frame.height / 2
                profileLabel.text = "Profile"
                profileLabel.isUserInteractionEnabled = false
                profileLabel.textColor = Constants.textColor.hexToUiColor()
                profileLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.profileButton?.addSubview(profileLabel)
            }
            self.profileArrow = UIImageView(frame: CGRect(x: profileButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let profileArrow = self.profileArrow {
                profileArrow.frame = CGRect(x: profileButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                profileArrow.image = UIImage(systemName: "chevron.right")
                profileArrow.contentMode = .scaleAspectFit
                profileArrow.tintColor = Constants.textColor.hexToUiColor()
                self.profileButton?.addSubview(profileArrow)
            }
            self.view.addSubview(profileButton)
        }
        
        
        self.blockedAccountsButton = UIButton(frame: CGRect(x: 15, y: self.profileButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let blockedAccountsButton = self.blockedAccountsButton {
            blockedAccountsButton.addReportShadow()
            blockedAccountsButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            blockedAccountsButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            blockedAccountsButton.isUserInteractionEnabled = true
            blockedAccountsButton.layer.cornerRadius = 12
            self.blockedAccountsImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let blockedAccountsImage = blockedAccountsImage {
                blockedAccountsImage.image = UIImage(systemName: "circle.slash")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .light, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                blockedAccountsImage.tintColor = Constants.textColor.hexToUiColor()
                blockedAccountsImage.center.y = blockedAccountsButton.frame.height / 2
                blockedAccountsImage.contentMode = .scaleAspectFit
                self.blockedAccountsButton?.addSubview(blockedAccountsImage)
            }
            let profButtonMax = (self.blockedAccountsImage?.frame.maxX)! + 10
            self.blockedAccountsLabel = UILabel(frame: CGRect(x: profButtonMax, y: profButtonMax, width: blockedAccountsButton.frame.width - 15 - 30, height: self.blockedAccountsButton!.frame.height))
            if let blockedAccountsLabel = self.blockedAccountsLabel {
                blockedAccountsLabel.center.y = self.blockedAccountsButton!.frame.height / 2
                blockedAccountsLabel.text = "Blocked Accounts"
                blockedAccountsLabel.isUserInteractionEnabled = false
                blockedAccountsLabel.textColor = Constants.textColor.hexToUiColor()
                blockedAccountsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.blockedAccountsButton?.addSubview(blockedAccountsLabel)
            }
            self.blockedAccountsArrow = UIImageView(frame: CGRect(x: blockedAccountsButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let blockedAccountsArrow = self.blockedAccountsArrow {
                blockedAccountsArrow.frame = CGRect(x: blockedAccountsButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                blockedAccountsArrow.image = UIImage(systemName: "chevron.right")
                blockedAccountsArrow.contentMode = .scaleAspectFit
                blockedAccountsArrow.tintColor = Constants.textColor.hexToUiColor()
                self.blockedAccountsButton?.addSubview(blockedAccountsArrow)
            }
            self.view.addSubview(blockedAccountsButton)
        }
        self.savedButton = UIButton(frame: CGRect(x: 15, y: self.blockedAccountsButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let savedButton = self.savedButton {
            savedButton.addReportShadow()
            savedButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            savedButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            savedButton.isUserInteractionEnabled = true
            savedButton.layer.cornerRadius = 12
            self.savedImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let savedImage = savedImage {
                savedImage.image = UIImage(systemName: "bookmark")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .light, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                savedImage.contentMode = .scaleAspectFit
                savedImage.tintColor = Constants.textColor.hexToUiColor()
                savedImage.center.y = savedButton.frame.height / 2
                self.savedButton?.addSubview(savedImage)
            }
            let profButtonMax = (self.savedImage?.frame.maxX)! + 10
            self.savedLabel = UILabel(frame: CGRect(x: profButtonMax, y: profButtonMax, width: savedButton.frame.width - 15 - 30, height: self.savedButton!.frame.height))
            if let savedLabel = self.savedLabel {
                savedLabel.center.y = self.savedButton!.frame.height / 2
                savedLabel.text = "Saved Posts"
                savedLabel.isUserInteractionEnabled = false
                savedLabel.textColor = Constants.textColor.hexToUiColor()
                savedLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.savedButton?.addSubview(savedLabel)
            }
            self.savedArrow = UIImageView(frame: CGRect(x: savedButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let savedArrow = self.savedArrow {
                savedArrow.frame = CGRect(x: savedButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                savedArrow.image = UIImage(systemName: "chevron.right")
                savedArrow.contentMode = .scaleAspectFit
                savedArrow.tintColor = Constants.textColor.hexToUiColor()
                self.savedButton?.addSubview(savedArrow)
            }
            self.view.addSubview(savedButton)
        }
        
        self.notificationsButton = UIButton(frame: CGRect(x: 15, y: self.savedButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let notificationsButton = self.notificationsButton {
            notificationsButton.addReportShadow()
            notificationsButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            notificationsButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            notificationsButton.isUserInteractionEnabled = true
            notificationsButton.layer.cornerRadius = 12
            self.notificationsImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let notificationsImage = notificationsImage {
                notificationsImage.image = UIImage(systemName: "bell")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .light, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                notificationsImage.tintColor = Constants.textColor.hexToUiColor()
                notificationsImage.center.y = notificationsButton.frame.height / 2
                notificationsImage.contentMode = .scaleAspectFit
                self.notificationsButton?.addSubview(notificationsImage)
            }
            let profButtonMax = (self.notificationsImage?.frame.maxX)! + 10
            self.notificationsLabel = UILabel(frame: CGRect(x: profButtonMax, y: profButtonMax, width: notificationsButton.frame.width - 15 - 30, height: self.notificationsButton!.frame.height))
            if let notificationsLabel = self.notificationsLabel {
                notificationsLabel.center.y = self.notificationsButton!.frame.height / 2
                notificationsLabel.text = "Notifications"
                notificationsLabel.isUserInteractionEnabled = false
                notificationsLabel.textColor = Constants.textColor.hexToUiColor()
                notificationsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.notificationsButton?.addSubview(notificationsLabel)
            }
            self.notificationsArrow = UIImageView(frame: CGRect(x: notificationsButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let notificationsArrow = self.notificationsArrow {
                notificationsArrow.frame = CGRect(x: notificationsButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                notificationsArrow.image = UIImage(systemName: "chevron.right")
                notificationsArrow.contentMode = .scaleAspectFit
                notificationsArrow.tintColor = Constants.textColor.hexToUiColor()
                self.notificationsButton?.addSubview(notificationsArrow)
            }
            self.view.addSubview(notificationsButton)
        }
        self.privacyPolicyButton = UIButton(frame: CGRect(x: 15, y: self.notificationsButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let privacyPolicyButton = self.privacyPolicyButton {
            privacyPolicyButton.addReportShadow()
            privacyPolicyButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            privacyPolicyButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            privacyPolicyButton.isUserInteractionEnabled = true
            privacyPolicyButton.layer.cornerRadius = 12
            self.privacyPolicyImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let privacyPolicyImage = privacyPolicyImage {
                privacyPolicyImage.image = UIImage(systemName: "lock.shield")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .light, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                privacyPolicyImage.tintColor = Constants.textColor.hexToUiColor()
                privacyPolicyImage.contentMode = .scaleAspectFit
                privacyPolicyImage.center.y = privacyPolicyButton.frame.height / 2
                self.privacyPolicyButton?.addSubview(privacyPolicyImage)
            }
            let profButtonMax = (self.notificationsImage?.frame.maxX)! + 10
            self.privacyPolicyLabel = UILabel(frame: CGRect(x: profButtonMax, y: profButtonMax, width: privacyPolicyButton.frame.width - 15 - 30, height: self.privacyPolicyButton!.frame.height))
            if let privacyPolicyLabel = self.privacyPolicyLabel {
                privacyPolicyLabel.center.y = self.privacyPolicyButton!.frame.height / 2
                privacyPolicyLabel.text = "Privacy Policy"
                privacyPolicyLabel.isUserInteractionEnabled = false
                privacyPolicyLabel.textColor = Constants.textColor.hexToUiColor()
                privacyPolicyLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.privacyPolicyButton?.addSubview(privacyPolicyLabel)
            }
            self.privacyPolicyArrow = UIImageView(frame: CGRect(x: privacyPolicyButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let privacyPolicyArrow = self.privacyPolicyArrow {
                privacyPolicyArrow.frame = CGRect(x: privacyPolicyButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                privacyPolicyArrow.image = UIImage(systemName: "chevron.right")
                privacyPolicyArrow.contentMode = .scaleAspectFit
                privacyPolicyArrow.tintColor = Constants.textColor.hexToUiColor()
                self.privacyPolicyButton?.addSubview(privacyPolicyArrow)
            }
            self.view.addSubview(privacyPolicyButton)
        }
        
        self.termsButton = UIButton(frame: CGRect(x: 15, y: self.privacyPolicyButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let termsButton = self.termsButton {
            termsButton.addReportShadow()
            termsButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            termsButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            termsButton.isUserInteractionEnabled = true
            termsButton.layer.cornerRadius = 12
            self.termsImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let termsImage = termsImage {
                termsImage.image = UIImage(systemName: "doc.text")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .light, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                termsImage.tintColor = Constants.textColor.hexToUiColor()
                termsImage.center.y = termsButton.frame.height / 2
                termsImage.contentMode = .scaleAspectFit
                self.termsButton?.addSubview(termsImage)
            }
            let profButtonMax = (self.notificationsImage?.frame.maxX)! + 10
            self.termsLabel = UILabel(frame: CGRect(x: profButtonMax, y: profButtonMax, width: termsButton.frame.width - 15 - 30, height: self.termsButton!.frame.height))
            if let termsLabel = self.termsLabel {
                termsLabel.center.y = self.termsButton!.frame.height / 2
                termsLabel.text = "Terms of Service"
                termsLabel.isUserInteractionEnabled = false
                termsLabel.textColor = Constants.textColor.hexToUiColor()
                termsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.termsButton?.addSubview(termsLabel)
            }
            self.termsArrow = UIImageView(frame: CGRect(x: termsButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let termsArrow = self.termsArrow {
                termsArrow.frame = CGRect(x: termsButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                termsArrow.image = UIImage(systemName: "chevron.right")
                termsArrow.contentMode = .scaleAspectFit
                termsArrow.tintColor = Constants.textColor.hexToUiColor()
                self.termsButton?.addSubview(termsArrow)
            }
            self.view.addSubview(termsButton)
        }
        self.communityButton = UIButton(frame: CGRect(x: 15, y: self.termsButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let communityButton = self.communityButton {
            communityButton.addReportShadow()
            communityButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            communityButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            communityButton.isUserInteractionEnabled = true
            communityButton.layer.cornerRadius = 12
            self.communityImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let communityImage = communityImage {
                communityImage.image = UIImage(systemName: "doc.append")?.applyingSymbolConfiguration(.init(pointSize: 14, weight: .light, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                communityImage.tintColor = Constants.textColor.hexToUiColor()
                communityImage.center.y = communityButton.frame.height / 2
                communityImage.contentMode = .scaleAspectFit
                self.communityButton?.addSubview(communityImage)
            }
            let profButtonMax = (self.communityImage?.frame.maxX)! + 10
            self.communityLabel = UILabel(frame: CGRect(x: profButtonMax, y: profButtonMax, width: communityButton.frame.width - 15 - 30, height: self.communityButton!.frame.height))
            if let communityLabel = self.communityLabel {
                communityLabel.center.y = self.communityButton!.frame.height / 2
                communityLabel.text = "Community Guidelines"
                communityLabel.isUserInteractionEnabled = false
                communityLabel.textColor = Constants.textColor.hexToUiColor()
                communityLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.communityButton?.addSubview(communityLabel)
            }
            self.communityArrow = UIImageView(frame: CGRect(x: communityButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let communityArrow = self.communityArrow {
                communityArrow.frame = CGRect(x: communityButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                communityArrow.image = UIImage(systemName: "chevron.right")
                communityArrow.contentMode = .scaleAspectFit
                communityArrow.tintColor = Constants.textColor.hexToUiColor()
                self.communityButton?.addSubview(communityArrow)
            }
            self.view.addSubview(communityButton)
        }
        
        self.logoutButton = UIButton(frame: CGRect(x: 15, y: self.communityButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let logoutButton = self.logoutButton {
            logoutButton.addReportShadow()
            logoutButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            logoutButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            logoutButton.isUserInteractionEnabled = true
            logoutButton.layer.cornerRadius = 12
            self.logooutImage = UIImageView(frame: CGRect(x: 15, y: 10, width: 15, height: 15))
            if let logooutImage = logooutImage {
                logooutImage.image = UIImage(systemName: "delete.left.fill")?.applyingSymbolConfiguration(.init(pointSize: 16, weight: .regular, scale: .medium))?.image(withTintColor: Constants.universalRed.hexToUiColor())
                logooutImage.tintColor = Constants.universalRed.hexToUiColor()
                logooutImage.center.y = logoutButton.frame.height / 2
                logooutImage.contentMode = .scaleAspectFit
                self.logoutButton?.addSubview(logooutImage)
            }
            let profButtonMax = (self.logooutImage?.frame.maxX)! + 10
            self.logoutLabel = UILabel(frame: CGRect(x: profButtonMax, y: 0, width: self.logoutButton!.frame.width - 15 - 30, height: self.logoutButton!.frame.height))
            if let logoutLabel = self.logoutLabel {
                logoutLabel.center.y = self.logoutButton!.frame.height / 2
                logoutLabel.text = "Log out"
                logoutLabel.isUserInteractionEnabled = false
                logoutLabel.textColor = Constants.universalRed.hexToUiColor()
                logoutLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
                self.logoutButton?.addSubview(logoutLabel)
            }
            self.view.addSubview(logoutButton)
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
    self.hideKeyboardWhenTappedAround()
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
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = Constants.textColor.hexToUiColor()
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            if self.isPostReport == false {
                textView.text = "Please provide the reasons that you believe this profile contains \"\(self.reportType)\" in multiple posts."
            } else {
                textView.text = "Please provide the reasons that you believe this post contains \"\(self.reportType)\"."
            }
        
            textView.textColor = UIColor.lightGray
        }
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
    @objc internal func reportButtonTapped(_ button: UIButton) {
        print("* report button pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        if let label = button.subviews[1] as? UILabel {
            reportType = label.text ?? ""
            print("* adding more stuff for \(reportType)")
            if reportType == "Log out" {
                print("* prompting for logout?")
                var alertController: AlertViewController = {
                    let font = UIFont(name: "CourierNewPSMT", size: 16)
                    let alertController = AlertViewController(title: "Confirmation", body: "Are you sure you want to log out?", titleFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14), bodyFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14), buttonFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14))
                    let cancelAction = AlertAction(title: "Nah", style: .custom(textColor: UIColor.darkGray)) {
                        
                    }
                    let logoutAction = AlertAction(title: "Yup, Log out", style: .custom(textColor: Constants.universalRed.hexToUiColor())) {
                        logout()
                        print("pushing login")
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: true)
                    }
                    alertController.addAction(cancelAction)
                                            alertController.addAction(logoutAction)
                    return alertController
                }()
                self.presenter.presentationType = .alert
                self.presenter.transitionType = nil
                self.presenter.dismissTransitionType = nil
                self.presenter.dismissAnimated = true
                let animation = CoverVerticalAnimation(options: .spring(duration: 0.5,
                                                                        delay: 0,
                                                                        damping: 0.7,
                                                                        velocity: 0))
                let coverVerticalWithSpring = TransitionType.custom(animation)
                self.presenter.transitionType = coverVerticalWithSpring
                self.presenter.dismissTransitionType = coverVerticalWithSpring
                self.customPresentViewController(self.presenter, viewController: alertController, animated: true)
            } else {
                
                if reportType == "Notifications" {
                    hideAllBaseElements()
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
                        let seconds = 0.2
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            // Put your code which should be executed with a delay here
                            self.showNotificationsStuffs()
                        }
                        
                        }
                } else if reportType == "Blocked Accounts" {
                    
                    if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userListViewController") as? userListViewController {
                        print("* opening blocked list")
                        vc.userConfig = userListConfig(type: "blocked", originalAuthorID: userID!, postID: "", numberToPutInFront: 0, shouldhideBackbutton: false)
//                        self.navigationController?.pushViewController(vc, animated: true)
//                        self.present(vc, animated: true)
                        self.dismiss(animated: true)
                        let seconds = 0.2
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            // Put your code which should be executed with a delay here
                            self.parentVC.navigationController?.pushViewController(vc, animated: true)
                        }
                       
                        
                    }
                } else if reportType == "Saved Posts" {
                    
                    if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "savedCollectionsVC") as? SavedCollectionsViewController {
                        print("* opening saved posts")
//                        self.navigationController?.pushViewController(vc, animated: true)
//                        self.present(vc, animated: true)
                        self.dismiss(animated: true)
                        let seconds = 0.2
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            // Put your code which should be executed with a delay here
                            self.parentVC.navigationController?.pushViewController(vc, animated: true)
                        }
                       
                        
                    }
                } else if reportType == "Profile" {
                    if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "editProfileVC") as? EditProfileVC {
                        print("* opening profile list")
                        self.dismiss(animated: true)
                        let seconds = 0.2
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            // Put your code which should be executed with a delay here
                            self.parentVC.navigationController?.pushViewController(vc, animated: true)
                        }
                       
                        
                    }
                }
            }
            
            
        }
    }
    func showNotificationsStuffs() {
       print("* showing notification stuffs")
        settingsLabel?.text = "Notifications"
        settingsLabel?.center.x = self.view.center.x
        settingsLabel?.fadeIn()
        allNotificationsView?.fadeIn()
        allNotificationsLabel?.fadeIn()
        allNotificationsCheckbox?.fadeIn()
        individualNotificationsView?.fadeIn()
//        notificationsBackbutton?.fadeIn()
    }
    func hideAllBaseElements() {
        self.settingsLabel?.fadeOut()
        self.savedButton?.fadeOut()
        self.profileButton?.fadeOut()
        self.blockedAccountsButton?.fadeOut()
        self.notificationsButton?.fadeOut()
        self.privacyPolicyButton?.fadeOut()
        self.termsButton?.fadeOut()
        self.communityButton?.fadeOut()
        self.logoutButton?.fadeOut()
    }
}
extension SettingsPopupController: PanModalPresentable {

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
//    var shortFormHeight: PanModalHeight {
//        return .contentHeight(300)
//    }

    var anchorModalToLongForm: Bool {
        return false
    }
}

