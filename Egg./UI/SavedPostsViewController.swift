//
//  SavedPostsViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 8/16/22.
//

import UIKit
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseAuth

class SavedPostsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imagePosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //        previewPostProfileCell
        //        print("* loading new post: \(imagePosts?[indexPath.row].imageUrl ?? "")")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "savedCollectionCell", for: indexPath) as! userProfileImagePosts
        cell.stylePost()
        cell.hasRetried = false
        cell.actualPost = imagePosts[indexPath.row]
        cell.backgroundColor = .white
        //        cell.previewImage.downloadWithUrlSession(at: cell, urlStr: imagePosts?[indexPath.row].thumbNailImageURL ?? "")
        cell.setPostImage(fromUrl: imagePosts[indexPath.row].thumbNailImageURL)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow:CGFloat = 3
        let spacingBetweenCells:CGFloat = 1
        
        let totalSpacing = (2 * self.spacing) + ((numberOfItemsPerRow - 1) * spacingBetweenCells) //Amount of total spacing in a row
        
        if let collection = self.postsCollectionView {
            let width = (collection.bounds.width - totalSpacing)/numberOfItemsPerRow
            return CGSize(width: width, height: width)
        }else{
            return CGSize(width: 0, height: 0)
        }
        
    }
    private let spacing:CGFloat = 1
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        print("* set selected path: \(self.selectedIndexPath)")
        self.performSegue(withIdentifier: "ShowPhotoPageView", sender: self)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if (indexPath.row == (imagePosts.count ?? 1) - 1) && hasReachedEndOfFeed == false {
            
            paginate()
        }
    }
    func paginate() {
        //This line is the main pagination code.
        //Firestore allows you to fetch document from the last queryDocument
        query = query.start(afterDocument: documents.last!).limit(to: 12)
        print("* fetching from last doc: \(documents.last!)")
        getPosts()
    }
    
    var collection: SavedCollection?
    var imagePosts: [imagePost] = []
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var postsCollectionView: UICollectionView!
    private var db = Firestore.firestore()
    
    var hasReachedEndOfFeed = false
    
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    var selectedIndexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        let userID = Auth.auth().currentUser?.uid
        query = db.collection("saved").document(userID!).collection(collection!.internalname).order(by: "timestamp", descending: true).limit(to: 12)
        styleUI()
        self.view.backgroundColor = Constants.backgroundColor.hexToUiColor()
        getPosts()
        Analytics.logEvent("loaded_saved_posts", parameters: nil)
    }
    func styleUI() {
        topWhiteView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 90)
//        topLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
        topLabel.font = UIFont(name: Constants.globalFontBold, size: 16)
        topLabel.text = "\(collection?.publicname ?? "")"
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
        
        let savedY = topWhiteView.frame.maxY - 8
        postsCollectionView.frame = CGRect(x: 0, y: savedY, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - savedY)
        postsCollectionView.backgroundColor = .clear
        postsCollectionView.showsVerticalScrollIndicator = false
        let layout = UICollectionViewFlowLayout()
       layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
       layout.minimumLineSpacing = spacing
       layout.minimumInteritemSpacing = spacing
       self.postsCollectionView?.collectionViewLayout = layout
    }
    func getPosts() {
        print("* getting posts")
        query.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let mainPostDispatchQueue = DispatchGroup()
                if querySnapshot!.isEmpty {
                    print("* detected empty feed")
                    self.hasReachedEndOfFeed = true
                } else {
                    for document in querySnapshot!.documents {
                        let documentDatas = document.data()
                        let authorID = documentDatas["authorID"] as? String ?? ""
                        let postID = documentDatas["postID"] as? String ?? ""
                        mainPostDispatchQueue.enter()
                        print("* collecting post \(documentDatas)")
                        self.documents += [document]
                        self.db.collection("posts").document(authorID).collection("posts").document(postID).getDocument() { (doc, error) in
                            if doc?.exists != nil && doc?.exists == true {
                                let useID = doc?.documentID
                                let values = doc?.data()  as? [String: Any]
                                
                                
                                var post = Egg_.imagePost()
//                                post.userID = self.uidOfProfile
                                post.postID = useID!
                                post.commentCount = values?["comments_count"] as? Int ?? 0 // fix this
                                post.likesCount = values?["likes_count"] as? Int ?? 0
                                post.imageUrl = values?["postImageUrl"] as? String ?? ""
                                post.thumbNailImageURL = values?["thumbnail_url"] as? String ?? ""
                                print("* thumbnail image: \(post.thumbNailImageURL)")
                                post.location = values?["location"] as? String ?? ""
                                post.caption = values?["caption"] as? String ?? ""
                                post.tags = values?["tags"] as? [String] ?? [""]
                                post.createdAt = values?["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                                post.imageHash = values?["imageHash"] as? String ?? ""
//                                post.username = self.user.username
                                post.storageRefForThumbnailImage = values?["storage_ref"] as? String ?? ""
                                self.imagePosts.append(post) // delete if use likes thing
                                mainPostDispatchQueue.leave()
                            } else {
                                mainPostDispatchQueue.leave()
                            }
                        }
                    }
                    mainPostDispatchQueue.notify(queue: .main) {
                        
                        if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                            print("* looks like we've reached the end of posts collection")
                            self.hasReachedEndOfFeed = true
                        } else {
                            DispatchQueue.main.async {
                                self.imagePosts = self.imagePosts.sorted (by: {$0.createdAt > $1.createdAt})
                                print("* reloading data")
                                self.postsCollectionView.isHidden = false
                                self.postsCollectionView.alpha = 1
                                self.postsCollectionView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    @IBAction func goBackPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        self.navigationController?.popViewController(animated: true)
    }
    let interactor = Interactor()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.tabBarController?.navigationItem.hidesBackButton = true
        navigationController?.navigationItem.hidesBackButton = true
        if let destinationViewController = segue.destination as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
        if segue.identifier == "ShowPhotoPageView" {
            let nav = self.navigationController
            let vc = segue.destination as! PhotoPageContainerViewController
            nav?.delegate = vc.transitionController
//            vc.transitionController.fromDelegate = self
            vc.transitionController.toDelegate = vc
            vc.delegate = self
//            vc.currentIndex = self.selectedIndexPath.row
//            vc.parentProfileController = self
//            vc.username = self.currentUsername
//            vc.hasValidStory = self.hasValidStory
//            vc.imageUrl = self.currentProfilePic
//            vc.isFollowing = self.isFollowing
            vc.imagePosts = self.imagePosts
//            vc.profileUID = self.uidOfProfile
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if #available(iOS 11, *) {
            //Do nothing
        }
        else {
            
            //Support for devices running iOS 10 and below
            
            //Check to see if the view is currently visible, and if so,
            //animate the frame transition to the new orientation
            if self.viewIfLoaded?.window != nil {
                
                coordinator.animate(alongsideTransition: { _ in
                    
                    //This needs to be called inside viewWillTransition() instead of viewWillLayoutSubviews()
                    //for devices running iOS 10.0 and earlier otherwise the frames for the view and the
                    //collectionView will not be calculated properly.
                    self.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                    self.postsCollectionView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                    
                }, completion: { _ in
                    
                    //Invalidate the collectionViewLayout
                    self.postsCollectionView.collectionViewLayout.invalidateLayout()
                    
                })
                
            }
            //Otherwise, do not animate the transition
            else {
                
                self.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                self.postsCollectionView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
                
                //Invalidate the collectionViewLayout
                self.postsCollectionView.collectionViewLayout.invalidateLayout()
                
            }
        }
        
    }
    
    func getImageViewFromCollectionViewCell(for selectedIndexPath: IndexPath) -> UIImageView {
        
        //Get the array of visible cells in the collectionView
        let visibleCells = self.postsCollectionView.indexPathsForVisibleItems
        
        //If the current indexPath is not visible in the collectionView,
        //scroll the collectionView to the cell to prevent it from returning a nil value
        if !visibleCells.contains(self.selectedIndexPath) {
            
            //Scroll the collectionView to the current selectedIndexPath which is offscreen
            self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredVertically, animated: false)
            
            //Reload the items at the newly visible indexPaths
            self.postsCollectionView.reloadItems(at: self.postsCollectionView.indexPathsForVisibleItems)
            self.postsCollectionView.layoutIfNeeded()
            
            //Guard against nil values
            guard let guardedCell = (self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts) else {
                //Return a default UIImageView
                return UIImageView(frame: CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0))
            }
            //The PhotoCollectionViewCell was found in the collectionView, return the image
            return guardedCell.previewImage
        }
        else {
            
            //Guard against nil return values
            guard let guardedCell = self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts else {
                //Return a default UIImageView
                return UIImageView(frame: CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0))
            }
            //The PhotoCollectionViewCell was found in the collectionView, return the image
            return guardedCell.previewImage
        }
        
    }
    
    //This function prevents the collectionView from accessing a deallocated cell. In the
    //event that the cell for the selectedIndexPath is nil, a default CGRect is returned in its place
    func getFrameFromCollectionViewCell(for selectedIndexPath: IndexPath) -> CGRect {
        
        //Get the currently visible cells from the collectionView
        let visibleCells = self.postsCollectionView.indexPathsForVisibleItems
        
        //If the current indexPath is not visible in the collectionView,
        //scroll the collectionView to the cell to prevent it from returning a nil value
        if !visibleCells.contains(self.selectedIndexPath) {
            
            //Scroll the collectionView to the cell that is currently offscreen
            self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredVertically, animated: false)
            
            //Reload the items at the newly visible indexPaths
            self.postsCollectionView.reloadItems(at: self.postsCollectionView.indexPathsForVisibleItems)
            self.postsCollectionView.layoutIfNeeded()
            
            //Prevent the collectionView from returning a nil value
            guard let guardedCell = (self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts) else {
                return CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0)
            }
            
            return guardedCell.frame
        }
        //Otherwise the cell should be visible
        else {
            //Prevent the collectionView from returning a nil value
            guard let guardedCell = (self.postsCollectionView.cellForItem(at: self.selectedIndexPath) as? userProfileImagePosts) else {
                return CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0)
            }
            //The cell was found successfully
            return guardedCell.frame
        }
    }
}
extension SavedPostsViewController: PhotoPageContainerViewControllerDelegate {
    
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int) {
        self.selectedIndexPath = IndexPath(row: currentIndex, section: 0)
        self.postsCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredVertically, animated: false)
    }
}
extension SavedPostsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
