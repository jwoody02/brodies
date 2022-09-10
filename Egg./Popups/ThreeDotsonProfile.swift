//
//  ThreeDotsonProfile.swift
//  Egg.
//
//  Created by Jordan Wood on 8/13/22.
//

import UIKit
import PanModal
import Presentr
import FirebaseFirestore
import FirebaseAuth
import SPAlert

class ThreeDotsOnProfileController: UIViewController {
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    private var db = Firestore.firestore()
    internal var shareBigButton: UIButton?
    internal var shareIcon: UIImageView?
    internal var shareLabel: UILabel?
    
    internal var blockBigButton: UIButton?
    internal var blockIcon: UIImageView?
    internal var blockLabel: UILabel?
    
    internal var reportBigButton: UIButton?
    internal var reportIcon: UIImageView?
    internal var reportLabel: UILabel?
    
    var profileUID = ""
    var isBlocked = false
    var profileUserName = ""
    var presenter = Presentr(presentationType: .alert)
    var parentVC = MyProfileViewController()
    
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
                    shareLabel.frame = CGRect(x: 0, y: Int(shareIcon.frame.maxY) + 5, width: bigThreeButtonWidths, height: 22)
                    shareLabel.center.x = CGFloat(bigThreeButtonWidths / 2)
                    shareLabel.isUserInteractionEnabled = false
                    shareLabel.textColor = Constants.textColor.hexToUiColor()
                    self.shareBigButton?.addSubview(shareLabel)
                }
            }
            self.view.addSubview(shareBigButton)
        }
        
        self.blockBigButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let blockBigButton = self.blockBigButton {
            blockBigButton.layer.cornerRadius = CGFloat(cornerRadii)
            blockBigButton.clipsToBounds = true
            blockBigButton.addReportShadow()
            blockBigButton.backgroundColor = buttonBackgrounds
            blockBigButton.frame = CGRect(x: Int(self.shareBigButton?.frame.maxX ?? 15) + Int(interButtonPadding), y: 15, width: bigThreeButtonWidths, height: 70)
            blockBigButton.addTarget(self, action: #selector(blockButtonPressed(_:)), for: .touchUpInside)
            self.blockIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let blockIcon = self.blockIcon {
                if isBlocked {
                    blockIcon.image = UIImage(systemName: "circle")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                } else {
                    blockIcon.image = UIImage(systemName: "circle.slash")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                }
                
                
                blockIcon.frame = CGRect(x: 0, y: 17, width: 22, height: 22)
                blockIcon.center.x = CGFloat(bigThreeButtonWidths / 2)
                blockIcon.isUserInteractionEnabled = false
                blockIcon.contentMode = .scaleAspectFit
                self.blockBigButton?.addSubview(blockIcon)
                self.blockLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                if let blockLabel = self.blockLabel {
                    if isBlocked {
                        blockLabel.text = "Unblock"
                    } else {
                        blockLabel.text = "Block"
                    }
                    
                    blockLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
                    blockLabel.textAlignment = .center
                    blockLabel.frame = CGRect(x: 0, y: Int(blockIcon.frame.maxY) + 5, width: bigThreeButtonWidths, height: 22)
                    blockLabel.center.x = CGFloat(bigThreeButtonWidths / 2)
                    blockLabel.isUserInteractionEnabled = false
                    blockLabel.textColor = Constants.textColor.hexToUiColor()
                    self.blockBigButton?.addSubview(blockLabel)
                }
            }
            self.view.addSubview(blockBigButton)
        }
        
        self.reportBigButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let reportBigButton = self.reportBigButton {
            reportBigButton.layer.cornerRadius = CGFloat(cornerRadii)
            reportBigButton.clipsToBounds = true
            reportBigButton.addTarget(self, action: #selector(ReportButtonPressed(_:)), for: .touchUpInside)
            reportBigButton.addReportShadow()
            reportBigButton.backgroundColor = buttonBackgrounds
            reportBigButton.frame = CGRect(x: Int(self.blockBigButton?.frame.maxX ?? 15) + Int(interButtonPadding), y: 15, width: bigThreeButtonWidths, height: 70)
            self.reportIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let reportIcon = self.reportIcon {
                reportIcon.image = UIImage(systemName: "exclamationmark.square")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.universalRed.hexToUiColor())
                reportIcon.frame = CGRect(x: 0, y: 17, width: 22, height: 22)
                reportIcon.center.x = CGFloat(bigThreeButtonWidths / 2)
                reportIcon.isUserInteractionEnabled = false
                reportIcon.contentMode = .scaleAspectFit
                self.reportBigButton?.addSubview(reportIcon)
                self.reportLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                if let reportLabel = self.reportLabel {
                    reportLabel.text = "Report"
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
    @objc internal func blockButtonPressed(_ button: UIButton) {
        print("* showing block popup menu")
        if self.isBlocked == true {
            print("* block pressed, unblocking user")
            let userID = Auth.auth().currentUser?.uid
            self.db.collection("blocked").document(userID!).collection("blocked_users").document(self.profileUID).delete()  { err in
                if let err = err {
                    print("Error writing document: \(err)")
                    SPAlert.present(title: "Unknown error occured", preset: .error, haptic: .error)
                } else {
                    print("Document successfully written!")
                    
                    SPAlert.present(title: "Successfully unblocked", preset: .done, haptic: .success)
                    self.blockLabel!.text = "Block"
                    self.blockIcon!.image = UIImage(systemName: "circle.slash")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                    self.isBlocked = !self.isBlocked
                    self.parentVC.userHasBlocked = false
                    self.parentVC.updatebasicInfo()
                    
                    self.dismiss(animated: true)
                    
                }
            }
        } else {
            var alertController: AlertViewController = {
                let alertController = AlertViewController(title: "Confirmation", body: "Are you sure you wanna block @\(self.profileUserName)? If ya'll make up, you can always unblock from settings so no pressure.", titleFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14), bodyFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14), buttonFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14))
                let cancelAction = AlertAction(title: "Cancel", style: .custom(textColor: .darkGray)) {
                    
                }
                let blockAction = AlertAction(title: "Block", style: .custom(textColor: Constants.universalRed.hexToUiColor())) {
                    if self.isBlocked == true {
                        
                    } else {
                        print("* block pressed, blocking user")
                        let userID = Auth.auth().currentUser?.uid
                        self.db.collection("blocked").document(userID!).collection("blocked_users").document(self.profileUID).setData(["blocked_at":Date().timeIntervalSince1970])  { err in
                            if let err = err {
                                print("Error writing document: \(err)")
                                SPAlert.present(title: "Unknown error occured", preset: .error, haptic: .error)
                            } else {
                                print("Document successfully written!")
                                
                                SPAlert.present(title: "Successfully blocked @\(self.profileUserName)", preset: .done, haptic: .success)
                                self.blockLabel!.text = "Unblock"
                                self.blockIcon!.image = UIImage(systemName: "circle")?.applyingSymbolConfiguration(.init(pointSize: 18, weight: .regular, scale: .medium))?.image(withTintColor: Constants.textColor.hexToUiColor())
                                
                                self.parentVC.userHasBlocked = true
                                self.parentVC.updatebasicInfo()
                                
                                self.isBlocked = !self.isBlocked
                                self.dismiss(animated: true)
                                
                            }
                        }
                    }
                   
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
        }
        
        
    }
    @objc internal func ReportButtonPressed(_ button: UIButton) {
        print("* report button pressed")
        let vc = ReportPostsController()
        vc.postAuthorID = self.profileUID
        vc.isPostReport = false
        self.presentPanModal(vc)
        
    }
}

extension ThreeDotsOnProfileController: PanModalPresentable {

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


