//
//  SavedCollectionsViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 8/16/22.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseAuth
import Kingfisher

struct SavedCollection {
    var publicname = ""
    var internalname = ""
    var numberOfPosts = 0
    var previewPics: [String] = []
    var createdAt = 0
}
class savedCollectionCell: UICollectionViewCell {
    @IBOutlet weak var previewImagesHolder: UIView!
    
    @IBOutlet weak var previewImage1: UIImageView!
    @IBOutlet weak var previewImage2: UIImageView!
    @IBOutlet weak var previewImage3: UIImageView!
    
    @IBOutlet weak var collectionNameLabel: UILabel!
    @IBOutlet weak var bigPlusButton: UIImageView!
    
    @IBOutlet weak var numberOfPostsLabel: UILabel!
    
    var collection: SavedCollection?
    
    func styleCell() {
        previewImagesHolder.layer.cornerRadius = 12
        previewImagesHolder.backgroundColor = .white
        let prevImX = 15
        let previewViewWidthHeight = Int(self.contentView.frame.width) - (prevImX * 2)
        previewImagesHolder.frame = CGRect(x: prevImX, y: prevImX, width: previewViewWidthHeight, height: previewViewWidthHeight)
        previewImagesHolder.clipsToBounds = true
        
        collectionNameLabel.text = collection?.publicname
        collectionNameLabel.font = UIFont(name: Constants.globalFontMedium, size: 14)
        collectionNameLabel.numberOfLines = 1
        collectionNameLabel.textColor = UIColor.darkGray
        collectionNameLabel.frame = CGRect(x: prevImX + 5, y: Int(previewImagesHolder.frame.maxY) + 10, width: previewViewWidthHeight, height: 20)
        if collection?.internalname == "{new-collection}" {
            self.bigPlusButton.tintColor = Constants.primaryColor.hexToUiColor()
            self.bigPlusButton.backgroundColor = .clear
            self.bigPlusButton.layer.cornerRadius = 12
            self.bigPlusButton.clipsToBounds = true
            bigPlusButton.isHidden = false
            let profWidth = 35
            self.bigPlusButton.frame = CGRect(x: 0, y: 0, width: CGFloat(profWidth), height: CGFloat(profWidth))
            self.bigPlusButton.center.x = previewImagesHolder.center.x
            self.bigPlusButton.center.y = previewImagesHolder.center.y
            self.bigPlusButton.image = UIImage(systemName: "plus")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .medium, scale: .small))
            self.bigPlusButton.contentMode = .scaleAspectFit
            
            var yourViewBorder = CAShapeLayer()
            yourViewBorder.strokeColor = Constants.primaryColor.hexToUiColor().cgColor
            yourViewBorder.lineDashPattern = [8, 6]
            yourViewBorder.frame = self.bounds
            yourViewBorder.fillColor = nil
            yourViewBorder.path = UIBezierPath(roundedRect: self.previewImagesHolder.bounds, cornerRadius: self.previewImagesHolder.layer.cornerRadius).cgPath
            self.previewImagesHolder.layer.addSublayer(yourViewBorder)
            collectionNameLabel.textColor = Constants.primaryColor.hexToUiColor()
            numberOfPostsLabel.isHidden = true
        } else {
            bigPlusButton.isHidden = true
            
            numberOfPostsLabel.isHidden = false
            numberOfPostsLabel.textColor = .white
//            numberOfPostsLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
            numberOfPostsLabel.font = UIFont(name: Constants.globalFontMedium, size: 14)
            numberOfPostsLabel.text = "\((collection?.numberOfPosts ?? 0).roundedWithAbbreviations)"
            numberOfPostsLabel.sizeToFit()
            let newPostWidth = numberOfPostsLabel.frame.width + 15
            numberOfPostsLabel.frame = CGRect(x: previewImagesHolder.frame.width - newPostWidth - 5, y: 5, width: newPostWidth, height: 22)
//            let blurEffect = UIBlurEffect(style: .dark)
//            let blurredEffectView = UIVisualEffectView(effect: blurEffect)
//            blurredEffectView.frame = numberOfPostsLabel.bounds
            numberOfPostsLabel.layer.cornerRadius = 10
            numberOfPostsLabel.clipsToBounds = true
//            numberOfPostsLabel.addSubview(blurredEffectView)
//            numberOfPostsLabel.sendSubviewToBack(blurredEffectView)
            numberOfPostsLabel.backgroundColor = .black.withAlphaComponent(0.7)
            
            applyShadow()
            handleThumbnails()
        }
    }
    func applyShadow() {
        previewImagesHolder.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        previewImagesHolder.layer.shadowOffset = CGSize(width: 0, height: 4)
        previewImagesHolder.layer.shadowRadius = 12
        previewImagesHolder.layer.cornerRadius = 12
        previewImagesHolder.layer.shadowOpacity = 0.1
    }
    func handleThumbnails() {
        previewImage1.contentMode = .scaleAspectFill
        previewImage2.contentMode = .scaleAspectFill
        previewImage3.contentMode = .scaleAspectFill
        
        let padding = 1
        if collection?.previewPics.count == 1 {
            previewImage1.frame = CGRect(x: 0, y: 0, width: previewImagesHolder.frame.width, height: previewImagesHolder.frame.height)
            setPreview1(with: (collection?.previewPics[0])!)
            previewImage1.isHidden = false
        } else if collection?.previewPics.count == 2 {
            previewImage1.frame = CGRect(x: 0, y: 0, width: (previewImagesHolder.frame.width / 2) - CGFloat(padding), height: previewImagesHolder.frame.height)
            setPreview1(with: (collection?.previewPics[0])!)
            previewImage2.frame = CGRect(x: previewImage1.frame.maxX + CGFloat(padding), y: 0, width: (previewImagesHolder.frame.width / 2), height: previewImagesHolder.frame.height)
            setPreview2(with: (collection?.previewPics[1])!)
        } else if collection?.previewPics.count != 0 {
            previewImage1.frame = CGRect(x: 0, y: 0, width: (previewImagesHolder.frame.width / 2) - CGFloat(padding), height: previewImagesHolder.frame.height)
            setPreview1(with: (collection?.previewPics[0])!)
            previewImage2.frame = CGRect(x: previewImage1.frame.maxX + CGFloat(padding), y: 0, width: (previewImagesHolder.frame.width / 2), height: CGFloat((Int(previewImagesHolder.frame.height) / 2)))
            setPreview2(with: (collection?.previewPics[1])!)
            previewImage3.frame = CGRect(x: previewImage1.frame.maxX + CGFloat(padding), y: previewImage2.frame.maxY + CGFloat(padding), width: (previewImagesHolder.frame.width / 2), height: (previewImagesHolder.frame.height / 2))
            setPreview3(with: (collection?.previewPics[2])!)
        }
    }
    func setPreview1(`with` urlString : String){
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)

        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.previewImage1.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    func setPreview2(`with` urlString : String){
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)

        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.previewImage2.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    func setPreview3(`with` urlString : String){
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)

        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.previewImage3.image = value.image
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
class SavedCollectionsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return saveCollections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "savedCollectionCell", for: indexPath) as! savedCollectionCell
        cell.collection = saveCollections[indexPath.row]
        cell.styleCell()
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let paddingBetween = 10 //ACCOUNT FOR ALL SPACING (Constants.imagePadding * 3)
        let w = (Int(UIScreen.main.bounds.width) - paddingBetween) / 2
        return CGSize(width: w, height: w + 20)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        if saveCollections[indexPath.row].internalname == "{new-collection}" {
            let vc = NewCollectionVC()
            vc.parentVC = self
            self.navigationController?.presentPanModal(vc)
        } else {
            if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "savedPostsVC") as? SavedPostsViewController {
                print("* opening posts collection list")
                vc.collection = saveCollections[indexPath.row]
                self.navigationController?.pushViewController(vc, animated: true)
               
            }
        }
        
    }
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var collectionsSavedView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    private var db = Firestore.firestore()
    var saveCollections: [SavedCollection] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.backgroundColor.hexToUiColor()
        collectionsSavedView.dataSource = self
        collectionsSavedView.delegate = self
        collectionsSavedView.backgroundColor = .clear
        styleUI()
        collectionsSavedView.alpha = 0
        fetchCollections()
    }
    func fetchCollections() {
        Analytics.logEvent("loaded_saved_collections", parameters: nil)
        let userID = Auth.auth().currentUser?.uid
        db.collection("saved").document(userID!).getDocument() { (collectioons, error) in
            if ((collectioons?.exists) != nil && (collectioons?.exists == true)) {
                let dat = (collectioons?.data() as? [String: AnyObject])
                
                let clections = dat?["collections"] as! [String: Dictionary<String, Any>]
                print("* got dat: \(clections)")
                
                for (keyz, col) in clections {
                    var c = SavedCollection(publicname: col["public_name"] as? String ?? "", internalname: col["internal_name"] as? String ?? "", numberOfPosts: col["num_of_posts"] as? Int ?? 0, previewPics: col["thumbnails"] as? [String] ?? [], createdAt: Int(col["createdAt"] as? Double ?? 0))
                    c.previewPics = c.previewPics.reversed()
                    self.saveCollections.append(c)
                }
            } else {
                self.db.collection("saved").document(userID!).setData(["collections":["all_posts": ["public_name": "All posts", "internal_name": "all_posts", "num_of_posts": 0, "thumbnails": [], "createdAt": Date().timeIntervalSince1970]]], merge: true)
            }
            let newCollection = SavedCollection(publicname: "New Collection", internalname: "{new-collection}", numberOfPosts: 0, previewPics: [], createdAt: 99999999999999)
            self.saveCollections.append(newCollection)
            self.saveCollections = self.saveCollections.sorted(by: {(obj1, obj2) -> Bool in
                return obj1.createdAt < obj2.createdAt
            })
            self.collectionsSavedView.reloadData()
            self.collectionsSavedView.fadeIn()
        }
        
    }
    func styleUI() {
        topWhiteView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 90)
//        topLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
        topLabel.font = UIFont(name: Constants.globalFontBold, size: 16)
        topLabel.text = "Favorites"
        topLabel.sizeToFit()
        
        topLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (topLabel.frame.width / 2), y: 50, width: topLabel.frame.width, height: topLabel.frame.height)
        self.topWhiteView.layer.masksToBounds = false
        self.topWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.topWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.topWhiteView.layer.shadowOpacity = 0.3
        self.topWhiteView.layer.shadowRadius = Constants.borderRadius
        backButton.frame = CGRect(x: 0, y: 30, width: 50, height: 60)
        backButton.tintColor = .darkGray
        backButton.setTitle("", for: .normal)
        
        let savedY = topWhiteView.frame.maxY
        collectionsSavedView.frame = CGRect(x: 0, y: savedY, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - savedY)
        collectionsSavedView.showsVerticalScrollIndicator = false
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
    @IBAction func goBackPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
//        navigationController?.delegate = self
        _ = navigationController?.popViewController(animated: true)
    }
    
}
