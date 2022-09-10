//
//  StoriesCollectionViewCell.swift
//  Egg.
//
//  Created by Jordan Wood on 7/27/22.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher
import NextLevel
class StoryCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var FlagShipImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bigPlusButton: UIImageView!
    
    
    @IBOutlet weak var addToStory: UIButton!
    @IBOutlet weak var bottomBlackView: UIView!
    @IBOutlet weak var timePostedLabel: UILabel!
    
    @IBOutlet weak var profilePicButton: IGStoryButton!
    
    func styleComponents(story: storyPost) {
        profilePicButton.setTitle("", for: .normal)
        addToStory.setTitle("", for: .normal)
        self.FlagShipImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.FlagShipImageView.layer.cornerRadius = 12
        self.FlagShipImageView.clipsToBounds = true
        self.bigPlusButton.frame = CGRect(x: 5, y: 5, width: 32, height: 32)
        self.bigPlusButton.layer.cornerRadius = 12
        
        let bottomHeight = (self.bounds.height / 8) * 3
        self.bottomBlackView.frame = CGRect(x: 0, y: Int(self.bounds.height) - Int(bottomHeight), width: Int(self.bounds.width), height: Int(bottomHeight))
        
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        self.FlagShipImageView.contentMode = .scaleAspectFill
        
        self.timePostedLabel.frame = CGRect(x: 10, y: Int(self.frame.height) - 25, width: Int(self.frame.width) - 20, height: 15)
        self.timePostedLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
//        self.timePostedLabel.textColor = .systemGray4
        self.timePostedLabel.textColor = hexStringToUIColor(hex: "#dcdcdc") // bdbdbd
        self.timePostedLabel.text = story.createdAt.storySimplifiedTimeAgo()
        self.nameLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 14)
        if story.isMyStory {
            self.nameLabel.text = "Your Story"
            profilePicButton.isHidden = true
            if story.isEmpty {
                
                self.bigPlusButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
                self.bigPlusButton.backgroundColor = .clear
                self.bigPlusButton.layer.cornerRadius = 8
                self.bigPlusButton.clipsToBounds = true
                let profWidth = self.frame.width / 4
                self.bigPlusButton.frame = CGRect(x: (self.frame.width / 2) - (profWidth / 2), y: (self.frame.width / 2.5), width: profWidth, height: profWidth)
                self.bigPlusButton.image = UIImage(systemName: "plus")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .medium, scale: .small))
                self.bigPlusButton.contentMode = .scaleAspectFit
                
                self.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
                var yourViewBorder = CAShapeLayer()
                yourViewBorder.strokeColor = hexStringToUIColor(hex: Constants.primaryColor).cgColor
                yourViewBorder.lineDashPattern = [8, 6]
                yourViewBorder.frame = self.bounds
                yourViewBorder.fillColor = nil
                yourViewBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
                self.layer.addSublayer(yourViewBorder)
                self.nameLabel.textColor = hexStringToUIColor(hex: Constants.primaryColor)
                self.nameLabel.font = UIFont(name: "\(Constants.globalFont)-Medium", size: 15)
                self.nameLabel.textAlignment = .center
                self.nameLabel.frame = CGRect(x: 0, y: bigPlusButton.frame.maxY + 40, width: self.frame.width, height: 30)
                bottomBlackView.isHidden = true
                self.timePostedLabel.isHidden = true
                
                self.FlagShipImageView.isHidden = true
            } else {
//                self.backgroundColor = .lightGray
                self.backgroundColor = .black
                setPostImage(fromUrl: story.imageUrl)
                self.nameLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
                let nameX = 10
                let nameHeight = 33
                self.nameLabel.numberOfLines = 0
                self.nameLabel.frame = CGRect(x: nameX, y: Int(self.frame.height) - nameHeight - nameX - 20, width: Int(self.frame.width) - (nameX*2), height: nameHeight)
                self.nameLabel.textAlignment = .left
                self.nameLabel.contentMode = .bottom
                self.nameLabel.preferredMaxLayoutWidth = CGFloat(Int(self.frame.width) - (nameX*2))
                self.nameLabel.sizeToFit()
                let heightz = self.nameLabel.frame.height
                self.nameLabel.frame = CGRect(x: CGFloat(nameX), y: CGFloat(Int(self.frame.height)) - heightz - 26, width: CGFloat(Int(self.frame.width) - (nameX*2)), height: heightz)
                
                let profWidth = self.frame.width / 4
                addToStory.frame = CGRect(x: self.frame.width - profWidth - 10, y: 10, width: profWidth, height: profWidth)
                addToStory.backgroundColor = hexStringToUIColor(hex: Constants.primaryColor)
                addToStory.layer.cornerRadius = 8
                addToStory.tintColor = .white
                addToStory.isHidden = false
                self.bottomBlackView.isHidden = false
               
            }
        } else {
            self.backgroundColor = .black
            setPostImage(fromUrl: story.imageUrl)
            nameLabel.text = story.author_full_name
            self.nameLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
            let nameX = 10
            let nameHeight = 33
            self.nameLabel.numberOfLines = 0
            self.nameLabel.frame = CGRect(x: nameX, y: Int(self.frame.height) - nameHeight - nameX - 20, width: Int(self.frame.width) - (nameX*2), height: nameHeight)
            self.nameLabel.textAlignment = .left
            self.nameLabel.contentMode = .bottom
            self.nameLabel.preferredMaxLayoutWidth = CGFloat(Int(self.frame.width) - (nameX*2))
            self.nameLabel.sizeToFit()
            let heightz = self.nameLabel.frame.height
            self.nameLabel.frame = CGRect(x: CGFloat(nameX), y: CGFloat(Int(self.frame.height)) - heightz - 26, width: CGFloat(Int(self.frame.width) - (nameX*2)), height: heightz)
            self.bottomBlackView.isHidden = false
            addToStory.isHidden = true
            profilePicButton.frame = CGRect(x: 10, y: 10, width: 32, height: 32)
            profilePicButton.layer.cornerRadius = 12
            print("* creating unseen profile pic")
            profilePicButton.condition = .init(display: .unseen, color: .custom(colors: [hexStringToUIColor(hex: Constants.primaryColor), .blue, hexStringToUIColor(hex: Constants.primaryColor).withAlphaComponent(0.6)]))
            if story.userImageUrl == "" {
                profilePicButton.image = UIImage(named: "no-profile-img.jpeg")
                print("* no profile pic, defaulting iamge")
                let seconds = 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    // Put your code which should be executed with a delay here
                    if self.profilePicButton.isHidden == true {
                        self.profilePicButton.fadeIn()
                    }
                    
                }
                
            } else {
                downloadProfilePicImage(with: story.userImageUrl)
            }
        }
        if Constants.isDebugEnabled {
//            var window : UIWindow = UIApplication.shared.keyWindow!
//            window.showDebugMenu()
            findViewController()?.view.debuggingStyle = true
        }
        let newBlackViewHeight = self.nameLabel.frame.height + self.timePostedLabel.frame.height + 50
        bottomBlackView.frame = CGRect(x: 0, y: self.frame.height - newBlackViewHeight, width: self.frame.width, height: newBlackViewHeight)
    }
    func downloadProfilePicImage(`with` urlString : String) {
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        print("* downloading user image via \(urlString)")
        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                print("* finished downloading user image")
                self.profilePicButton.image = value.image
                let seconds = 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    // Put your code which should be executed with a delay here
                    if self.profilePicButton.isHidden == true {
                        self.profilePicButton.fadeIn()
                    }
                }
//                self.profilePicButton.isHidden = false
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    @IBAction func addToStoryPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
        print("pushing camera view")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController
        vc?.modalPresentationStyle = .fullScreen
        NextLevel.shared.devicePosition = .back
        var parentCollectionView = self.superview?.findViewController()
        parentCollectionView?.present(vc!, animated: true)
    }
    private var db = Firestore.firestore()
    
    var actualPost = imagePost()
    
    func setPostImage(fromUrl: String) {
        let url = URL(string: fromUrl)
        let processor = DownsamplingImageProcessor(size: self.FlagShipImageView.bounds.size)
        self.FlagShipImageView.kf.indicatorType = .activity
        self.FlagShipImageView.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.3)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
                self.FlagShipImageView.contentMode = .scaleAspectFill
                self.bottomBlackView.isHidden = false
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }
    func setUserImage(fromUrl: String) {
//        let url = URL(string: fromUrl)
//        let processor = DownsamplingImageProcessor(size: self.userProfileImage.bounds.size)
//        self.userProfileImage.kf.indicatorType = .activity
//        self.userProfileImage.kf.setImage(
//            with: url,
//            options: [
//                .processor(processor),
//                .scaleFactor(UIScreen.main.scale),
//                .transition(.fade(0.5)),
//                .cacheOriginalImage,
//            ])
//        {
//            result in
//            switch result {
//            case .success(let value):
//                print("Task done for: \(value.source.url?.absoluteString ?? "")")
//            case .failure(let error):
//                print("Job failed: \(error.localizedDescription)")
//            }
//        }
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
}
