//
//  ThreeDotsOnPost.swift
//  Egg.
//
//  Created by Jordan Wood on 8/13/22.
//

import UIKit
import PanModal
import FirebaseAuth
import Presentr
import FirebaseFirestore
import FirebaseAnalytics
import SPAlert
import FirebaseDynamicLinks

class ThreeDotsOnPostController: UIViewController {
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    
    internal var shareBigButton: UIButton?
    internal var shareIcon: UIImageView?
    internal var shareLabel: UILabel?
    
    internal var linkBigButton: UIButton?
    internal var linkIcon: UIImageView?
    internal var linkLabel: UILabel?
    
    internal var reportBigButton: UIButton?
    internal var reportIcon: UIImageView?
    internal var reportLabel: UILabel?
    
    var postID = ""
    var authorOfPost = ""
    var imagePostURL = ""
    var presenter = Presentr(presentationType: .alert)
    private var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        bigThreeButtonWidths = (Int(self.view.frame.width) - interButtonPadding*4) / 3
        setupUI()
    }
    func setupUI() {
        self.shareBigButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let shareBigButton = self.shareBigButton {
            shareBigButton.layer.cornerRadius = CGFloat(cornerRadii)
            shareBigButton.clipsToBounds = true
            shareBigButton.addReportShadow()
            shareBigButton.backgroundColor = buttonBackgrounds
            shareBigButton.addTarget(self, action: #selector(ShareButtonPressed(_:)), for: .touchUpInside)
            shareBigButton.frame = CGRect(x: 15, y: 15, width: bigThreeButtonWidths, height: 70)
            self.shareIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let shareIcon = self.shareIcon {
                shareIcon.image = UIImage(systemName: "square.and.arrow.up")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                shareIcon.frame = CGRect(x: 0, y: 17, width: 22, height: 22)
                shareIcon.center.x = CGFloat(bigThreeButtonWidths / 2)
                shareIcon.isUserInteractionEnabled = false
                shareIcon.contentMode = .scaleAspectFit
                self.shareBigButton?.addSubview(shareIcon)
                self.shareLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                if let shareLabel = self.shareLabel {
                    shareLabel.text = "Share"
                    shareLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
                    shareLabel.textAlignment = .center
                    shareLabel.textColor = Constants.textColor.hexToUiColor()
                    shareLabel.frame = CGRect(x: 0, y: Int(shareIcon.frame.maxY) + 5, width: bigThreeButtonWidths, height: 22)
                    shareLabel.center.x = CGFloat(bigThreeButtonWidths / 2)
                    shareLabel.isUserInteractionEnabled = false
                    self.shareBigButton?.addSubview(shareLabel)
                }
            }
            self.view.addSubview(shareBigButton)
        }
        
        
       
        
        self.linkBigButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let linkBigButton = self.linkBigButton {
            linkBigButton.layer.cornerRadius = CGFloat(cornerRadii)
            linkBigButton.clipsToBounds = true
            linkBigButton.addReportShadow()
            linkBigButton.backgroundColor = buttonBackgrounds
            linkBigButton.addTarget(self, action: #selector(LinkButtonPressed(_:)), for: .touchUpInside)
            linkBigButton.frame = CGRect(x: Int(self.shareBigButton?.frame.maxX ?? 15) + Int(interButtonPadding), y: 15, width: bigThreeButtonWidths, height: 70)
            self.linkIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let linkIcon = self.linkIcon {
                linkIcon.image = UIImage(systemName: "link")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                linkIcon.frame = CGRect(x: 0, y: 17, width: 22, height: 22)
                linkIcon.center.x = CGFloat(bigThreeButtonWidths / 2)
                linkIcon.isUserInteractionEnabled = false
                linkIcon.contentMode = .scaleAspectFit
                self.linkBigButton?.addSubview(linkIcon)
                self.linkLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                if let linkLabel = self.linkLabel {
                    linkLabel.text = "Link"
                    linkLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
                    linkLabel.textAlignment = .center
                    linkLabel.frame = CGRect(x: 0, y: Int(linkIcon.frame.maxY) + 5, width: bigThreeButtonWidths, height: 22)
                    linkLabel.center.x = CGFloat(bigThreeButtonWidths / 2)
                    linkLabel.isUserInteractionEnabled = false
                    linkLabel.textColor = Constants.textColor.hexToUiColor()
                    self.linkBigButton?.addSubview(linkLabel)
                }
            }
            self.view.addSubview(linkBigButton)
        }
        
        self.reportBigButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let reportBigButton = self.reportBigButton {
            let userID : String = (Auth.auth().currentUser?.uid)!
            reportBigButton.layer.cornerRadius = CGFloat(cornerRadii)
            reportBigButton.addReportShadow()
            reportBigButton.clipsToBounds = true
            reportBigButton.backgroundColor = buttonBackgrounds
            reportBigButton.frame = CGRect(x: Int(self.linkBigButton?.frame.maxX ?? 15) + Int(interButtonPadding), y: 15, width: bigThreeButtonWidths, height: 70)
            reportBigButton.addTarget(self, action: #selector(ReportButtonPressed(_:)), for: .touchUpInside)
            self.reportIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let reportIcon = self.reportIcon {
                if authorOfPost == userID {
                    reportIcon.image = UIImage(systemName: "trash")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.universalRed.hexToUiColor())
                } else {
                    reportIcon.image = UIImage(systemName: "exclamationmark.square")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.universalRed.hexToUiColor())
                }
                
                reportIcon.frame = CGRect(x: 0, y: 17, width: 22, height: 22)
                reportIcon.center.x = CGFloat(bigThreeButtonWidths / 2)
                reportIcon.isUserInteractionEnabled = false
                reportIcon.contentMode = .scaleAspectFit
                self.reportBigButton?.addSubview(reportIcon)
                self.reportLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                if let reportLabel = self.reportLabel {
                    if authorOfPost == userID {
                        reportLabel.text = "Delete"
                    } else {
                        reportLabel.text = "Report"
                    }
                    reportLabel.textColor = Constants.universalRed.hexToUiColor()
                    reportLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
                    reportLabel.textAlignment = .center
                    reportLabel.frame = CGRect(x: 0, y: Int(reportIcon.frame.maxY) + 5, width: bigThreeButtonWidths, height: 22)
                    reportLabel.center.x = CGFloat(bigThreeButtonWidths / 2)
                    reportLabel.isUserInteractionEnabled = false
                    self.reportBigButton?.addSubview(reportLabel)
                }
            }
            self.view.addSubview(reportBigButton)
        }
    }
    @objc internal func ReportButtonPressed(_ button: UIButton) {
        print("* report button pressed")
        let userID : String = (Auth.auth().currentUser?.uid)!
        if authorOfPost == userID {
            print("* delete post?")
            var alertController: AlertViewController = {
                let alertController = AlertViewController(title: "Confirmation", body: "Are you sure you wanna delete this post? This action can't be undone.", titleFont: UIFont(name: Constants.globalFontBold, size: 13), bodyFont: UIFont(name: Constants.globalFontBold, size: 13), buttonFont: UIFont(name: Constants.globalFontBold, size: 13))
                let cancelAction = AlertAction(title: "Cancel", style: .custom(textColor: .darkGray)) {
                    
                }
                let blockAction = AlertAction(title: "Delete", style: .custom(textColor: Constants.universalRed.hexToUiColor())) {
                    print("* delete confirmed")
                    self.db.collection("posts").document(userID).collection("posts").document(self.postID).delete()
                    self.dismiss(animated: true)
                    SPAlert.present(title: "Successfully Deleted!", preset: .done, haptic: .success)
                    
                }
                alertController.addAction(cancelAction)
                alertController.addAction(blockAction)
                return alertController
            }()
            let width = ModalSize.full
            let height = ModalSize.custom(size: 300)
            let center = ModalCenterPosition.customOrigin(origin: CGPoint(x: 0, y: UIScreen.main.bounds.height - 300))
            let customType = PresentationType.custom(width: width, height: height, center: center)
            self.presenter = Presentr(presentationType: customType)
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
            let vc = ReportPostsController()
            vc.postID = self.postID
            vc.postAuthorID = self.authorOfPost
            self.presentPanModal(vc)
        }
        
    }
    @objc internal func LinkButtonPressed(_ button: UIButton) {
        saveShareLinkToClipboard()
    }
    @objc internal func ShareButtonPressed(_ button: UIButton) {
        guard let link = URL(string: "https://www.brodies.app") else { return }
        let dynamicLinksDomainURIPrefix = "https://brodies.page.link/post?uid=\(self.authorOfPost)&posti=\(self.postID)"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)

        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.caliwood.eggtopia")
        linkBuilder?.iOSParameters?.appStoreID = "1637329972"
//        linkBuilder?.iOSParameters?.minimumAppVersion = "1.2.3"

        linkBuilder?.analyticsParameters = DynamicLinkGoogleAnalyticsParameters(source: "inapp",
                                                                               medium: "social",
                                                                               campaign: "share-link-generated")

        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = "View post on Brodie's"
        linkBuilder?.socialMetaTagParameters?.imageURL = URL(string: "\(self.imagePostURL)")

        guard let longDynamicLink = linkBuilder?.url else { return }
        print("The long URL is: \(longDynamicLink)")
        DynamicLinkComponents.shortenURL(longDynamicLink, options: nil) { url, warnings, error in
            guard let url = url, error != nil else { self.openPageForLink(url: longDynamicLink.absoluteString); return }
          print("The short URL is: \(url)")
            self.openPageForLink(url: url.absoluteString)
        }
    }
    func saveShareLinkToClipboard() {
        guard let link = URL(string: "https://www.brodies.app") else { return }
        let dynamicLinksDomainURIPrefix = "https://brodies.page.link/post?uid=\(self.authorOfPost)&posti=\(self.postID)"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)

        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.caliwood.eggtopia")
        linkBuilder?.iOSParameters?.appStoreID = "1637329972"
//        linkBuilder?.iOSParameters?.minimumAppVersion = "1.2.3"

        linkBuilder?.analyticsParameters = DynamicLinkGoogleAnalyticsParameters(source: "inapp",
                                                                               medium: "social",
                                                                               campaign: "share-link-generated")

        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = "View post on Brodie's"
        linkBuilder?.socialMetaTagParameters?.imageURL = URL(string: "\(self.imagePostURL)")

        guard let longDynamicLink = linkBuilder?.url else { return }
        print("The long URL is: \(longDynamicLink)")
        DynamicLinkComponents.shortenURL(longDynamicLink, options: nil) { url, warnings, error in
            guard let url = url, error != nil else { UIPasteboard.general.string = longDynamicLink.absoluteString; SPAlert.present(title: "Link saved to clipboard!", preset: .done, haptic: .success); return }
          print("The short URL is: \(url)")
            UIPasteboard.general.string = url.absoluteString
            SPAlert.present(title: "Link saved to clipboard!", preset: .done, haptic: .success)
        }
    }
    func openPageForLink(url: String) {
        if let link = NSURL(string: url)
                {
            let objectsToShare = [link] as [Any]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
//                    activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            self.present(activityVC, animated: true, completion: nil)
                }
    }
}

extension ThreeDotsOnPostController: PanModalPresentable {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var panScrollable: UIScrollView? {
        return nil
    }

    var longFormHeight: PanModalHeight {
        let actualHeight = 200
        
        return .maxHeightWithTopInset(UIScreen.main.bounds.height-CGFloat(actualHeight))
    }

    var anchorModalToLongForm: Bool {
        return false
    }
}

