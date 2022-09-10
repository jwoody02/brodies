//
//  StoriesHolderCell.swift
//  Egg.
//
//  Created by Jordan Wood on 7/27/22.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import NextLevel
extension StoriesTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = Int(UIScreen.main.bounds.width / 3.25)
        return CGSize(width: width, height: Int(Double(width) * 1.6))
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stories.count
//        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "storycell", for: indexPath) as! StoryCollectionViewCell
        let story = stories[indexPath.row]
        cell.styleComponents(story: story)
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let story = stories[indexPath.row]
        print("* story selected")
        if story.isMyStory && story.isEmpty {
            let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
            print("pushing camera view")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController
            vc?.modalPresentationStyle = .fullScreen
            NextLevel.shared.devicePosition = .back
            var parentCollectionView = self.superview?.findViewController()
            parentCollectionView?.present(vc!, animated: true)
        } else {
            print("* loading more stories from user \(story.userID)")
            let now = NSDate().timeIntervalSince1970
            let oneDayAgo = now - (60 * 60 * 24)
            let storiesRef = db.collection("stories")
            let userStories = storiesRef.document(story.userID).collection("stories").whereField("createdAt", isLessThan: now).whereField("createdAt", isGreaterThan: oneDayAgo).order(by: "createdAt", descending: false).limit(to: 20)
            
            var stores:  [storyPost] = [storyPost] ()
            var storey = [
                "name":"\(story.username)",
                "contentNature":0,
                "previewAsset":"",
                "contents":
                    [
                        [
                            "contentType":0,
                            "assetName":"cathd",
                            "externalURL":"",
                            "duration":10
                        ],
                        [
                            "contentType":0,
                            "assetName":"pandahd",
                            "externalURL":"",
                            "duration":10
                        ]
                    ]
            ] as [String : Any]
            userStories.getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    let mainPostDispatchQueue = DispatchGroup()
                    if querySnapshot!.isEmpty {
                        print("* detected empty story for \(story.userID)")
                    } else {
                        for document in querySnapshot!.documents {
                            print("* \(document.documentID) => \(document.data())")
                            let values = document.data()  as? [String: Any]
                            var storyToPresent = storyPost()
                            storyToPresent.imageUrl = values?["storyImageUrl"] as? String ?? ""
                            storyToPresent.createdAt = values?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                            storyToPresent.userID = document.documentID
                            storyToPresent.userImageUrl = story.userImageUrl
                            storyToPresent.username = story.username
                            storyToPresent.author_full_name = story.author_full_name
                            stores.append(storyToPresent)
                            
                            if document == querySnapshot?.documents.last {
                                print("* reached last story, presenting")
                               
                            }
                            
                        }
                    }
                }
            }
        }
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
