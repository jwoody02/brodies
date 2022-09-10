//
//  NewCollectionPopup.swift
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
import FirebaseAnalytics

class NewCollectionVC: UIViewController, UITextFieldDelegate {
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    private var db = Firestore.firestore()
    var parentVC: UIViewController?
    
    internal var newCollectionLabel: UILabel?
    internal var characterCountLabel: UILabel?
    
    internal var newLabel: UILabel?
    internal var collectionNameTextField: UITextField?
    
    internal var createCollection: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = backgroundColor
        setupUI()
        
    }
    func setupUI() {
        self.newCollectionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let newCollectionLabel = self.newCollectionLabel {
            newCollectionLabel.text = "New Collection"
            newCollectionLabel.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 25)
            newCollectionLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
            newCollectionLabel.textColor = .darkGray
            newCollectionLabel.textAlignment = .center
            self.view.addSubview(newCollectionLabel)
        }
        
        self.newLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let newLabel = self.newLabel {
            newLabel.text = "Name"
            newLabel.frame = CGRect(x: 15, y: newCollectionLabel!.frame.maxY + 20, width: UIScreen.main.bounds.width - 70, height: 25)
            newLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
            newLabel.textColor = .darkGray
            newLabel.textAlignment = .left
            self.view.addSubview(newLabel)
        }
        self.characterCountLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let characterCountLabel = self.characterCountLabel {
            characterCountLabel.text = "0/30"
            characterCountLabel.frame = CGRect(x: 15, y: newCollectionLabel!.frame.maxY + 20, width: UIScreen.main.bounds.width - 70, height: 25)
            characterCountLabel.frame = CGRect(x: UIScreen.main.bounds.width - 15 - characterCountLabel.frame.width, y: characterCountLabel.frame.minY, width: characterCountLabel.frame.width, height: characterCountLabel.frame.height)
            characterCountLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
            characterCountLabel.center.y = newLabel!.center.y
            characterCountLabel.textColor = .lightGray
            characterCountLabel.textAlignment = .right
            self.view.addSubview(characterCountLabel)
        }
        self.collectionNameTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let collectionNameTextField = self.collectionNameTextField {
            collectionNameTextField.placeholder = "Enter collection name"
            collectionNameTextField.frame = CGRect(x: 15, y: newLabel!.frame.maxY + 10, width: UIScreen.main.bounds.width - 30, height: 25)
            collectionNameTextField.font = UIFont(name: "\(Constants.globalFont)", size: 14)
            collectionNameTextField.textColor = .darkGray
            collectionNameTextField.textAlignment = .left
            collectionNameTextField.addBottomBorder(withColor: UIColor.darkGray)
            collectionNameTextField.becomeFirstResponder()
            collectionNameTextField.delegate = self
            self.view.addSubview(collectionNameTextField)
        }
        self.createCollection = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let createCollection = self.createCollection {
            createCollection.setTitle("Create Collection", for: .normal)
            createCollection.addTarget(self, action: #selector(createButtonPressed(_:)), for: .touchUpInside)
            createCollection.frame = CGRect(x: 15, y: collectionNameTextField!.frame.maxY + 25, width: collectionNameTextField!.frame.width, height: 53)
            makeCreatebuttonGrey()
            createCollection.titleLabel!.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
            self.view.addSubview(createCollection)
        }
    }
    @objc internal func createButtonPressed(_ button: UIButton) {
        print("* creating collection with name: \(collectionNameTextField?.text)")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        makeCreatebuttonGrey()
        let postName = collectionNameTextField?.text as! String
        let newCollectionDictionary = ["collections.\(String(describing: postName.camelCase()))":["public_name": "\(postName)", "internal_name": "\(String(describing: postName.camelCase()))", "num_of_posts": 0, "thumbnails": []]]
        db.collection("saved").document(userID!).getDocument() { (collectioons, error) in
            var isValidName = true
            if ((collectioons?.exists) != nil && (collectioons?.exists == true)) {
                let dat = (collectioons?.data() as? [String: AnyObject])
                
                let clections = dat?["collections"] as! [String: Dictionary<String, Any>]
                
                for (_, col) in clections {
                    let c = SavedCollection(publicname: col["public_name"] as? String ?? "", internalname: col["internal_name"] as? String ?? "", numberOfPosts: col["num_of_posts"] as? Int ?? 0, previewPics: col["thumbnails"] as? [String] ?? [])
                    if c.publicname == self.collectionNameTextField!.text {
                        isValidName = false
                        Analytics.logEvent("invalid_collection_name", parameters: nil)
                    }
                }
                if isValidName {
                    Analytics.logEvent("created_new_collection", parameters: nil)
                    print("* adding collection: \(newCollectionDictionary)")
                    self.db.collection("saved").document(userID!).setData(["collections": ["\(String(describing: postName.camelCase()))":["public_name": "\(postName)", "internal_name": "\(String(describing: postName.camelCase()))", "num_of_posts": 0, "thumbnails": [], "createdAt": Date().timeIntervalSince1970]]], merge: true) {error in
                        if let parent = self.parentVC as? SavedCollectionsViewController {
                            parent.saveCollections.removeAll()
                            parent.collectionsSavedView.reloadData()
                            parent.fetchCollections()
                            self.dismiss(animated: true)
                        }
                        if let parentVC = self.parentVC as? AddToCollectionPopup {
                            print("* refreshing collection popup")
//                            parentVC.saveCollections.removeAll()
//                            parentVC.fetchCollections()
                            
                            self.dismiss(animated: true)
                            parentVC.putIntocollection(internalName: "\(String(describing: postName.camelCase()))")
                        }
                    }
                }
            } else {
                self.db.collection("saved").document(userID!).setData(["collections":["all_posts": ["public_name": "All posts", "internal_name": "all_posts", "num_of_posts": 0, "thumbnails": [], "createdAt": Date().timeIntervalSince1970], "\(String(describing: postName.camelCase()))": ["public_name": "\(postName)", "internal_name": "\(String(describing: postName.camelCase()))", "num_of_posts": 0, "thumbnails": [], "createdAt": Date().timeIntervalSince1970]]], merge: true)
                if let parent = self.parentVC as? SavedCollectionsViewController {
                    parent.saveCollections.removeAll()
                    parent.collectionsSavedView.reloadData()
                    parent.fetchCollections()
                    self.dismiss(animated: true)
                    
                }
                if let parentVC = self.parentVC as? AddToCollectionPopup {
                    print("* refreshing collection popup")
                    parentVC.saveCollections.removeAll()
                    parentVC.fetchCollections()
                    self.dismiss(animated: true)
                }
            }
            
        }
    }
    func makeCreatebuttonGrey() {
        createCollection?.backgroundColor = .lightGray.withAlphaComponent(0.4)
        createCollection?.layer.cornerRadius = 4
        createCollection?.layer.shadowColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        createCollection?.layer.shadowOffset = CGSize(width: 4, height: 10)
        createCollection?.layer.shadowOpacity = 0.5
        createCollection?.layer.shadowRadius = 4
        createCollection?.isUserInteractionEnabled = false
    }
    func makeCreateButtonClickable() {
        createCollection?.backgroundColor = Constants.primaryColor.hexToUiColor()
        createCollection?.layer.cornerRadius = 4
        createCollection?.layer.shadowColor = Constants.primaryColor.hexToUiColor().withAlphaComponent(0.3).cgColor
        createCollection?.layer.shadowOffset = CGSize(width: 4, height: 10)
        createCollection?.layer.shadowOpacity = 0.5
        createCollection?.layer.shadowRadius = 4
        createCollection?.isUserInteractionEnabled = true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                           replacementString string: String) -> Bool
    {
        let maxLength = 29
        let currentString: NSString = textField.text as! NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        characterCountLabel!.text = "\(newString.length)/30"
        if newString.length > 0 {
            makeCreateButtonClickable()
        } else {
            makeCreatebuttonGrey()
        }
        return newString.length <= maxLength
    }
}
extension UITextField {
    func addBottomBorder(withColor: UIColor){
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: self.frame.size.width, height: 1)
        bottomLine.backgroundColor = withColor.cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
}
extension NewCollectionVC: PanModalPresentable {

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
extension String {
    func camelCase() -> String {
        return self.removeEmoji().replacingOccurrences(of: " ", with: "_").lowercased()
    }
    func removeEmoji() -> String {
        return self.unicodeScalars
            .filter { !$0.properties.isEmojiPresentation }
            .reduce("") { $0 + String($1) }
    }
}
