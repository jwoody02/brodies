//
//  ReportPost.swift
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

class ReportPostsController: UIViewController, UITextViewDelegate {
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    private var db = Firestore.firestore()
    
    internal var reportIssueLabel: UILabel?
    internal var whatIsWrongLabel: UILabel?
    
    internal var itsSpamButton: UIButton?
    internal var itsSpamLabel: UILabel?
    internal var itsSpamArrow: UIImageView?
    
    internal var adultContentButton: UIButton?
    internal var adultContentLabel: UILabel?
    internal var adultArrow: UIImageView?
    
    internal var illegalContentButton: UIButton?
    internal var illegalContentLabel: UILabel?
    internal var illegalArrow: UIImageView?
    
    internal var illegalServicesButton: UIButton?
    internal var illegalServicesLabel: UILabel?
    internal var illegalServicesArrow: UIImageView?
    
    internal var hateSpeechButton: UIButton?
    internal var hateSpeechLabel: UILabel?
    internal var hateSpeechArrow: UIImageView?
    
    internal var OtherButton: UIButton?
    internal var OtherLabel: UILabel?
    internal var OtherArrow: UIImageView?
    
    internal var reportTextView: UITextView?
    internal var submitButton: UIButton?
    
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
        setupUI()
//        self.dismissDetail()
    }
    func setupUI() {
        
        self.reportIssueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let reportIssueLabel = self.reportIssueLabel {
            reportIssueLabel.text = "Report an issue"
            reportIssueLabel.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 25)
            reportIssueLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 15)
            reportIssueLabel.textColor = .darkGray
            reportIssueLabel.textAlignment = .center
            self.view.addSubview(reportIssueLabel)
        }
        self.whatIsWrongLabel = UILabel(frame: CGRect(x: 15, y: self.reportIssueLabel!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 100))
        if let whatIsWrongLabel = self.whatIsWrongLabel {
            if self.isPostReport == false {
                whatIsWrongLabel.text = "Please only report a profile if user has uploaded posts that belong in one or more categories listed below. Excessive false reporting on profiles can lead to suspension and possible ban. If you or someone you know is in danger, immediately go to local authorities."
            } else {
                whatIsWrongLabel.text = "Please only report a post if it belongs in one of the categories listed below. Excessive false reporting on posts can lead to suspension and possible ban. If you or someone you know is in danger, immediately go to local authorities."
            }
            whatIsWrongLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
            whatIsWrongLabel.textColor = .lightGray
            whatIsWrongLabel.numberOfLines = 0
            whatIsWrongLabel.textAlignment = .center
            self.view.addSubview(whatIsWrongLabel)
        }
        
        self.itsSpamButton = UIButton(frame: CGRect(x: 15, y: self.whatIsWrongLabel!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let itsSpamButton = self.itsSpamButton {
            itsSpamButton.addReportShadow()
            itsSpamButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            itsSpamButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            itsSpamButton.isUserInteractionEnabled = true
            itsSpamButton.layer.cornerRadius = 12
            self.itsSpamLabel = UILabel(frame: CGRect(x: 15, y: 0, width: itsSpamButton.frame.width - 15 - 30, height: self.itsSpamButton!.frame.height))
            if let itsSpamLabel = self.itsSpamLabel {
                itsSpamLabel.center.y = self.itsSpamButton!.frame.height / 2
                itsSpamLabel.text = "Spam"
                itsSpamLabel.isUserInteractionEnabled = false
                itsSpamLabel.textColor = Constants.textColor.hexToUiColor()
                itsSpamLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.itsSpamButton?.addSubview(itsSpamLabel)
            }
            self.itsSpamArrow = UIImageView(frame: CGRect(x: itsSpamButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let itsSpamArrow = self.itsSpamArrow {
                itsSpamArrow.frame = CGRect(x: itsSpamButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                itsSpamArrow.image = UIImage(systemName: "chevron.right")
                itsSpamArrow.contentMode = .scaleAspectFit
                itsSpamArrow.tintColor = Constants.textColor.hexToUiColor()
                self.itsSpamButton?.addSubview(itsSpamArrow)
            }
            self.view.addSubview(itsSpamButton)
        }
        
        self.adultContentButton = UIButton(frame: CGRect(x: 15, y: self.itsSpamButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let adultContentButton = self.adultContentButton {
            adultContentButton.addReportShadow()
            adultContentButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            adultContentButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            adultContentButton.isUserInteractionEnabled = true
            adultContentButton.layer.cornerRadius = 12
            self.adultContentLabel = UILabel(frame: CGRect(x: 15, y: 0, width: adultContentButton.frame.width - 15 - 30, height: self.adultContentButton!.frame.height))
            if let adultContentLabel = self.adultContentLabel {
                adultContentLabel.center.y = self.adultContentButton!.frame.height / 2
                adultContentLabel.text = "Sexual or adult content"
                adultContentLabel.isUserInteractionEnabled = false
                adultContentLabel.textColor = Constants.textColor.hexToUiColor()
                adultContentLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.adultContentButton?.addSubview(adultContentLabel)
            }
            self.adultArrow = UIImageView(frame: CGRect(x: adultContentButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let adultArrow = self.adultArrow {
                adultArrow.frame = CGRect(x: adultContentButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                adultArrow.image = UIImage(systemName: "chevron.right")
                adultArrow.contentMode = .scaleAspectFit
                adultArrow.tintColor = Constants.textColor.hexToUiColor()
                self.adultContentButton?.addSubview(adultArrow)
            }
            self.view.addSubview(adultContentButton)
        }
        
        self.illegalContentButton = UIButton(frame: CGRect(x: 15, y: self.adultContentButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let illegalContentButton = self.illegalContentButton {
            illegalContentButton.addReportShadow()
            illegalContentButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            illegalContentButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            illegalContentButton.isUserInteractionEnabled = true
            illegalContentButton.layer.cornerRadius = 12
            self.illegalContentLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.illegalContentButton!.frame.width - 15 - 30, height: self.illegalContentButton!.frame.height))
            if let illegalContentLabel = self.illegalContentLabel {
                illegalContentLabel.center.y = self.illegalContentButton!.frame.height / 2
                illegalContentLabel.text = "Illegal content or imagery"
                illegalContentLabel.isUserInteractionEnabled = false
                illegalContentLabel.textColor = Constants.textColor.hexToUiColor()
                illegalContentLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.illegalContentButton?.addSubview(illegalContentLabel)
            }
            self.illegalArrow = UIImageView(frame: CGRect(x: illegalContentButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let illegalArrow = self.illegalArrow {
                illegalArrow.frame = CGRect(x: illegalContentButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                illegalArrow.image = UIImage(systemName: "chevron.right")
                illegalArrow.contentMode = .scaleAspectFit
                illegalArrow.tintColor = Constants.textColor.hexToUiColor()
                self.illegalContentButton?.addSubview(illegalArrow)
            }
            self.view.addSubview(illegalContentButton)
        }
        
        self.illegalServicesButton = UIButton(frame: CGRect(x: 15, y: self.illegalContentButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let illegalServicesButton = self.illegalServicesButton {
            illegalServicesButton.addReportShadow()
            illegalServicesButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            illegalServicesButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            illegalServicesButton.isUserInteractionEnabled = true
            illegalServicesButton.layer.cornerRadius = 12
            self.illegalServicesLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.illegalServicesButton!.frame.width - 15 - 30, height: self.illegalServicesButton!.frame.height))
            if let illegalServicesLabel = self.illegalServicesLabel {
                illegalServicesLabel.center.y = self.illegalServicesButton!.frame.height / 2
                illegalServicesLabel.text = "Illegal products or services"
                illegalServicesLabel.isUserInteractionEnabled = false
                illegalServicesLabel.textColor = Constants.textColor.hexToUiColor()
                illegalServicesLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.illegalServicesButton?.addSubview(illegalServicesLabel)
            }
            self.illegalServicesArrow = UIImageView(frame: CGRect(x: illegalServicesButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let illegalServicesArrow = self.illegalServicesArrow {
                illegalServicesArrow.frame = CGRect(x: illegalServicesButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                illegalServicesArrow.image = UIImage(systemName: "chevron.right")
                illegalServicesArrow.contentMode = .scaleAspectFit
                illegalServicesArrow.tintColor = Constants.textColor.hexToUiColor()
                self.illegalServicesButton?.addSubview(illegalServicesArrow)
            }
            self.view.addSubview(illegalServicesButton)
        }
        
        self.hateSpeechButton = UIButton(frame: CGRect(x: 15, y: self.illegalServicesButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let hateSpeechButton = self.hateSpeechButton {
            hateSpeechButton.addReportShadow()
            hateSpeechButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            hateSpeechButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            hateSpeechButton.isUserInteractionEnabled = true
            hateSpeechButton.layer.cornerRadius = 12
            self.hateSpeechLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.hateSpeechButton!.frame.width - 15 - 30, height: self.hateSpeechButton!.frame.height))
            if let hateSpeechLabel = self.hateSpeechLabel {
                hateSpeechLabel.center.y = self.hateSpeechButton!.frame.height / 2
                hateSpeechLabel.text = "Hate speech or harassment"
                hateSpeechLabel.isUserInteractionEnabled = false
                hateSpeechLabel.textColor = Constants.textColor.hexToUiColor()
                hateSpeechLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.hateSpeechButton?.addSubview(hateSpeechLabel)
            }
            self.hateSpeechArrow = UIImageView(frame: CGRect(x: hateSpeechButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let hateSpeechArrow = self.hateSpeechArrow {
                hateSpeechArrow.frame = CGRect(x: hateSpeechButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                hateSpeechArrow.image = UIImage(systemName: "chevron.right")
                hateSpeechArrow.contentMode = .scaleAspectFit
                hateSpeechArrow.tintColor = Constants.textColor.hexToUiColor()
                self.hateSpeechButton?.addSubview(hateSpeechArrow)
            }
            self.view.addSubview(hateSpeechButton)
        }
        
        self.OtherButton = UIButton(frame: CGRect(x: 15, y: self.hateSpeechButton!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 50))
        if let OtherButton = self.OtherButton {
            OtherButton.addReportShadow()
            OtherButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)
            OtherButton.backgroundColor = Constants.surfaceColor.hexToUiColor()
            OtherButton.isUserInteractionEnabled = true
            OtherButton.layer.cornerRadius = 12
            self.OtherLabel = UILabel(frame: CGRect(x: 15, y: 0, width: self.OtherButton!.frame.width - 15 - 30, height: self.OtherButton!.frame.height))
            if let OtherLabel = self.OtherLabel {
                OtherLabel.center.y = self.OtherButton!.frame.height / 2
                OtherLabel.text = "Other"
                OtherLabel.isUserInteractionEnabled = false
                OtherLabel.textColor = Constants.textColor.hexToUiColor()
                OtherLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.OtherButton?.addSubview(OtherLabel)
            }
            self.OtherArrow = UIImageView(frame: CGRect(x: OtherButton.frame.width - 32 - 10, y: 0, width: 32, height: 32))
            if let OtherArrow = self.OtherArrow {
                OtherArrow.frame = CGRect(x: OtherButton.frame.width - 15 - 15, y: 35/2, width: 15, height: 15)
                OtherArrow.image = UIImage(systemName: "chevron.right")
                OtherArrow.contentMode = .scaleAspectFit
                OtherArrow.tintColor = Constants.textColor.hexToUiColor()
                self.OtherButton?.addSubview(OtherArrow)
            }
            self.view.addSubview(OtherButton)
        }
        self.reportTextView = UITextView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let reportTextView = self.reportTextView {
            
            reportTextView.textColor = Constants.textColor.hexToUiColor()
            reportTextView.delegate = self
            reportTextView.backgroundColor = Constants.surfaceColor.hexToUiColor()
            reportTextView.alpha = 0
            reportTextView.frame = CGRect(x: 15, y: (whatIsWrongLabel?.frame.maxY)! + 10, width: UIScreen.main.bounds.width - 30, height: 300)
            reportTextView.text = "Enter a description explaining your reason for reporting this post"
            reportTextView.layer.cornerRadius = 12
            reportTextView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
            reportTextView.textColor = UIColor.lightGray
            reportTextView.font = UIFont(name: Constants.globalFont, size: 14)
            reportTextView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
            reportTextView.layer.shadowOffset = CGSize(width: 0, height: 4)
            reportTextView.layer.shadowRadius = 12
            reportTextView.layer.cornerRadius = 12
            reportTextView.layer.shadowOpacity = 0.1
            self.view.addSubview(reportTextView)
        }
        self.submitButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let submitButton = self.submitButton {
            submitButton.layer.cornerRadius = 4
            submitButton.layer.shadowColor = Constants.primaryColor.hexToUiColor().withAlphaComponent(0.3).cgColor
            submitButton.layer.shadowOffset = CGSize(width: 4, height: 10)
            submitButton.layer.shadowOpacity = 0.5
            submitButton.layer.shadowRadius = 4
            submitButton.titleLabel!.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
            submitButton.setTitle("Submit", for: .normal)
            submitButton.alpha = 0
            submitButton.titleLabel?.textColor = .white
            submitButton.backgroundColor = Constants.primaryColor.hexToUiColor()
            submitButton.addTarget(self, action: #selector(handleSubmitButton(_:)), for: .touchUpInside)
            self.view.addSubview(submitButton)
        }
    self.hideKeyboardWhenTappedAround()
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
    @objc internal func handleSubmitButton(_ button: UIButton) {
        reportDescription = (reportTextView?.text.replacingOccurrences(of: "Please provide more info here", with: ""))!
        let userID = Auth.auth().currentUser?.uid
        print("* submit button pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if self.isPostReport == false {
            print("* submitting to reports/\(userID!)/profile-reports/\(postID)")
            let repReference = db.collection("reports").document(userID!).collection("profile-reports").document(postID)
            repReference.setData(["reason":reportType, "description": reportDescription, "reportId": repReference.documentID, "actualpostAuthorID": postAuthorID])   { err in
                if let err = err {
                    print("Error writing document: \(err)")
                    SPAlert.present(title: "Unknown error occured", preset: .error, haptic: .error)
                } else {
                    SPAlert.present(title: "Successfully Submitted!", preset: .done, haptic: .success)
                    self.dismiss(animated: true)
                }
            }
        } else {
            print("* submitting to reports/\(userID!)/post-reports/\(postID)")
            let repReference = db.collection("reports").document(userID!).collection("post-reports").document(postID)
            repReference.setData(["reason":reportType, "description": reportDescription, "reportId": repReference.documentID, "actualpostAuthorID": postAuthorID, "postId": postID])   { err in
                if let err = err {
                    print("Error writing document: \(err)")
                    SPAlert.present(title: "Unknown error occured", preset: .error, haptic: .error)
                } else {
                    SPAlert.present(title: "Successfully Submitted!", preset: .done, haptic: .success)
                    self.dismiss(animated: true)
                }
            }
        }
    }
    @objc internal func reportButtonTapped(_ button: UIButton) {
        print("* report button pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        hideAllBaseElements()
        if let label = button.subviews.first as? UILabel {
            reportType = label.text ?? ""
            print("* adding more stuff for \(reportType) report")
            let seconds = 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                // Put your code which should be executed with a delay here
                self.reportIssueLabel?.text = "Provide more info"
                if self.isPostReport == false {
                    self.whatIsWrongLabel?.text = "Please provide the reasons that you believe this profile contains \"\(self.reportType)\" in multiple posts."
                } else {
                    self.whatIsWrongLabel?.text = "Please provide the reasons that you believe this post contains \"\(self.reportType)\"."
                }
                
                self.whatIsWrongLabel?.frame = CGRect(x: 15, y: self.reportIssueLabel!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 30)
                self.reportTextView?.frame = CGRect(x: 15, y: (self.whatIsWrongLabel?.frame.maxY)! + 10, width: UIScreen.main.bounds.width - 30, height: 340)
                self.submitButton?.frame = CGRect(x: 40, y: (self.reportTextView?.frame.maxY)! + 20, width: UIScreen.main.bounds.width - 80, height: 53)
                self.reportIssueLabel?.fadeIn()
                self.whatIsWrongLabel?.fadeIn()
                self.reportTextView?.text = "Please provide more info here"
                self.reportTextView?.fadeIn()
                self.submitButton?.fadeIn()
            }
            
        }
    }
    func hideAllBaseElements() {
        reportIssueLabel?.fadeOut()
        whatIsWrongLabel?.fadeOut()
        itsSpamButton?.fadeOut()
        adultContentButton?.fadeOut()
        illegalContentButton?.fadeOut()
        illegalServicesButton?.fadeOut()
        hateSpeechButton?.fadeOut()
        OtherButton?.fadeOut()
    }
}
extension UIButton {
    func addReportShadow() {
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.cornerRadius = 12
        self.layer.shadowOpacity = 0.1
    }
}
extension ReportPostsController: PanModalPresentable {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var panScrollable: UIScrollView? {
        return nil
    }

    var longFormHeight: PanModalHeight {
        let actualHeight = 650
        
        return .maxHeightWithTopInset(UIScreen.main.bounds.height-CGFloat(actualHeight))
    }

    var anchorModalToLongForm: Bool {
        return false
    }
}
