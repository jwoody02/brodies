//
//  StoriesTableViewCell.swift
//  Egg.
//
//  Created by Jordan Wood on 7/27/22.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SkeletonView
import NextLevel
import ViewAnimator
class StoriesTableViewCell: UITableViewCell, SkeletonCollectionViewDataSource {
    
    var db = Firestore.firestore()
    let storyDispatchGroup = DispatchGroup()
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "storycell"
    }
    
    
    @IBOutlet weak var storiesCollectionView: UICollectionView!
    var stories = [storyPost] ()
    var tmpStories = [storyPost] ()
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // ...
        
        // Comment if you set Datasource and delegate in .xib
        self.storiesCollectionView.dataSource = self
        self.storiesCollectionView.delegate = self
        if let layout = storiesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        storiesCollectionView.showsHorizontalScrollIndicator = false
        storiesCollectionView.showsVerticalScrollIndicator = false
        storiesCollectionView.isSkeletonable = true
        storiesCollectionView.showAnimatedSkeleton(usingColor: .clouds, transition: .crossDissolve(0.25))
        if Auth.auth().currentUser?.uid != nil {

           //user is logged in
            fetchCurrentUserStory()
            
            }else{
             //user is not logged in
            }
        
//        storyDispatchGroup.enter()
//        fetchStories()
        storyDispatchGroup.notify(queue: .main) {
            print("* fetched stories!")
            if self.stories != self.tmpStories {
                self.storiesCollectionView.stopSkeletonAnimation()
                self.storiesCollectionView.hideSkeleton(reloadDataAfter: true, transition: .crossDissolve(0.25))
                let cells = self.storiesCollectionView.visibleCells
                let animation = AnimationType.from(direction: .right, offset: 60.0)
                UIView.animate(views: cells, animations: [animation])
            } else {
                print("* stories are the exact same, not reloading the ui")
            }
            
        }
    }
    func styleComponents() {
        
    }
    func reloadAllStoryComponents() {
        tmpStories = stories
        stories.removeAll()
        fetchCurrentUserStory()
    }
    func fetchCurrentUserStory() {
        storyDispatchGroup.enter()
        let userID = Auth.auth().currentUser?.uid
        print("* fetching \(userID) latestStory")
        let now = NSDate().timeIntervalSince1970
        let oneDayAgo = now - (60 * 60 * 24)
        let storiesRef = db.collection("stories")
        let userStory = storiesRef.document(userID!).collection("stories").whereField("createdAt", isLessThan: now).whereField("createdAt", isGreaterThan: oneDayAgo).order(by: "createdAt", descending: true).limit(to: 1)
        
        userStory.getDocuments() { (querySnapshot, err) in
            var myStory = storyPost()
            myStory.isMyStory = true
            print("* got snapshot from current user: \(querySnapshot)")
            if let err = err {
                print("Error getting documents: \(err)")
                myStory.isEmpty = true
                self.stories.append(myStory)
//                self.storyDispatchGroup.leave()
            } else {
                if querySnapshot!.isEmpty {
                    print("* detected no recent stories")
                    myStory.isEmpty = true
                    self.stories.append(myStory)
//                    self.storyDispatchGroup.leave()
                } else {
                    print("* user does have a story")
                    myStory.isEmpty = false
                    let values = querySnapshot?.documents.first?.data()  as? [String: Any]
                    myStory.imageUrl = values?["storyImageUrl"] as? String ?? ""
                    myStory.createdAt = values?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                    myStory.userID = userID!
                    self.stories.append(myStory)
//                    self.storyDispatchGroup.leave()
                }
            }
            self.fetchStories()
        }
    }
    func fetchStories() {
        storyDispatchGroup.enter()
        let userID = Auth.auth().currentUser?.uid
        let followersRef = db.collection("followers")
        let now = NSDate().timeIntervalSince1970
        let oneDayAgo = now - (60 * 60 * 24)
        let oneDayAgoAsDate = Date(timeIntervalSince1970: oneDayAgo)
        print("* fetching story feed")
        print("* date now: \(now) vs one day ago: \(oneDayAgo)")
        print("* checking for followers: \(userID!)")
        let storyQuery = followersRef.whereField("followers", arrayContains: userID!).whereField("last_story.createdAt", isGreaterThan: oneDayAgoAsDate).limit(to: 6)
        storyQuery.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("* err, assuming no stories: \(err)")
                self.storyDispatchGroup.leave()
                self.storyDispatchGroup.leave()
            } else {
                if querySnapshot!.isEmpty {
                    print("* snapshot empty, assuming no stories")
                    self.storyDispatchGroup.leave()
                    self.storyDispatchGroup.leave()
                } else {
                    print("* got some stories")
                    for document in querySnapshot!.documents {
                        if document.documentID != userID {
                            self.storyDispatchGroup.enter()
                            let now = NSDate().timeIntervalSince1970
                            let oneDayAgo = now - (60 * 60 * 24)
                            var story = storyPost()
                            let storyz = self.db.collection("stories").document(document.documentID).collection("stories").whereField("createdAt", isLessThan: now).whereField("createdAt", isGreaterThan: oneDayAgo).order(by: "createdAt", descending: true).limit(to: 1)
                            
                            storyz.getDocuments() { (doc, err) in
                                let values = doc?.documents.first?.data()  as? [String: Any]
                                story.imageUrl = values?["storyImageUrl"] as? String ?? ""
                                story.createdAt = values?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                                story.userID = document.documentID
    //                            story.userImageUrl = document.data()["profileImageURL"] as? String ?? ""
    //                            story.username = document.data()["username"] as? String ?? ""
    //                            story.author_full_name = document.data()["full_name"] as? String ?? ""
                                
                                // collect more of the users info
                                self.db.collection("user-locations").document(document.documentID).getDocument { (docy, err) in
                                    if ((document.exists) != nil) && document.exists == true {
                                        story.userImageUrl = docy?.data()?["profileImageURL"] as? String ?? ""
                                        story.username = docy?.data()?["username"] as? String ?? ""
                                        story.author_full_name = docy?.data()?["full_name"] as? String ?? ""
                                        self.stories.append(story)
                                    }
                                    
                                    self.storyDispatchGroup.leave()
                                    if document == querySnapshot?.documents.last {
                                        self.storyDispatchGroup.leave()
                                        self.storyDispatchGroup.leave()
                                    }
                                }
                                
                            }
                        } else {
                            print("* looks like it has the same document id as our user")
                            if document == querySnapshot?.documents.last {
                                self.storyDispatchGroup.leave()
                                self.storyDispatchGroup.leave()
                            }
                        }
                        
                    }
                }
            }
        }
    }
    // Inside UITableViewCell subclass
    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0))
    }
}

extension storyPost: Equatable {
    static func == (lhs: storyPost, rhs: storyPost) -> Bool {
        return lhs.postID == rhs.postID && lhs.userID == rhs.userID
    }
}
