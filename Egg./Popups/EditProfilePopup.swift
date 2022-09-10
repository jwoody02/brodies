//
//  EditProfilePopup.swift
//  Egg.
//
//  Created by Jordan Wood on 8/18/22.
//

import Foundation
import UIKit
import PanModal
import Presentr
import FirebaseFirestore
import FirebaseAuth
import SPAlert
import FirebaseAnalytics
import Kingfisher
import MaterialComponents
import SPAlert
import FirebaseStorage

class EditProfileVC: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var bottomWhiteView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var profileHolder: UIView!
    @IBOutlet weak var changeProfileImageButton: UIButton!
    @IBOutlet weak var profileImagePreview: UIImageView!
    
    @IBOutlet weak var nameField: MDCOutlinedTextField!
    @IBOutlet weak var usernameField: MDCOutlinedTextField!
    private var db = Firestore.firestore()
    internal var bioField: MDCOutlinedTextArea?
    
    internal var privateAccountButton: UIButton?
    internal var privateAccountLabel: UILabel?
    internal var privateAccountCheckbox: AIFlatSwitch?
    
    var originalUser = User(uid: "", username: "", profileImageUrl: "", bio: "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: "", hasValidStory: false, isFollowing: false)
    var isPrivate = false
    var wasPrivate = false
    let imagePicker = UIImagePickerController()
    
    var hasChangedProfilePic = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.backgroundColor.hexToUiColor()
        setupUI()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.sourceType = .photoLibrary
        self.hideKeyboardWhenTappedAround()
//        nameController = MDCTextInputControllerOutlined(textInput: nameField)
//        usernameController = MDCTextInputControllerOutlined(textInput: usernameField)
        updateInfo()
    }
    func makeCreatebuttonGrey() {
        saveButton.backgroundColor = .lightGray.withAlphaComponent(0.4)
        saveButton.layer.cornerRadius = 4
        saveButton.layer.shadowColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        saveButton.layer.shadowOffset = CGSize(width: 4, height: 10)
        saveButton.layer.shadowOpacity = 0.5
        saveButton.layer.shadowRadius = 4
        saveButton.isUserInteractionEnabled = false
    }
    func makeCreateButtonClickable() {
        saveButton.backgroundColor = Constants.primaryColor.hexToUiColor()
        saveButton.layer.cornerRadius = 4
        saveButton.layer.shadowColor = Constants.primaryColor.hexToUiColor().withAlphaComponent(0.3).cgColor
        saveButton.layer.shadowOffset = CGSize(width: 4, height: 10)
        saveButton.tintColor = .white
        saveButton.layer.shadowOpacity = 0.5
        saveButton.layer.shadowRadius = 4
        saveButton.isUserInteractionEnabled = true
    }
    @objc internal func handleEditTap(sender : UITapGestureRecognizer) {
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("* did finish picking image")
        if let image = info[.originalImage] as? UIImage {
            profileImagePreview.image = image
            hasChangedProfilePic = true
            makeCreateButtonClickable()
            self.imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    func updateInfo() {
        let userID = Auth.auth().currentUser?.uid
        db.collection("user-locations").document(userID!).getDocument() { [self] (document, error) in
            if let document = document {
                let data = document.data()! as [String: AnyObject]
                nameField.text = data["full_name"] as? String ?? ""
                usernameField.text = data["username"] as? String ?? ""
                bioField?.textView.text = data["bio"] as? String ?? ""
//                bioField?.
                isPrivate = data["isPrivate"] as? Bool ?? false
                wasPrivate = data["isPrivate"] as? Bool ?? false
                privateAccountCheckbox?.setSelected(isPrivate, animated: true)
                let imageURL = data["profileImageURL"] as? String ?? ""
                originalUser = User(uid: userID!, username: data["username"] as? String ?? "", profileImageUrl: imageURL, bio: data["bio"] as? String ?? "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: data["full_name"] as? String ?? "", hasValidStory: false, isFollowing: false)
                if imageURL == "" {
                    profileImagePreview.image = UIImage(named: "no-profile-img.jpeg")
                    print("* no profile pic, defaulting iamge")
//                    profilePicImage.fadeIn()
                } else {
                    self.setUserImage(with: imageURL)
                }
            }
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        let seconds = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            if self.hasAnyInfoChanged() {
                self.makeCreateButtonClickable()
            } else {
                self.makeCreatebuttonGrey()
            }
        }
        if textView == bioField?.textView {
            return numberOfChars < 150
        }
        
        return numberOfChars < 30    // 10 Limit Value
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                           replacementString string: String) -> Bool
    {
        
        let maxLength = 29
        let currentString: NSString = textField.text as! NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        let newCharacterCount = newString.length
        let seconds = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            if self.hasAnyInfoChanged() {
                self.makeCreateButtonClickable()
            } else {
                self.makeCreatebuttonGrey()
            }
        }
        if textField == nameField {
            return newString.length <= 29
        } else if textField == usernameField {
            return newString.length <= 29
        }
        
        return newString.length <= maxLength
    }
    func hasAnyInfoChanged() -> Bool {
        if nameField.text ?? "" != originalUser.fullname {
            return true
        }
        if usernameField.text ?? "" != originalUser.username {
            return true
        }
        if bioField?.textView.text ?? "" != originalUser.bio {
            return true
        }
        if wasPrivate != isPrivate {
            return true
        }
        if hasChangedProfilePic == true {
            return true
        }
        return false
    }
    func setUserImage(`with` urlString : String) {
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        
        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.profileImagePreview.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    func setupUI() {
        
        topWhiteView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 90)
        self.topWhiteView.layer.masksToBounds = false
        self.topWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.topWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.topWhiteView.layer.shadowOpacity = 0.3
        self.topWhiteView.layer.shadowRadius = Constants.borderRadius
        
        
        bottomWhiteView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        bottomWhiteView.layer.cornerRadius = Constants.borderRadius
        bottomWhiteView.clipsToBounds = true
        bottomWhiteView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 120, width: UIScreen.main.bounds.width, height: 120)
        self.bottomWhiteView.layer.masksToBounds = false
        self.bottomWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.bottomWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.bottomWhiteView.layer.shadowOpacity = 0.3
        self.bottomWhiteView.layer.shadowRadius = Constants.borderRadius
        
        
        topLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        topLabel.text = "Edit Profile"
        topLabel.sizeToFit()
        topLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (topLabel.frame.width / 2), y: 50, width: topLabel.frame.width, height: topLabel.frame.height)
        backButton.frame = CGRect(x: 0, y: 30, width: 50, height: 60)
        backButton.tintColor = .darkGray
        backButton.setTitle("", for: .normal)
        styleForGreySave()
        
        scrollView.frame = CGRect(x: 0, y: topWhiteView.frame.maxY, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - topWhiteView.frame.maxY)
        profileHolder.layer.cornerRadius = 12
//        let gesture = UITapGestureRecognizer(target: self, action: selector(self.handleEditTap))
//       withSender: self)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.handleEditTap))
        profileHolder.addGestureRecognizer(gesture)
//        profileHolder.addTarget(self, action: #selector(handleEditTap(_:)), for: .touchUpInside)
        profileHolder.layer.borderColor = Constants.secondaryColor.hexToUiColor().cgColor
        profileHolder.layer.borderWidth = 2
        profileHolder.frame = CGRect(x: 20, y: 20, width: 90, height: 90)
        profileHolder.clipsToBounds = true
        profileHolder.isUserInteractionEnabled = true
        profileImagePreview.frame = CGRect(x: 0, y: 0, width: profileHolder.frame.width, height: profileHolder.frame.height)
        profileImagePreview.contentMode = .scaleAspectFill
        profileImagePreview.isUserInteractionEnabled = false
//        profileImagePreview.center.x = self.view.center.x
        
        changeProfileImageButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        changeProfileImageButton.tintColor = UIColor.white
        changeProfileImageButton.setTitle("Edit", for: .normal)
        changeProfileImageButton.isUserInteractionEnabled = false
        changeProfileImageButton.layer.cornerRadius = 0
        changeProfileImageButton.frame = CGRect(x: 0, y: profileImagePreview.frame.maxY - 25, width: profileImagePreview.frame.width, height: 25)
        changeProfileImageButton.center.x = profileImagePreview.center.x
        
        let nameX = profileHolder.frame.maxX + 20
        nameField.frame = CGRect(x: nameX, y: 28, width: UIScreen.main.bounds.width - nameX - 20, height: 30)
        nameField.label.text = "Full Name"
        nameField.styleField()
        nameField.placeholder = "John Doe"
        nameField.leadingAssistiveLabel.text = "This will be publically shown on your profile"
        nameField.sizeToFit()
        nameField.frame = CGRect(x: nameX, y: 28, width: UIScreen.main.bounds.width - nameX - 20, height: nameField.frame.height)
        nameField.delegate = self
        
        let userX = 20
        usernameField.frame = CGRect(x: userX, y: Int(profileHolder.frame.maxY) + 20, width: Int(UIScreen.main.bounds.width) - userX - 20, height: 30)
        usernameField.label.text = "Username"
        usernameField.styleField()
        (usernameField!).delegate = self
        usernameField.placeholder = "brodie"
        let aticon = UIImageView(image: UIImage(systemName: "at")?.withTintColor(Constants.primaryColor.hexToUiColor()))
        aticon.tintColor = Constants.primaryColor.hexToUiColor()
        usernameField.leadingView = aticon
        usernameField.leadingViewMode = .always
        usernameField.sizeToFit()
        usernameField.frame = CGRect(x: userX, y: Int(profileHolder.frame.maxY) + 20, width: Int(UIScreen.main.bounds.width) - userX - 20, height: Int(usernameField.frame.height))
        
        self.bioField = MDCOutlinedTextArea(frame: CGRect(x: userX, y: Int(usernameField.frame.maxY) + 20, width: Int(UIScreen.main.bounds.width) - userX - 20, height: 90))
        if let bioField = self.bioField {
            bioField.label.text = "Bio"
            bioField.styleField()
            bioField.textView.delegate = self
            bioField.textView.font = usernameField.font
            bioField.placeholder = "Add a bio here"
            scrollView.addSubview(bioField)
        }
        self.privateAccountButton = UIButton(frame: CGRect(x: userX, y: Int(bioField!.frame.maxY) + 5, width: Int(UIScreen.main.bounds.width) - userX - 20, height: 40))
        if let privateAccountButton = self.privateAccountButton {
            privateAccountButton.setTitle("", for: .normal)
            privateAccountButton.backgroundColor = .clear
            privateAccountButton.alpha = 1
            privateAccountButton.addTarget(self, action: #selector(privateAccountPressed(_:)), for: .touchUpInside)
            privateAccountButton.isUserInteractionEnabled = true
            let checkboxWid = 18
            let checkboxY = (Int(privateAccountButton.frame.height) / 2) - checkboxWid / 2
            self.privateAccountCheckbox = AIFlatSwitch(frame: CGRect(x: 0, y: checkboxY, width: checkboxWid, height: checkboxWid))
            if let privateAccountCheckbox = self.privateAccountCheckbox {
                privateAccountCheckbox.isUserInteractionEnabled = false
                self.privateAccountButton?.addSubview(privateAccountCheckbox)
            }
            self.privateAccountLabel = UILabel(frame: CGRect(x: Int(privateAccountCheckbox!.frame.maxX) + 10, y: 0, width: Int(UIScreen.main.bounds.width) - userX - 60, height: 40))
            if let privateAccountLabel = self.privateAccountLabel {
                privateAccountLabel.text = "Private Account"
                privateAccountLabel.isUserInteractionEnabled = false
//                privateAccountLabel.textColor = Constants.textColor.hexToUiColor()
                privateAccountLabel.textColor = Constants.primaryColor.hexToUiColor()
                privateAccountLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
                self.privateAccountButton?.addSubview(privateAccountLabel)
            }
            self.scrollView.addSubview(privateAccountButton)
        }
        saveButton.frame = CGRect(x: 15, y: 25, width: UIScreen.main.bounds.width - 30, height: 53)
    }
    @objc internal func privateAccountPressed(_ button: UIButton) {
        print("* privateAccount pressed")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let isSelected = !(privateAccountCheckbox!.isSelected)
        privateAccountCheckbox?.setSelected(isSelected, animated: true)
        isPrivate = isSelected
        if self.hasAnyInfoChanged() {
            self.makeCreateButtonClickable()
        } else {
            self.makeCreatebuttonGrey()
        }
    }
    @IBAction func goBackPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
//        navigationController?.delegate = self
        _ = navigationController?.popViewController(animated: true)
    }
    @IBAction func SaveChangesPressed(_ sender: Any) {
        Analytics.logEvent("updated_profile", parameters: nil)
        let userID = Auth.auth().currentUser?.uid
        makeCreatebuttonGrey()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if hasChangedProfilePic {
            print("* uploading new profile pic")
            uploadProfilePic() { url in
                guard let url = url else { return }
                print("* got new profile pic url: \(url)")
                if self.usernameField.text ?? "" != self.originalUser.username && self.usernameField.text ?? "" != "" {
                    print("* username has been changed, check for availability")
                    self.db.collection("user-locations").whereField("username", isEqualTo: self.usernameField.text ?? "").limit(to: 1).getDocuments { (queryResults, error) in
                        if queryResults!.isEmpty || error != nil {
                            print("* looks like username is available!")
                            self.db.collection("user-locations").document(userID!).setData(["full_name": self.nameField.text ?? "", "bio":self.bioField?.textView.text ?? "", "isPrivate":self.privateAccountCheckbox?.isSelected ?? false, "profileImageURL": url, "username": self.usernameField.text ?? ""], merge: true) { error in
                                if let error = error {
                                    print("*error updating: \(error)")
                                    SPAlert.present(title: "Error Saving", preset: .error, haptic: .error)
                                    self.makeCreateButtonClickable()
                                } else {
                                    SPAlert.present(title: "Successfully Saved!", preset: .done, haptic: .success)
                                    print("* done updating")
                                    self.isPrivate = self.privateAccountCheckbox?.isSelected ?? false
                                    self.wasPrivate = self.privateAccountCheckbox?.isSelected ?? false
                                    self.originalUser.fullname = self.nameField.text ?? ""
                                    self.originalUser.bio = self.bioField?.textView.text ?? ""
                                }
                               
                                
                            }
                        } else {
                            print("* username is taken already")
                        }
                    }
                } else {
                    self.db.collection("user-locations").document(userID!).setData(["full_name": self.nameField.text ?? "", "bio":self.bioField?.textView.text ?? "", "isPrivate":self.privateAccountCheckbox?.isSelected ?? false, "profileImageURL": url], merge: true) { error in
                        if let error = error {
                            print("*error updating: \(error)")
                            SPAlert.present(title: "Error Saving", preset: .error, haptic: .error)
                            self.makeCreateButtonClickable()
                        } else {
                            SPAlert.present(title: "Successfully Saved!", preset: .done, haptic: .success)
                            print("* done updating")
                            self.isPrivate = self.privateAccountCheckbox?.isSelected ?? false
                            self.wasPrivate = self.privateAccountCheckbox?.isSelected ?? false
                            self.originalUser.fullname = self.nameField.text ?? ""
                            self.originalUser.bio = self.bioField?.textView.text ?? ""
                        }
                       
                        
                    }
                }
            }
        } else {
            if usernameField.text ?? "" != originalUser.username && self.usernameField.text ?? "" != "" {
                print("* username has been changed, check for availability")
                self.db.collection("user-locations").whereField("username", isEqualTo: self.usernameField.text ?? "").limit(to: 1).getDocuments { (queryResults, error) in
                    if queryResults!.isEmpty || error != nil {
                        print("* looks like username is available!")
                        self.db.collection("user-locations").document(userID!).setData(["full_name": self.nameField.text ?? "", "bio":self.bioField?.textView.text ?? "", "isPrivate":self.privateAccountCheckbox?.isSelected ?? false,"username": self.usernameField.text ?? ""], merge: true) { error in
                            if let error = error {
                                print("*error updating: \(error)")
                                SPAlert.present(title: "Error Saving", preset: .error, haptic: .error)
                                self.makeCreateButtonClickable()
                            } else {
                                SPAlert.present(title: "Successfully Saved!", preset: .done, haptic: .success)
                                print("* done updating")
                                self.isPrivate = self.privateAccountCheckbox?.isSelected ?? false
                                self.wasPrivate = self.privateAccountCheckbox?.isSelected ?? false
                                self.originalUser.fullname = self.nameField.text ?? ""
                                self.originalUser.bio = self.bioField?.textView.text ?? ""
                            }
                           
                            
                        }
                    } else {
                        print("* username is taken already")
                    }
                }
                
            } else {
                db.collection("user-locations").document(userID!).setData(["full_name": nameField.text ?? "", "bio":bioField?.textView.text ?? "", "isPrivate":privateAccountCheckbox?.isSelected ?? false], merge: true) { error in
                    if let error = error {
                        print("*error updating: \(error)")
                        SPAlert.present(title: "Error Saving", preset: .error, haptic: .error)
                        self.makeCreateButtonClickable()
                    } else {
                        SPAlert.present(title: "Successfully Saved!", preset: .done, haptic: .success)
                        print("* done updating")
                        self.isPrivate = self.privateAccountCheckbox?.isSelected ?? false
                        self.wasPrivate = self.privateAccountCheckbox?.isSelected ?? false
                        self.originalUser.fullname = self.nameField.text ?? ""
                        self.originalUser.bio = self.bioField?.textView.text ?? ""
                    }
                   
                    
                }
            }
        }
        
    }
    func uploadProfilePic(completion: @escaping (_ url: String?) -> Void) {
        Analytics.logEvent("new_profile_pic", parameters: nil)
        let userID : String = (Auth.auth().currentUser?.uid)!
        let storageRef = Storage.storage().reference().child("profile_pics/\(userID)/")
//        guard let imageData = cameraPhotoResult!.image!.jpegData(compressionQuality: 0.75) else { return }
        print("* cropped image")
        guard let imageData = profileImagePreview.image!.nx_croppedImage(to: 1).jpegData(compressionQuality: 0.4) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        // Add a progress observer to an upload task
        
        let uploadTask = storageRef.putData(imageData, metadata: metaData) { metaData, error in
            if error == nil, metaData != nil {
                
                storageRef.downloadURL { url, error in
                    completion(url?.absoluteString)
                    // success!
                }
            } else {
                // failed
                completion(nil)
            }
        }
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        let keyboardFrame =
        (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0);
      }

      @objc func keyboardWillHide(notification: NSNotification) {
        self.scrollView.contentInset = UIEdgeInsets.zero;
      }
    func styleForGreySave() {
        saveButton.backgroundColor = .lightGray.withAlphaComponent(0.3)
        saveButton.tintColor = .darkGray.withAlphaComponent(0.6)
        saveButton.layer.cornerRadius = 12
        let savebuttonwidth = 100
        saveButton.frame = CGRect(x: Int(self.topWhiteView.frame.width) - savebuttonwidth - 10, y: Int(22.5), width: savebuttonwidth, height: 35)
        saveButton.center.y = backButton.center.y
        saveButton.isUserInteractionEnabled = false
    }
}
extension MDCOutlinedTextField {
    func styleField() {
        self.setOutlineColor(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .editing)
        self.setOutlineColor(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .normal)
        self.setNormalLabelColor(Constants.primaryColor.hexToUiColor(), for: .normal)
        self.setFloatingLabelColor(Constants.primaryColor.hexToUiColor(), for: .normal)
        self.setTextColor(Constants.primaryColor.hexToUiColor(), for: .normal)
        
        self.setNormalLabelColor(Constants.primaryColor.hexToUiColor(), for: .editing)
        self.setFloatingLabelColor(Constants.primaryColor.hexToUiColor(), for: .editing)
        self.setTextColor(Constants.primaryColor.hexToUiColor(), for: .editing)
        
        self.setLeadingAssistiveLabelColor(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .normal)
        self.setLeadingAssistiveLabelColor(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .editing)
        
    }
}

extension MDCOutlinedTextArea {
    func styleField() {
        self.setOutlineColor(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .editing)
        self.setOutlineColor(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .normal)
        self.setNormalLabel(Constants.primaryColor.hexToUiColor(), for: .normal)
        self.setFloatingLabel(Constants.primaryColor.hexToUiColor(), for: .normal)
        self.setTextColor(Constants.primaryColor.hexToUiColor(), for: .normal)
        
        self.setNormalLabel(Constants.primaryColor.hexToUiColor(), for: .editing)
        self.setFloatingLabel(Constants.primaryColor.hexToUiColor(), for: .editing)
        self.setTextColor(Constants.primaryColor.hexToUiColor(), for: .editing)
        
        self.setLeadingAssistiveLabel(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .normal)
        self.setLeadingAssistiveLabel(Constants.primaryColor.hexToUiColor().withAlphaComponent(0.5), for: .editing)
    }
}
