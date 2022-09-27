//
//  AddToCollectionPopup.swift
//  Egg.
//
//  Created by Jordan Wood on 8/17/22.
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

class addToCollectionCell: UITableViewCell {
    internal var previewImage: UIImageView?
    internal var bigPlusImage: UIImageView?
    internal var collectionNameLabel: UILabel?
    internal var numOfPosts: UILabel?
    
    
    var collection: SavedCollection?
    func styleCell() {
        addElements()
        previewImage?.frame = CGRect(x: 15, y: 10, width: 60, height: 60)
        previewImage?.clipsToBounds = true
        previewImage?.contentMode = .scaleAspectFill
        previewImage?.layer.cornerRadius = 8
        previewImage?.backgroundColor = .lightGray.withAlphaComponent(0.2)
        
        collectionNameLabel?.text = collection?.publicname
        collectionNameLabel?.frame = CGRect(x: previewImage!.frame.maxX + 10, y: 20, width: self.contentView.frame.width, height: 20)
        
        numOfPosts?.text = "\(String(describing: (collection?.numberOfPosts ?? 0).delimiter)) posts"
        numOfPosts?.frame = CGRect(x: collectionNameLabel!.frame.minX, y: collectionNameLabel!.frame.maxY, width: self.contentView.frame.width, height: 16)
        
        if collection?.internalname == "{new-collection}" {
            previewImage?.contentMode = .scaleAspectFit
            bigPlusImage?.image = UIImage(systemName: "plus")?.applyingSymbolConfiguration(.init(pointSize: 12, weight: .regular, scale: .small))?.image(withTintColor: .lightGray.withAlphaComponent(0.6))
            bigPlusImage?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            bigPlusImage?.center.x = (previewImage?.center.x)!
            bigPlusImage?.center.y = (previewImage?.center.y)!
            self.contentView.bringSubviewToFront(bigPlusImage!)
            previewImage?.isHidden = false
            previewImage?.image = nil
            numOfPosts?.isHidden = true
            collectionNameLabel?.center.y = (previewImage?.center.y)!
        }
    }
    func addElements() {
        self.previewImage?.removeFromSuperview()
        self.previewImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let previewImage = self.previewImage {
            self.contentView.addSubview(previewImage)
        }
        self.collectionNameLabel?.removeFromSuperview()
        self.collectionNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let collectionNameLabel = self.collectionNameLabel {
            collectionNameLabel.font = UIFont(name: Constants.globalFontMedium, size: 14)
            collectionNameLabel.textColor = .darkGray
            self.contentView.addSubview(collectionNameLabel)
        }
        self.numOfPosts?.removeFromSuperview()
        self.numOfPosts = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let numOfPosts = self.numOfPosts {
            self.contentView.addSubview(numOfPosts)
            numOfPosts.font = UIFont(name: "\(Constants.globalFont)", size: 13)
            numOfPosts.textColor = .lightGray
        }
        self.bigPlusImage?.removeFromSuperview()
        if collection?.internalname == "{new-collection}" {
            self.bigPlusImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let bigPlusImage = self.bigPlusImage {
                self.contentView.addSubview(bigPlusImage)
            }
        }
    }
    func setPreview(`with` urlString : String){
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)

        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.previewImage?.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
class AddToCollectionPopup: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return saveCollections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addToCollectionCell") as! addToCollectionCell
        cell.collection = saveCollections[indexPath.row]
        cell.styleCell()
        print("* making cell \(saveCollections[indexPath.row])")
        if saveCollections[indexPath.row].previewPics.count != 0 {
            cell.setPreview(with: saveCollections[indexPath.row].previewPics.reversed()[0])
        }
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let collection = saveCollections[indexPath.row]
        if collection.internalname == "{new-collection}" {
            print("* presenting newcolelction vc")
            let vc = NewCollectionVC()
            vc.parentVC = self
            Analytics.logEvent("made_new_saved_collection", parameters: nil)
            self.presentPanModal(vc)
        } else {
            let collection = saveCollections[indexPath.row]
            let userID : String = (Auth.auth().currentUser?.uid)!
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            print("* saving to collection: \(collection)")
            db.collection("saved").document(userID).collection(collection.internalname).document(actualPost.postID).setData(["postID": actualPost.postID, "authorID": actualPost.userID, "timestamp": Date().timeIntervalSince1970])
            Analytics.logEvent("saved_post_to_collection", parameters: nil)
            self.dismiss(animated: true)
        }
        
    }
    func putIntocollection(internalName: String) {
        let userID : String = (Auth.auth().currentUser?.uid)!
        db.collection("saved").document(userID).collection(internalName).document(actualPost.postID).setData(["postID": actualPost.postID, "authorID": actualPost.userID, "timestamp": Date().timeIntervalSince1970])
        self.dismiss(animated: true)
    }
    let backgroundColor = Constants.backgroundColor.hexToUiColor()
    let buttonBackgrounds = Constants.surfaceColor.hexToUiColor()
    var interButtonPadding = 15
    var bigThreeButtonWidths = 0
    var cornerRadii = 8
    private var db = Firestore.firestore()
    var actualPost = imagePost()
    var parentVC: UIViewController?
    var saveCollections: [SavedCollection] = []
    
    internal var newCollectionLabel: UILabel?
    internal var closeButton: UIButton?
    internal var collectionsTableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = backgroundColor
        
        setupUI()
        fetchCollections()
        collectionsTableView?.rowHeight = 80
    }
    func setupUI() {
        
        self.newCollectionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let newCollectionLabel = self.newCollectionLabel {
            newCollectionLabel.text = "Add to Collection"
            newCollectionLabel.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 25)
            newCollectionLabel.font = UIFont(name: Constants.globalFontBold, size: 13)
            newCollectionLabel.textColor = .darkGray
            newCollectionLabel.textAlignment = .center
            self.view.addSubview(newCollectionLabel)
        }
        
        self.collectionsTableView = UITableView(frame: CGRect(x: 0, y: newCollectionLabel!.frame.maxY + 20, width: UIScreen.main.bounds.width, height: 700 - (newCollectionLabel!.frame.maxY + 20)))
        if let collectionsTableView = self.collectionsTableView {
            collectionsTableView.register(addToCollectionCell.self, forCellReuseIdentifier: "addToCollectionCell")
            collectionsTableView.backgroundColor = .clear
            collectionsTableView.alwaysBounceVertical = false
            collectionsTableView.delegate = self
            collectionsTableView.dataSource = self
            collectionsTableView.separatorStyle = .none
            self.view.addSubview(collectionsTableView)
        }
        let clsoeWidth = 30
        let closeXY = 15
        self.closeButton = UIButton(frame: CGRect(x: Int(UIScreen.main.bounds.width) - closeXY - clsoeWidth, y: closeXY, width: clsoeWidth, height: clsoeWidth))
        if let closeButton = self.closeButton {
            closeButton.layer.cornerRadius = CGFloat(clsoeWidth / 2)
            let closeImage = UIImage(systemName: "xmark")?.applyingSymbolConfiguration(.init(pointSize: 11, weight: .regular, scale: .small))?.image(withTintColor: "#828282".hexToUiColor())
            closeButton.setImage(closeImage, for: .normal)
            closeButton.backgroundColor = "#dcdcdc".hexToUiColor().withAlphaComponent(0.6)
            closeButton.clipsToBounds = true
            closeButton.setTitle("", for: .normal)
            closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
            self.view.addSubview(closeButton)
        }
    }
    @objc internal func closeButtonPressed(_ button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        self.dismiss(animated: true)
    }
    func fetchCollections() {
        Analytics.logEvent("save_to_collection_list_loaded", parameters: nil)
        let userID = Auth.auth().currentUser?.uid
        db.collection("saved").document(userID!).getDocument() { (collectioons, error) in
            let newCollection = SavedCollection(publicname: "New Collection", internalname: "{new-collection}", numberOfPosts: 0, previewPics: [], createdAt: -1)
            self.saveCollections.append(newCollection)
            if ((collectioons?.exists) != nil && (collectioons?.exists == true)) {
                let dat = (collectioons?.data() as? [String: AnyObject])
                
                let clections = dat?["collections"] as! [String: Dictionary<String, Any>]
                print("* got dat: \(clections)")
                
                for (keyz, col) in clections {
                    if col["public_name"] as? String ?? "" != "All posts" {
                        var c = SavedCollection(publicname: col["public_name"] as? String ?? "", internalname: col["internal_name"] as? String ?? "", numberOfPosts: col["num_of_posts"] as? Int ?? 0, previewPics: col["thumbnails"] as? [String] ?? [], createdAt: Int(col["createdAt"] as? Double ?? 0))
                        c.previewPics = c.previewPics.reversed()
                        self.saveCollections.append(c)
                    }
                    
                }
            } else {
                self.db.collection("saved").document(userID!).setData(["collections":["all_posts": ["public_name": "All posts", "internal_name": "all_posts", "num_of_posts": 0, "thumbnails": []]]], merge: true)
            }

            print("* reloading with \(self.saveCollections)")
            self.saveCollections = self.saveCollections.sorted(by: {(obj1, obj2) -> Bool in
                return obj1.createdAt < obj2.createdAt
            })
            self.collectionsTableView?.reloadData()
//            self.collectionsTableView?.fadeIn()
        }
        
    }
}

extension AddToCollectionPopup: PanModalPresentable {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var panScrollable: UIScrollView? {
        return nil
    }

    var longFormHeight: PanModalHeight {
        let actualHeight = 700
        
        return .maxHeightWithTopInset(UIScreen.main.bounds.height-CGFloat(actualHeight))
    }

    var anchorModalToLongForm: Bool {
        return false
    }
}
