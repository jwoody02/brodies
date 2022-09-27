//
//  ImagePostCell.swift
//  Egg.
//
//  Created by Jordan Wood on 7/27/22.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import FirebaseAnalytics
import PanModal
import ImageSlideshow
import PageControls
import ActiveLabel
import ISPageControl

class ImagePostTableViewCell: UITableViewCell, ImageSlideshowDelegate, UIScrollViewDelegate {
    @IBOutlet weak var profilePicImage: IGStoryButton!
    @IBOutlet weak var firstusernameButton: UIButton!
    @IBOutlet weak var secondusernameButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var captionLabel: ActiveLabel!
    
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    
    @IBOutlet weak var viewCommentsButton: UIButton!
    @IBOutlet weak var upperRightShareButton: UIButton!
    @IBOutlet weak var mainPostImage: UIImageView!
    
    @IBOutlet weak var likeButton: HeartButton!
    @IBOutlet weak var commentBubbleButton: CommentButton!
    @IBOutlet weak var shareToUserButton: ShareUserButton!
    @IBOutlet weak var savePostButton: SaveButton!
    
    @IBOutlet weak var viewLikesView: UIView! // contained for # of likes + profile pics and usernames
    @IBOutlet weak var likesLabel: UILabel! // label that'll contain likes count and usernames if applicable
    @IBOutlet weak var profilePicView1: UIImageView! // imageview1 that'll contain profile pic
    @IBOutlet weak var profilePicView2: UIImageView! // imageview2 that'll contain profile pic
    @IBOutlet weak var profilePicView3: UIImageView! // imageview3 that'll contain profile pic
    
    @IBOutlet weak var tmpImageview: UIImageView! // just used for skeleton views
    @IBOutlet weak var tmpViewLikesButton: UIButton! // just used to listen for view likes click
    
    @IBOutlet weak var tmpRightArrow: UIButton!
    @IBOutlet weak var otherLikesbutton: UIButton!
    
    @IBOutlet weak var bigOlHeartPopup: UIImageView!
    
    @IBOutlet weak var popupSaveView: UIView!
    @IBOutlet weak var popupSaveBUtton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var TaptoAddToCollectionLabel: UILabel!
    
    // for multiple images
    @IBOutlet var slideshow: ImageSlideshow!
    @IBOutlet var pageControl: SnakePageControl!
    @IBOutlet var IGpagecontrol: ISPageControl!
    
    // number of posts tings
    @IBOutlet weak var numOfPostsView: UIView!
    @IBOutlet weak var numOfPostsBlurView: UIVisualEffectView!
    @IBOutlet weak var numOfPostsLabel: UILabel!
    
    var postid = ""
    var userID = ""
    var imageHash = ""
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    var otherLikesCount = 0
    var isCurrentlySavingData = false
    let shouldMakeRed = true
    
    var zoomEnabled = false
        var imgCenter:CGPoint?
        
    
    weak var parentViewController : FeedViewController?
    var postIndex = 0
    
    private var db = Firestore.firestore()
    
    var uidsOfLikes: [String] = []
    
    var actualPost = imagePost()
    
    func setPostImage(fromUrl: String) {
        let url = URL(string: fromUrl)
        let processor = DownsamplingImageProcessor(size: self.mainPostImage.bounds.size)
        self.mainPostImage.kf.indicatorType = .activity
        self.mainPostImage.kf.setImage(
            with: url,
            placeholder: UIImage(blurHash: imageHash, size: CGSize(width: 32, height: 32)),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.5)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
                self.mainPostImage.contentMode = .scaleAspectFill
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }
    func resetSavedPopup() {
        popupSaveView.backgroundColor = .clear
        popupSaveView.isUserInteractionEnabled = true
//        popupSaveView.setTitle("", for: .normal)
        popupSaveView.clipsToBounds = true
        popupSaveView.layer.cornerRadius = 0
        popupSaveView.alpha = 0
        let popupSaveViewX = 0
        let popupHeight = 45
        popupSaveView.frame = CGRect(x: popupSaveViewX, y: Int(mainPostImage.frame.maxY), width: Int(self.contentView.frame.width) - (popupSaveViewX * 2), height: popupHeight)
        
        blurView.frame = CGRect(x: 0, y: 0, width: popupSaveView.frame.width, height: popupSaveView.frame.height)
        popupSaveBUtton.frame = blurView.frame
        popupSaveBUtton.setTitle("", for: .normal)
        checkMarkImageView.contentMode = .scaleAspectFit
        
        let checkWid = 16
        let checkX = (Int(popupSaveView.frame.height) / 2) - checkWid / 2
        checkMarkImageView.frame = CGRect(x: checkX, y: checkX, width: checkWid, height: checkWid)
        
        TaptoAddToCollectionLabel.text = "Saved! Tap to add to a collection"
        TaptoAddToCollectionLabel.frame = CGRect(x: checkMarkImageView.frame.maxX + CGFloat(checkX), y: 0, width: popupSaveView.frame.width - (checkMarkImageView.frame.maxX + CGFloat(checkX)), height: popupSaveView.frame.height)
        popupSaveView.center.y = self.mainPostImage.frame.maxY
    }
    func popupSaved() {
        let popupSaveViewX = 0
        let popupHeight = 45
        popupSaveView.frame = CGRect(x: popupSaveViewX, y: Int(mainPostImage.frame.maxY) - popupSaveViewX - popupHeight, width: Int(self.contentView.frame.width) - (popupSaveViewX * 2), height: popupHeight)
        popupSaveView.alpha = 1
    }
    func setUserImage(fromUrl: String) {
//        let url = URL(string: fromUrl)
//        let processor = DownsamplingImageProcessor(size: self.profilePicImage.bounds.size)
//        self.profilePicImage.kf.indicatorType = .activity
//        self.profilePicImage.kf.setImage(
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
    // Inside UITableViewCell subclass

    override func layoutSubviews() {
        super.layoutSubviews()

//        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
        contentView.frame = CGRect(x: 5, y: 5, width: self.frame.width - 10, height: self.frame.height - 10)
        let tapAction = UITapGestureRecognizer(target: self, action: #selector(self.didTapLabel(_:)))
        captionLabel?.isUserInteractionEnabled = true
        captionLabel?.addGestureRecognizer(tapAction)
    }
    func styleCell(type: String, hasSubTitle: Bool) {
//        _ = driver
        contentView.frame = CGRect(x: 5, y: 10, width: self.frame.width - 10, height: self.frame.height - 20)
        UIView.performWithoutAnimation {
            profilePicImage.setTitle("", for: .normal)
            shareToUserButton.setTitle("", for: .normal)
            savePostButton.setTitle("", for: .normal)
            tmpRightArrow.setTitle("", for: .normal)
            otherLikesbutton.setTitle("", for: .normal)
            upperRightShareButton.setTitle("", for: .normal)
            tmpViewLikesButton.setTitle("", for: .normal)
        }
        resetSavedPopup()
        otherLikesbutton.isHidden = true
        profilePicView1.isHidden = true
        profilePicView2.isHidden = true
        profilePicView3.isHidden = true
//        addSeparatorLineToTop()
        if type == "imagePost" {
            self.backgroundColor = .clear
//            self.layer.cornerRadius = Constants.borderRadius
            
            // PROFILE IMAGE
            profilePicImage.layer.cornerRadius = 12
            profilePicImage.frame = CGRect(x: 8, y: 8, width: 38, height: 38)
            
            // USERNAME LABEL
            firstusernameButton.contentHorizontalAlignment = .left
            secondusernameButton.contentHorizontalAlignment = .left
            locationButton.contentHorizontalAlignment = .left
            locationButton.contentVerticalAlignment = .top
            
            let shareButtonWidth = 30
            upperRightShareButton.frame = CGRect(x: Int(self.contentView.bounds.width) - shareButtonWidth - 15, y: Int(profilePicImage.frame.minY) + 5, width: shareButtonWidth, height: shareButtonWidth)
            upperRightShareButton.contentMode = .scaleAspectFit
            let extraButtonWidths = Int(self.frame.width) - Int(profilePicImage.frame.maxY) - shareButtonWidth - 20
            if hasSubTitle == true {
                firstusernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY + 4, width: CGFloat(extraButtonWidths), height: 16)
                locationButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: firstusernameButton.frame.maxY, width: CGFloat(extraButtonWidths), height: 30)
            } else {
                firstusernameButton.frame = CGRect(x: profilePicImage.frame.maxX + 10, y: profilePicImage.frame.minY, width: CGFloat(extraButtonWidths), height: 16)
                firstusernameButton.center.y = profilePicImage.center.y
            }
            locationButton.titleLabel?.font = UIFont(name: Constants.globalFontMedium, size: 11)
            timeSincePostedLabel.frame = CGRect(x: firstusernameButton.frame.minX, y: firstusernameButton.frame.minY, width: self.contentView.bounds.width - firstusernameButton.frame.maxX, height: 16)
            timeSincePostedLabel.backgroundColor = .clear

            
            // post image
//            let mainPostWidth = UIScreen.main.bounds.width - 30
//            mainPostImage.contentMode = .scaleAspectFill
//            mainPostImage.frame = CGRect(x: 15, y: profilePicImage.frame.maxY + profilePicImage.frame.minY , width: mainPostWidth, height: mainPostWidth*1.25)
            
            let mainPostWidth = self.contentView.bounds.width
            mainPostImage.contentMode = .scaleAspectFill
            mainPostImage.frame = CGRect(x: 0, y: profilePicImage.frame.maxY + 8 , width: mainPostWidth, height: mainPostWidth*1.25)
            

//            let subButtonY = mainPostImage.frame.maxY - 40
            let subButtonY = mainPostImage.frame.maxY + 10
            let subButtonWidths = 30
            

            self.likeButton.frame = CGRect(x: 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
//            self.likeButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
//            self.likeButton.layer.shadowOffset = CGSize(width: 0, height: 3)
//            self.likeButton.layer.shadowOpacity = 0.4
//            self.likeButton.layer.shadowRadius = 4
            
            self.commentBubbleButton.frame = CGRect(x: Int(likeButton.frame.maxX) + 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            self.shareToUserButton.frame = CGRect(x: Int(commentBubbleButton.frame.maxX) + 9, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            shareToUserButton.tintColor = Constants.textColor.hexToUiColor()
            
//            self.commentBubbleButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
//            self.commentBubbleButton.layer.shadowOffset = CGSize(width: 0, height: 3)
//            self.commentBubbleButton.layer.shadowOpacity = 0.4
//            self.commentBubbleButton.layer.shadowRadius = 4
            
            self.savePostButton.frame = CGRect(x: Int(self.contentView.bounds.width) - subButtonWidths - 10, y: Int(subButtonY), width: subButtonWidths, height: subButtonWidths)
            
            
            
            
            self.mainPostImage.isUserInteractionEnabled = true
            // Single Tap
//                let singleTap: UITapGestureRecognizer =  UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
//                singleTap.numberOfTapsRequired = 1
//            self.mainPostImage.addGestureRecognizer(singleTap)
            let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
                doubleTap.numberOfTapsRequired = 2
            if actualPost.multiImageUrls.count > 1 {
                self.slideshow.addGestureRecognizer(doubleTap)
            } else {
                self.mainPostImage.addGestureRecognizer(doubleTap)
            }
            
            
//            singleTap.require(toFail: doubleTap)
//            singleTap.delaysTouchesBegan = true
            doubleTap.delaysTouchesBegan = true
            mainPostImage.layer.cornerRadius = 0
            
            self.firstusernameButton.tintColor = hexStringToUIColor(hex: Constants.textColor)
            self.secondusernameButton.tintColor = hexStringToUIColor(hex: Constants.textColor)
            
            likeButton.isHidden = false
            commentBubbleButton.isHidden = false
            upperRightShareButton.isHidden = false
            savePostButton.isHidden = false
            shareToUserButton.isHidden = false
                
            viewLikesView.frame = CGRect(x: 15, y: likeButton.frame.maxY + 10, width: 200, height: 40)
            styleForUnLikedBigView()
            viewLikesView.isHidden = false
            
            if actualPost.likesCount == 1 {
                likesLabel.text = "\(actualPost.likesCount.delimiter) like"
            } else {
                likesLabel.text = "\(actualPost.likesCount.delimiter) likes"
            }
//            likesLabel.font = UIFont(name: Constants.globalFontBold, size: 14)
            likesLabel.font = UIFont(name: Constants.globalFontMedium, size: 15)
            likesLabel.textColor = Constants.textColor.hexToUiColor()
            print("* received profile pics: \(actualPost.previewProfilePics)")
            
            likesLabel.frame = CGRect(x: 15, y: 5, width: 0, height: 0)
            likesLabel.sizeToFit()
            likesLabel.frame = CGRect(x: 15, y: 0, width: self.likesLabel.frame.width, height: viewLikesView.frame.height)
            tmpRightArrow.frame = CGRect(x: likesLabel.frame.maxX + 5, y: 1, width: 20, height: viewLikesView.frame.height)
            self.viewLikesView.frame = CGRect(x: self.viewLikesView.frame.minX, y: self.viewLikesView.frame.minY, width: self.tmpRightArrow.frame.maxX + 5, height: self.viewLikesView.frame.height)
            
            let profWidthheight = 25
            let profY = self.viewLikesView.frame.maxY + 8
            profilePicView1.frame = CGRect(x: 15, y: self.viewLikesView.frame.maxY, width: 0, height: 0)
            
            var likesString = ""
            if actualPost.previewProfilePics.count == 0 {
                
            } else if actualPost.previewProfilePics.count == 1 {
                print("* creating profile pic")
                profilePicView1.styleForMiniProfilePic()
                profilePicView1.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView2.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView3.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                handleProfileUrl(url: actualPost.previewProfilePics[0], forIndex: 0)
                
                
            } else if actualPost.previewProfilePics.count == 2 {
                profilePicView1.styleForMiniProfilePic()
                profilePicView1.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView2.styleForMiniProfilePic()
                profilePicView2.frame = CGRect(x: Int(profilePicView1.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView3.frame = CGRect(x: Int(profilePicView1.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                
                handleProfileUrl(url: actualPost.previewProfilePics[0], forIndex: 0)
                handleProfileUrl(url: actualPost.previewProfilePics[1], forIndex: 1)
                
                
            } else {
                profilePicView1.styleForMiniProfilePic()
                profilePicView1.frame = CGRect(x: 15, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView2.styleForMiniProfilePic()
                profilePicView2.frame = CGRect(x: Int(profilePicView1.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                profilePicView3.styleForMiniProfilePic()
                profilePicView3.frame = CGRect(x: Int(profilePicView2.frame.maxX) - 10, y: Int(CGFloat(profY)), width: profWidthheight, height: profWidthheight)
                
                handleProfileUrl(url: actualPost.previewProfilePics[0], forIndex: 0)
                handleProfileUrl(url: actualPost.previewProfilePics[1], forIndex: 1)
                handleProfileUrl(url: actualPost.previewProfilePics[2], forIndex: 2)
            }
            if actualPost.numOfLikeMindedLIkes > 1 {
                likesString = "liked by \(actualPost.usernameToShow) + \(actualPost.numOfLikeMindedLIkes - 1) more"
                otherLikesbutton.isHidden = false
            } else if actualPost.numOfLikeMindedLIkes != 0 {
                likesString = "liked by \(actualPost.usernameToShow)"
                otherLikesbutton.isHidden = false
            }
            print("* using string: \(likesString)")
            UIView.performWithoutAnimation {
                otherLikesbutton.setTitle(likesString, for: .normal)
            }
            if Constants.isDarkmode {
                otherLikesbutton.tintColor = .lightGray
                captionLabel.textColor = .lightGray
            }
            otherLikesbutton.frame = CGRect(x: profilePicView3.frame.maxX + 5, y: profilePicView1.frame.minY, width: self.contentView.bounds.width - profilePicView3.frame.maxX - 15 - 15, height: profilePicView3.frame.height)
            otherLikesbutton.titleLabel?.font = UIFont(name: Constants.globalFontMedium, size: 11)
            otherLikesbutton.isHidden = false
            tmpViewLikesButton.frame = CGRect(x: 0, y: 0, width: self.viewLikesView.frame.width, height: self.viewLikesView.frame.height)
            
            self.secondusernameButton.frame = CGRect(x: 15, y: profilePicView1.frame.maxY+10, width: 5, height: 5)
            self.captionLabel.numberOfLines = 0
            
            
            
//            self.secondusernameButton.backgroundColor = .blue
            let captionFont = UIFont(name: "\(Constants.globalFont)", size: 12)
            let captionString = "\(actualPost.username)   \(actualPost.caption)"
            let captionWidth = self.contentView.bounds.width - 15 - secondusernameButton.frame.maxX
            let expectedLabelHeight = captionString.height(withConstrainedWidth: captionWidth, font: captionFont!)
            print("* expected label height: \(expectedLabelHeight)")
            captionLabel.font = captionFont
            captionLabel.text = captionString
            
            self.captionLabel.textAlignment = .left
            if actualPost.shouldShowFullText == false {
                if expectedLabelHeight < 17 {
                    self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY - 2, width: captionWidth, height: 16)
                } else if (expectedLabelHeight > 40) {
                    self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY - 2, width: captionWidth, height: 32)
    //                self.captionLabel.addTrailing(with: "... ", moreText: "more", moreTextFont: captionLabel.font, moreTextColor: Constants.primaryColor.hexToUiColor())
                    self.captionLabel.appendReadmore(after: captionString, trailingContent: .readmore)
                    
                } else {
                    self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY - 2, width: captionWidth, height: 32)
    //                self.captionLabel.appendReadmore(after: captionString as NSString, trailingContent: .readmore)
                }
                
            } else {
                
                self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY - 3, width: captionWidth, height: expectedLabelHeight)
                self.viewCommentsButton.frame = CGRect(x: 15, y: captionLabel.frame.maxY+15, width: 5, height: 20)
                self.viewCommentsButton.sizeToFit()
                viewCommentsButton.frame = CGRect(x: viewCommentsButton.frame.minX, y: viewCommentsButton.frame.minY, width: viewCommentsButton.frame.width + 25, height: viewCommentsButton.frame.height + 5)
            }
            
            if actualPost.caption == "" {
                self.secondusernameButton.isHidden = true
                self.secondusernameButton.alpha = 0
                self.captionLabel.isHidden = true
                self.captionLabel.alpha = 0
                self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY-2, width: captionWidth, height: 0)
            } else {
                self.secondusernameButton.isHidden = false
                self.secondusernameButton.alpha = 1
                self.captionLabel.isHidden = false
                self.captionLabel.alpha = 1
            }
            self.firstusernameButton.backgroundColor = contentView.backgroundColor
            self.secondusernameButton.backgroundColor = firstusernameButton.backgroundColor
            
            self.viewCommentsButton.frame = CGRect(x: 15, y: captionLabel.frame.maxY+15, width: 5, height: 20)
            self.viewCommentsButton.alpha = 1
            self.viewCommentsButton.layer.cornerRadius = 8
            self.viewCommentsButton.backgroundColor = Constants.secondaryColor.hexToUiColor()
            self.viewCommentsButton.tintColor = Constants.primaryColor.hexToUiColor()
            viewCommentsButton.titleLabel?.font = UIFont(name: Constants.globalFontMedium, size: 13)
            UIView.performWithoutAnimation {
                self.viewCommentsButton.setTitle("\(actualPost.commentCount.delimiter) Comments", for: .normal)
            }
            self.viewCommentsButton.titleLabel?.textColor = viewCommentsButton.tintColor
            viewCommentsButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
            viewCommentsButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            viewCommentsButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
            self.viewCommentsButton.sizeToFit()
            viewCommentsButton.frame = CGRect(x: viewCommentsButton.frame.minX, y: viewCommentsButton.frame.minY, width: viewCommentsButton.frame.width + 25, height: viewCommentsButton.frame.height + 5)
            
            tmpRightArrow.tintColor = .lightGray
            
            if shouldMakeRed && actualPost.isLiked {
//                self.viewLikesView.backgroundColor = hexStringToUIColor(hex: Constants.universalRed)
//                self.likesLabel.textColor = .white
                self.likeButton.isLiked = true
                styleForLikedBigView()
                tmpRightArrow.tintColor = .white
            } else if actualPost.isLiked == false {
                self.likeButton.isLiked = false
            }
        }
        addPinchGesture()
        styleActiveLabel()
        let seconds = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
            let tapAction = UITapGestureRecognizer(target: self, action: #selector(self.didTapLabel(_:)))
            self.captionLabel?.isUserInteractionEnabled = true
            self.captionLabel?.addGestureRecognizer(tapAction)
        }
        
    }
    @objc func didTapLabel(_ sender: UITapGestureRecognizer) {
           guard let text = captionLabel.text else { return }

           let readmore = (text as NSString).range(of: TrailingContent.readmore.text)
           let readless = (text as NSString).range(of: TrailingContent.readless.text)
           if sender.didTap(label: captionLabel, inRange: readmore) {
               let captionFont = UIFont(name: "\(Constants.globalFont)", size: 12)
               let captionString = "\(actualPost.username)   \(actualPost.caption)"
               captionLabel.appendReadLess(after: captionString, trailingContent: .readless)
//               captionLabel.sizeToFit()
               
               let captionWidth = self.contentView.bounds.width - 15 - secondusernameButton.frame.maxX
               let expectedLabelHeight = captionString.height(withConstrainedWidth: captionWidth, font: captionFont!)
               self.captionLabel.frame = CGRect(x: secondusernameButton.frame.minX, y: secondusernameButton.frame.minY - 2, width: captionWidth, height: expectedLabelHeight)
               self.viewCommentsButton.frame = CGRect(x: 15, y: captionLabel.frame.maxY+15, width: 5, height: 20)
               self.viewCommentsButton.sizeToFit()
               viewCommentsButton.frame = CGRect(x: viewCommentsButton.frame.minX, y: viewCommentsButton.frame.minY, width: viewCommentsButton.frame.width + 25, height: viewCommentsButton.frame.height + 5)
               if let _ = self.parentViewController?.imagePosts?[postIndex] as? imagePost {
                   (self.parentViewController?.imagePosts?[postIndex] as! imagePost).shouldShowFullText = true
                   self.parentViewController?.postsTableView.reloadData()
               }
           } else if  sender.didTap(label: captionLabel, inRange: readless) {
               captionLabel.appendReadmore(after: actualPost.caption, trailingContent: .readmore)
               self.viewCommentsButton.frame = CGRect(x: 15, y: captionLabel.frame.maxY+15, width: 5, height: 20)
               self.viewCommentsButton.sizeToFit()
               if let _ = self.parentViewController?.imagePosts?[postIndex] as? imagePost {
                   (self.parentViewController?.imagePosts?[postIndex] as! imagePost).shouldShowFullText = false
                   self.parentViewController?.postsTableView.reloadData()
               }
           } else { return }
           
       }
    func styleActiveLabel() {
        captionLabel.enabledTypes = [.mention, .hashtag, .url]
        captionLabel.customize { label in
            label.hashtagColor = Constants.primaryColor.hexToUiColor().withAlphaComponent(0.7)
            label.mentionColor = Constants.primaryColor.hexToUiColor()
            label.URLColor = Constants.primaryColor.hexToUiColor()
            label.handleMentionTap { userHandle in
                print("* opening profile for user: @\(userHandle)")
                let userLocalRef = self.db.collection("user-locations").whereField("username", isEqualTo: userHandle.lowercased()).limit(to: 1)
                userLocalRef.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        if querySnapshot?.count != 0 {
                            print("* got user doc: \(querySnapshot?.documents[0].documentID)")
                            self.openProfileForUser(withUID: (querySnapshot?.documents[0].documentID)!)
                        }
                    }
                }
            }
//            label.handleHashtagTap { self.alert("Hashtag", message: $0) }
            label.handleURLTap { url in
                print("* opening url: \(url)")
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    func setupSlideshow() {
        print("* setting up slideshow with \(actualPost.multiImageUrls)")
        slideshow.frame = mainPostImage.frame
        slideshow.slideshowInterval = 0
        slideshow.pageIndicatorPosition = .init(horizontal: .center, vertical: .under)
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFill

        slideshow.pageIndicator = nil
        // optional way to show activity indicator during image load (skipping the line will show no activity indicator)
        slideshow.activityIndicator = DefaultActivityIndicator()
        slideshow.delegate = self
        slideshow.zoomEnabled = true
        slideshow.circular = false
        var imageSrcs: [KingfisherSource] = []
        for im in actualPost.multiImageUrls {
            imageSrcs.append(KingfisherSource(urlString: im)!)
        }
//        setupSnakeControl()
        IGpagecontrol.numberOfPages = imageSrcs.count
        setupIGControl()
        
        slideshow.setImageInputs(imageSrcs)
//        slideshow.scrollView.delegate = self
    }
    func setupIGControl() {
        let frame = CGRect(x: 0, y: Int(slideshow.frame.maxY) + 20, width: 24, height: 15)
//        IGpagecontrol = ISPageControl(frame: frame, numberOfPages: 4)
        
        IGpagecontrol.frame = frame
        IGpagecontrol.center.x = self.contentView.frame.width / 2
        IGpagecontrol.radius = 3.5
        IGpagecontrol.padding = 4
        IGpagecontrol.inactiveTintColor = .lightGray
        IGpagecontrol.currentPageTintColor = Constants.primaryColor.hexToUiColor()
        IGpagecontrol.borderWidth = 0
//        IGpagecontrol.borderColor = UIColor.red
        numOfPostsLabel.text = "1/\(actualPost.multiImageUrls.count)"
        numOfPostsLabel.font = UIFont(name: Constants.globalFontMedium, size: 12)
        let pad = 10
        let wid = 40
        numOfPostsView.frame = CGRect(x: Int(self.contentView.frame.width) - pad - wid, y: Int(slideshow.frame.minY) + pad, width: wid, height: 25)
        print("* num postsview frame: \(numOfPostsView)")
        numOfPostsView.backgroundColor = .clear
        numOfPostsView.layer.cornerRadius = 8
        numOfPostsView.clipsToBounds = true
        
        numOfPostsBlurView.frame = CGRect(x: 0, y: 0, width: numOfPostsView.frame.width, height: numOfPostsView.frame.height)
//        numOfPostsBlurView.backgroundColor = .black
        let blurEffect = UIBlurEffect(style: .dark)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        numOfPostsBlurView.effect = blurEffect
        numOfPostsBlurView.alpha = 0.8
        numOfPostsLabel.frame = numOfPostsBlurView.frame
        numOfPostsLabel.textAlignment = .center
        
//        numOfPostsView.alpha = 1
//        numOfPostsView.isHidden = false
    }
    func setupSnakeControl() {
        pageControl.indicatorRadius = 4
        pageControl.indicatorPadding = 6
        pageControl.activeTint = .gray
        pageControl.inactiveTint = .lightGray.withAlphaComponent(0.5)
        
        // custom frame stuffs
        
        
        pageControl.pageCount = actualPost.multiImageUrls.count
        let tmpSize = pageControl.sizeThatFits(CGSize.zero)
//        pageControl.layer.borderColor = UIColor.red.cgColor
//        pageControl.layer.borderWidth = 2
        var size = Int(tmpSize.width)
        pageControl.frame = CGRect(x: 0, y: Int(slideshow.frame.maxY) + 20, width: size, height: 15)
        pageControl.center.x = self.contentView.frame.width / 2
    }
    func imageSlideshow(_ imageSlideshow: ImageSlideshow, didChangeCurrentPageTo page: Int) {
           print("[slideshow changed] current page:", page)
        
            let pageMath = imageSlideshow.scrollView.contentOffset.x / imageSlideshow.scrollView.bounds.width
//            pageControl.progress = pageMath
            print("* set page control progress \(pageMath)")
            IGpagecontrol.currentPage = Int(page)
            numOfPostsLabel.text = "\(page + 1)/\(actualPost.multiImageUrls.count)"
        
        if self.numOfPostsView.alpha == 0 && page == imageSlideshow.currentPage {
            self.numOfPostsView.fadeIn()
        }
        let seconds = 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                // Put your code which should be executed with a delay here
                if page == imageSlideshow.currentPage {
                    if self.numOfPostsView.alpha == 1 {
                        self.numOfPostsView.fadeOut()
                    }
                }
                
                
            }
       }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let page = scrollView.contentOffset.x / scrollView.bounds.width
            let progressInPage = scrollView.contentOffset.x - (page * scrollView.bounds.width)
            let progress = CGFloat(page) + progressInPage
//        pageControl.progress = progress
        
        }
    func imageSlideshowDidEndDecelerating(_ imageSlideshow: ImageSlideshow) {
        print("* slideshow did end decelerating")
    }
    private func addPinchGesture() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
                pinch.delegate = self
                self.mainPostImage.addGestureRecognizer(pinch)
                
                let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
                pan.delegate = self
                self.mainPostImage.addGestureRecognizer(pan)
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if self.zoomEnabled && sender.state == .began {
            self.imgCenter = sender.view?.center
        } else if self.zoomEnabled && sender.state == .changed {
            let translation = sender.translation(in: self)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.mainPostImage.superview)
        }
    }
    func disableTableViewScrolling() {
        if let vc = self.findViewController() as? FeedViewController {
            vc.postsTableView.isScrollEnabled = false
            vc.postsTableView.clipsToBounds = false
            self.clipsToBounds = false
        }
    }
    func enableTableViewScrolling() {
        if let vc = self.findViewController() as? FeedViewController {
            vc.postsTableView.isScrollEnabled = true
            vc.postsTableView.clipsToBounds = true
            self.clipsToBounds = true
        }
    }
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            let currentScale = self.mainPostImage.frame.size.width / self.mainPostImage.bounds.size.width
            let newScale = currentScale * sender.scale
            if newScale > 1 {
                self.zoomEnabled = true
            }
            self.disableTableViewScrolling()
        } else if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = self.mainPostImage.frame.size.width / self.mainPostImage.bounds.size.width
            var newScale = currentScale * sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.mainPostImage.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
            self.disableTableViewScrolling()
        } else if sender.state == .ended {
            guard let center = self.imgCenter else {return}
            UIView.animate(withDuration: 0.3, animations: {
                self.mainPostImage.transform = CGAffineTransform.identity
                self.mainPostImage.center = center
            }, completion: { _ in
                self.zoomEnabled = false
                self.enableTableViewScrolling()
            })
        }
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    func handleProfileUrl(url: String, forIndex: Int) {
        if url == "" {
            if forIndex == 0 {
                profilePicView1.image = UIImage(named: "no-profile-img.jpeg")
            } else if forIndex == 1 {
                profilePicView2.image = UIImage(named: "no-profile-img.jpeg")
            } else if forIndex == 2 {
                profilePicView3.image = UIImage(named: "no-profile-img.jpeg")
            }
        } else {
            putProfileImage(url: url, intoIndex: forIndex)
        }
    }
    func updateCommentButtonLocation() {
        self.commentBubbleButton.frame = CGRect(x: self.likeButton.frame.maxX + 10, y: self.commentBubbleButton.frame.minY, width: self.commentBubbleButton.frame.width, height: self.commentBubbleButton.frame.height)
    }
    func likeButtonAnimateToRed() {
//        self.updateCommentButtonLocation()
//        if self.likeButton.isLiked {
//            self.likeButton.setNewLikeAmount(to: self.likeButton.likesCount - 1)
//            self.likeButton.sizeToFit()
//        } else {
//            self.likeButton.setNewLikeAmount(to: self.likeButton.likesCount + 1)
//            self.likeButton.sizeToFit()
//        }
        
        self.likeButton.flipLikedState()
        actualPost.isLiked = self.likeButton.isLiked
        makeBigOlLikesViewRed()
        let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
    }
    func animateUpLikes() {
        UIView.animate(withDuration: 0.1, animations: {
            let newScale = 1.3
            self.viewLikesView.transform = self.viewLikesView.transform.scaledBy(x: newScale, y: newScale)
        }, completion: { _ in
          UIView.animate(withDuration: 0.1, animations: {
              self.viewLikesView.transform = CGAffineTransform.identity
              
          })
            
        })
    }
    func styleForLikedBigView() {
        self.viewLikesView.layer.shadowColor = Constants.universalRed.hexToUiColor().withAlphaComponent(0.7).cgColor
        self.viewLikesView.layer.shadowOffset = CGSize(width: 2, height: 4)
        self.viewLikesView.layer.shadowOpacity = 0.4
        self.viewLikesView.layer.shadowRadius = 4
        self.viewLikesView.layer.cornerRadius = 8
        self.viewLikesView.backgroundColor = Constants.universalRed.hexToUiColor()
        self.likesLabel.textColor = .white
    }
    func styleForUnLikedBigView() {
        self.viewLikesView.layer.shadowColor = Constants.textColor.hexToUiColor().withAlphaComponent(0.1).cgColor
        self.viewLikesView.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.viewLikesView.layer.shadowOpacity = 0.4
        self.viewLikesView.layer.shadowRadius = 4
        self.viewLikesView.layer.cornerRadius = 8
        if Constants.isDarkmode {
            self.viewLikesView.backgroundColor = hexStringToUIColor(hex: "#3d3d3d")
        } else {
            self.viewLikesView.backgroundColor = hexStringToUIColor(hex: "#e8e8e8")
        }
        
        self.likesLabel.textColor = Constants.textColor.hexToUiColor()
    }
    func makeBigOlLikesViewRed() {
        
        print("* should make red!")
        let originalLikesLabelX = self.likesLabel.frame.minX
        print("* is liked button liked: \(self.likeButton.isLiked)")
        let currentval = (likesLabel.text?.replacingOccurrences(of: " likes", with: "") ?? "0").replacingOccurrences(of: " like", with: "").replacingOccurrences(of: ",", with: "")
        print("* upadting post at \(postIndex)")
        if self.likeButton.isLiked {
            if shouldMakeRed {
                styleForLikedBigView()
            }
            self.tmpRightArrow.tintColor = .white
            likesLabel.pushScrollingTransitionUp(0.2) // Invoke before changing content
            likesLabel.text = "\(((Int(currentval) ?? 0) + 1).delimiter) likes" // roundedWithAbbreviations if want k/M for likes
            
            if let _ = (parentViewController?.imagePosts?[postIndex] as? imagePost) {
                (parentViewController?.imagePosts?[postIndex] as! imagePost).likesCount = ((Int(currentval) ?? 0) + 1)
                (parentViewController?.imagePosts?[postIndex] as! imagePost).isLiked = true
            }
            
//            animateUpLikes()
        } else {
            styleForUnLikedBigView()
            self.tmpRightArrow.tintColor = .lightGray
            if ((Int(currentval) ?? 1) - 1) >= 0 {
                likesLabel.pushScrollingTransitionDown(0.2) // Invoke before changing content
                likesLabel.text = "\(((Int(currentval) ?? 1) - 1).delimiter) likes" // roundedWithAbbreviations if want k/M for likes
                if let _ = (parentViewController?.imagePosts?[postIndex] as? imagePost) {
                    (parentViewController?.imagePosts?[postIndex] as! imagePost).likesCount = ((Int(currentval) ?? 1) - 1)
                    (parentViewController?.imagePosts?[postIndex] as! imagePost).isLiked = false
                }
            }
            
//            animateDownLikes()
        }
        
        
        likesLabel.sizeToFit()
        likesLabel.frame = CGRect(x: originalLikesLabelX, y: 0, width: self.likesLabel.frame.width, height: viewLikesView.frame.height)
//        self.viewLikesView.frame = CGRect(x: self.viewLikesView.frame.minX, y: self.viewLikesView.frame.minY, width: self.likesLabel.frame.maxX + 15, height: self.viewLikesView.frame.height)
        self.viewLikesView.frame = CGRect(x: self.viewLikesView.frame.minX, y: self.viewLikesView.frame.minY, width: self.tmpRightArrow.frame.maxX + 5, height: self.viewLikesView.frame.height)
    }
    
    @IBAction func viewLikesTapped(_ sender: Any) {
        openLikesList(authorID: actualPost.userID, numLikes: actualPost.likesCount, postID: actualPost.postID)
    }
    @IBAction func threeDotsPressed(_ sender: Any) {
        let vc = ThreeDotsOnPostController()
        vc.postID = self.actualPost.postID
        vc.authorOfPost = self.actualPost.userID
        vc.imagePostURL = self.actualPost.imageUrl
        self.parentViewController?.presentPanModal(vc)
    }
    @IBAction func saveViewTapped(_ sender: Any) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        let vc = AddToCollectionPopup()
        vc.actualPost = actualPost
        self.parentViewController?.navigationController?.presentPanModal(vc)
    }
    @IBAction func savedPressed(_ sender: Any) {
        let userID : String = (Auth.auth().currentUser?.uid)!
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        savePostButton.flipLikedState()
        Analytics.logEvent("saved_post", parameters: nil)
        if actualPost.isSaved == true {
            (parentViewController?.imagePosts?[postIndex] as! imagePost).isSaved = false
            actualPost.isSaved = false
            savePostButton.isLiked = false
            db.collection("saved").document(userID).collection("all_posts").document(actualPost.postID).delete()
            savePostButton.setImage(savePostButton.unlikedImage, for: .normal)
        } else {
            (parentViewController?.imagePosts?[postIndex] as! imagePost).isSaved = true
            actualPost.isSaved = true
            db.collection("saved").document(userID).collection("all_posts").document(actualPost.postID).setData(["postID": actualPost.postID, "authorID": actualPost.userID, "timestamp": Date().timeIntervalSince1970])
            savePostButton.isLiked = true
            savePostButton.setImage(savePostButton.likedImage, for: .normal)
            let vc = AddToCollectionPopup()
            vc.actualPost = actualPost
            self.parentViewController?.navigationController?.presentPanModal(vc)
            UIView.animate(withDuration: 0.2, animations: { //1
                
                self.popupSaved()
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                   // Code you want to be delayed
                    UIView.animate(withDuration: 0.2) {
                        self.resetSavedPopup()
                    }
                    
                }
            })
           
            
        }
    }
    func openLikesList(authorID: String, numLikes: Int, postID: String) {
        print("* open likes list")
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userListViewController") as? userListViewController {
            vc.userConfig = userListConfig(type: "likes", originalAuthorID: authorID, postID: postID, numberToPutInFront: numLikes)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            if let navigator = self.findViewController()?.navigationController {
                navigator.pushViewController(vc, animated: true)
            }
        }
    }
    func likePost(id: String, author: String) {
        
        if isCurrentlySavingData == false {
            Analytics.logEvent("like_post", parameters: [
              "postAuthor": userID,
              "postId": id,
              "currentUID": author
            ])
            isCurrentlySavingData = true
        let postsRef = db.collection("posts")
        let timestamp = NSDate().timeIntervalSince1970
//            let value: Double = 1
//            let incr = FieldValue.increment(value)
//
            let userIDz = Auth.auth().currentUser?.uid
//            postsRef.document(userID).collection("posts").document(id).updateData(["likes_count":incr])
            self.db.collection("user-locations").document(userIDz!).getDocument { (document, err) in
                print("* doc: \(document)")
                if ((document?.exists) != nil) && document?.exists == true {
                    let data = document?.data()! as! [String: AnyObject]
                    let usrname = data["username"] as? String ?? ""
                    postsRef.document(self.userID).collection("posts").document(id).collection("likes").document(userIDz!).setData([
                    "uid": "\(author)",
                    "likedAtTimeStamp": Int(timestamp),
                    "username":usrname
                ], merge: true) { err in
                    print("* successfully liked post")
                    self.isCurrentlySavingData = false
                }
                }
            }
            
        }
    }
    func unlikePost(id: String, author: String) {
        if isCurrentlySavingData == false {
            Analytics.logEvent("unlike_post", parameters: [
              "postAuthor": userID,
              "postId": id,
              "currentUID": author
            ])
            isCurrentlySavingData = true
        let postsRef = db.collection("posts")
        let timestamp = NSDate().timeIntervalSince1970
//        let value: Double = -1
//        let incr = FieldValue.increment(value)
//        postsRef.document(userID).collection("posts").document(id).updateData(["likes_count":incr])
        
        postsRef.document(userID).collection("posts").document(id).collection("likes").document(author).delete() {err in
            print("* done unliking post!")
            self.isCurrentlySavingData = false
        }
        
        }
    }
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if isCurrentlySavingData == false {
            
            print("Double Tap!")
            print("* like button pressed")
            let userIDz : String = (Auth.auth().currentUser?.uid)!
            Analytics.logEvent("double_tap_like_post", parameters: [
                "postAuthor": userID,
              "postId": postid,
              "currentUID": userIDz
            ])
            if self.likeButton.isLiked == false{
                print("* liking post \(postid)")
                likePost(id: postid, author: userIDz)
                
            } else {
                print("* unliking post \(postid)")
                unlikePost(id: postid, author: userIDz)
            }
            likeButtonAnimateToRed()
        }
        
    }
    func showCommentSection(shouldSetFirstResponder: Bool = false) {
//        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CommentsViewController") as? CommentsViewController {
//            if let navigator = self.findViewController()?.navigationController {
//                vc.actualPost = self.actualPost
//                vc.tmpImage = self.mainPostImage.image
//                vc.originalPostID = self.postid
//                vc.originalPostAuthorID = self.userID
//                vc.currentUserUsername = self.currentUserUsername
//                vc.currentUserProfilePic = self.currentUserProfilePic
//                if shouldSetFirstResponder {
//                    vc.commentTextField.becomeFirstResponder()
//                }
//                let generator = UIImpactFeedbackGenerator(style: .medium)
//                generator.impactOccurred()
//                navigator.pushViewController(vc, animated: true)
//
//            }
//        }
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "NewCommentSection") as? CommentSectionPopup {
//        let vc = CommentSectionPopup()
        vc.actualPost = self.actualPost
        vc.originalPostID = self.postid
        vc.originalPostAuthorID = self.userID
        vc.currentUserUsername = self.currentUserUsername
            vc.parentVC = self.parentViewController
        vc.currentUserProfilePic = self.currentUserProfilePic
        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
        if let navigator = self.findViewController()?.navigationController {
            navigator.presentPanModal(vc)
        }
        }
    }
    @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {

        print("Single Tap, presenting comment section")
        showCommentSection()

       }
    func openProfileForUser(withUID: String) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
            if let navigator = self.findViewController()?.navigationController {
                vc.uidOfProfile = withUID
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigator.pushViewController(vc, animated: true)

            }
        }
    }
    @IBAction func messagesPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
//        let drop = Drop(
//            title: "Coming Soon",
//            subtitle: "Direct Messaging will be coming in a future update",
//            icon: UIImage(systemName: "exclamationmark.triangle")?.withTintColor(.yellow),
//            action: .init {
//                print("Drop tapped")
//                Drops.hideCurrent()
//            },
//            position: .top,
//            duration: 5.0,
//            accessibility: "Alert: Title, Subtitle"
//        )
//        Drops.show(drop)
        let image = UIImage.init(systemName: "exclamationmark.triangle")!.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
//        SPIndicator.present(title: "Coming Soon", message: "DMs are coming soon", preset: .custom(image))
            parentViewController?.showErrorMessage(title: "Coming Soon", body: "Messaging will be coming in a future update, sorry if we gave u blue balls :P")
    }
    
    @IBAction func userNameButtonTapped(_ sender: Any) {
        openProfileForUser(withUID: actualPost.userID)
    }
    @IBAction func likeButtonPressed(_ sender: Any) {
        if isCurrentlySavingData == false {
            print("* like button pressed")
            let userID : String = (Auth.auth().currentUser?.uid)!
            if self.likeButton.isLiked == false{
                print("* liking post \(postid)")
                likePost(id: postid, author: userID)
            } else {
                print("* unliking post \(postid)")
                unlikePost(id: postid, author: userID)
            }
            likeButtonAnimateToRed()
            
        }
        
    }
    @IBAction func commentButtonPressed(_ sender: Any) {
        showCommentSection()
    }
    func putProfileImage(url: String, intoIndex: Int) {
        guard let url = URL.init(string: url) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        let processor = DownsamplingImageProcessor(size: CGSize(width: profilePicView1.frame.width, height: profilePicView1.frame.height))
        KingfisherManager.shared.retrieveImage(with: resource, options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .cacheOriginalImage
        ], progressBlock: nil) { result in
            switch result {
            case .success(let value):
                if intoIndex == 0 {
                    self.profilePicView1.image = value.image
                    self.profilePicView1.alpha = 1
                    self.profilePicView1.isHidden = false
                } else if intoIndex == 1 {
                    self.profilePicView2.image = value.image
                    self.profilePicView2.alpha = 1
                    self.profilePicView2.isHidden = false
                } else if intoIndex == 2 {
                    self.profilePicView3.image = value.image
                    self.profilePicView3.alpha = 1
                    self.profilePicView3.isHidden = false
                }
                
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func downloadImage(`with` urlString : String) {
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        let processor = DownsamplingImageProcessor(size: CGSize(width: profilePicImage.frame.width, height: profilePicImage.frame.height))
        KingfisherManager.shared.retrieveImage(with: resource, options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .cacheOriginalImage
        ], progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.profilePicImage.image = value.image
                self.profilePicImage.alpha = 1
                self.profilePicImage.isHidden = false
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
}
extension UIImageView {
    func styleForMiniProfilePic() {
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.contentMode = .scaleToFill
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
        self.layer.isOpaque = false
        self.isHidden = false
        self.alpha = 1
    }
}
extension UILabel {

        func addTrailing(with trailingText: String, moreText: String, moreTextFont: UIFont, moreTextColor: UIColor) {
            let readMoreText: String = trailingText + moreText

            let lengthForVisibleString: Int = self.vissibleTextLength
            let mutableString: String = self.text!
            let trimmedString: String? = (mutableString as NSString).replacingCharacters(in: NSRange(location: lengthForVisibleString, length: ((self.text?.count)! - lengthForVisibleString)), with: "")
            let readMoreLength: Int = (readMoreText.count)
            let trimmedForReadMore: String = (trimmedString! as NSString).replacingCharacters(in: NSRange(location: ((trimmedString?.count ?? 0) - readMoreLength), length: readMoreLength), with: "") + trailingText
            let answerAttributed = NSMutableAttributedString(string: trimmedForReadMore, attributes: [NSAttributedString.Key.font: self.font])
            let readMoreAttributed = NSMutableAttributedString(string: moreText, attributes: [NSAttributedString.Key.font: moreTextFont, NSAttributedString.Key.foregroundColor: moreTextColor])
            answerAttributed.append(readMoreAttributed)
            self.attributedText = answerAttributed
        }

        var vissibleTextLength: Int {
            let font: UIFont = self.font
            let mode: NSLineBreakMode = self.lineBreakMode
            let labelWidth: CGFloat = self.frame.size.width
            let labelHeight: CGFloat = self.frame.size.height
            let sizeConstraint = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)

            let attributes: [AnyHashable: Any] = [NSAttributedString.Key.font: font]
            let attributedText = NSAttributedString(string: self.text!, attributes: attributes as? [NSAttributedString.Key : Any])
            let boundingRect: CGRect = attributedText.boundingRect(with: sizeConstraint, options: .usesLineFragmentOrigin, context: nil)

            if boundingRect.size.height > labelHeight {
                var index: Int = 0
                var prev: Int = 0
                let characterSet = CharacterSet.whitespacesAndNewlines
                repeat {
                    prev = index
                    if mode == NSLineBreakMode.byCharWrapping {
                        index += 1
                    } else {
                        index = (self.text! as NSString).rangeOfCharacter(from: characterSet, options: [], range: NSRange(location: index + 1, length: self.text!.count - index - 1)).location
                    }
                } while index != NSNotFound && index < self.text!.count && (self.text! as NSString).substring(to: index).boundingRect(with: sizeConstraint, options: .usesLineFragmentOrigin, attributes: attributes as? [NSAttributedString.Key : Any], context: nil).size.height <= labelHeight
                return prev
            }
            return self.text!.count
        }
    }
extension UITapGestureRecognizer {

    func didTap(label: UILabel, inRange targetRange: NSRange) -> Bool {
        
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)

        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}
