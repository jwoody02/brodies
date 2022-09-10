//
//  CommentSectionPopup.swift
//  Egg.
//
//  Created by Jordan Wood on 8/27/22.
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
class CommentReply: Equatable {
    var commentText: String
    var username: String
    var authorID: String
    var timestamp: Double
    var likes_count: Int
    var commentID: String
    var replyID: String
    var authorUserName: String
    var authorProfilePic: String
    var replyText: String
    var isLiked: Bool
    // init function with data from firebase
    init(data: [String: Any]) {
        self.commentText = data["commentText"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.authorID = data["authorID"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Double ?? 0
        self.commentID = data["commentID"] as? String ?? ""
        self.replyID = data["replyID"] as? String ?? ""
        self.authorUserName = data["authorUserName"] as? String ?? ""
        self.authorProfilePic = data["authorProfilePic"] as? String ?? ""
        self.replyText = data["replyText"] as? String ?? ""
        self.likes_count = data["likes_count"] as? Int ?? 0
        self.isLiked = false
    }
    static func ==(lhs: CommentReply, rhs: CommentReply) -> Bool {
        return lhs.authorID == rhs.authorID && lhs.replyID == rhs.replyID && lhs.authorUserName == rhs.authorUserName && lhs.authorProfilePic == rhs.authorProfilePic && lhs.commentText == rhs.commentText && lhs.timestamp == rhs.timestamp
    }

}
extension CommentSectionPopup: TableViewCellDelegate {
    
    func singleTapDetected(in cell: CommentSectionTableViewCell)  {
        if let indexPath = commentsTableView.indexPath(for: cell) {
            print("* comment singleTap \(indexPath) ")
            
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            let recInTableView = commentsTableView.rectForRow(at: IndexPath(row: cell.index, section: 0))
            let absoluteRec = self.commentsTableView.convert(recInTableView, to: commentsTableView.superview)
            print("* got absolute rect for cell: \(absoluteRec)")
//            copyView.frame = absoluteRec
            copyView.frame = CGRect(x: cell.contentView.frame.minX, y: absoluteRec.minY + cell.contentView.frame.minY, width: cell.contentView.frame.width, height: cell.contentView.frame.height)
            OGCopyViewRect = copyView.frame
            self.styleCopyView(actualComment: comments[cell.index])
            self.heartButton.setImage(cell.heartButton.image(for: .normal), for: .normal)
            self.heartButton.tintColor = cell.heartButton.tintColor
            self.profilePicImage.image = cell.profilePicImage.image
            copyView.isHidden = false
            hasReachedEndOfReplies = false
            copyView.isUserInteractionEnabled = true
            commentTextField.placeholder = "Reply to \(cell.actualComment.authorUserName)'s comment"
            tappedComment = cell.actualComment
            repliesTableView.isHidden = true
            // repliesTableView.frame = CGRect(x: copyView.frame.minX, y: copyView.frame.maxY, width: copyView.frame.width, height: )
            // fetch replies for comment
            print("* fetching from posts/\(self.actualPost.userID)/posts/\(actualPost.postID)/comments/\(cell.actualComment.commentID)/comment_replies")
            repliesQuery = self.db.collection("posts").document(self.actualPost.userID).collection("posts").document(actualPost.postID).collection("comments").document(cell.actualComment.commentID).collection("comment_replies").order(by: "timestamp", descending: false).limit(to: 10)
            repliesDocuments.removeAll()
            replies.removeAll()
            hasDoneInitialReplyFetch = false
            fetchReplies()
            UIView.animate(withDuration: 0.25) {
                self.commentsTableView.alpha = 0
                self.commentsLabel.text = "\(cell.actualComment.numberOfReplies) Replies"
                self.copyView.frame = CGRect(x: cell.contentView.frame.minX, y: 60, width: cell.contentView.frame.width, height: cell.contentView.frame.height)
                self.arrowImage.image = UIImage(systemName: "chevron.down")
            }
           
        }
    }
    func doubleTapDetected(in cell: CommentSectionTableViewCell) {
        if let indexPath = commentsTableView.indexPath(for: cell) {
            //            let generator = UIImpactFeedbackGenerator(style: .medium)
            //            generator.impactOccurred()
            print("* comment doubleTap \(indexPath) ")
            cell.likeFunction()
        }
    }
    
    @objc func copyViewTapp() {
        tappedComment = nil
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: {
            self.commentsTableView.alpha = 1
            self.copyView.frame = self.OGCopyViewRect ?? CGRect(x: 0, y: 0, width: 0, height: 0)
            self.arrowImage.image = UIImage(systemName: "chevron.right")
            self.commentsLabel.text = "\(self.actualPost.commentCount) Comments"
            self.commentTextField.placeholder = "Comment on \(self.actualPost.username)'s post"
            self.commentTextField.text = ""
            self.tappedComment = nil
            self.repliesTableView.alpha = 0
            self.replies.removeAll()
        } , completion: { (finished: Bool) in
            self.copyView.isHidden = true
            self.repliesTableView.reloadData()
        })
    }

    @IBAction func copyViewTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: {
            self.commentsTableView.alpha = 1
            self.copyView.frame = self.OGCopyViewRect ?? CGRect(x: 0, y: 0, width: 0, height: 0)
            self.arrowImage.image = UIImage(systemName: "chevron.right")
            
        } , completion: { (finished: Bool) in
            self.copyView.isHidden = true
        })
    }
    func fetchReplies() {
        print("* fetchin commenttt")
        if let tappedComment = tappedComment {
            if hasDoneInitialReplyFetch == false && tappedComment.commentID == highlightCommentUID && replyToOpen != "" {
                print("* using highlight comment id: \(highlightCommentUID)")
                self.db.collection("posts").document(self.actualPost.userID).collection("posts").document(self.actualPost.postID).collection("comments").document(self.highlightCommentUID).collection("comment_replies").document(self.replyToOpen).getDocument { (result, error) in
                    if result?.exists != nil && result?.exists == true {
                        let data = result?.data() as? [String: Any] ?? [:]
                        var reply = CommentReply(data: data)
                        self.db.collection("posts").document(self.actualPost.userID).collection("posts").document(self.actualPost.postID).collection("comments").document(self.highlightCommentUID).collection("comment_replies").document(self.replyToOpen).collection("likes").whereField("uid", isEqualTo: Auth.auth().currentUser?.uid ?? "").limit(to: 1).getDocuments() { (likesSnapshot, err) in
                            if likesSnapshot!.isEmpty {
                                reply.isLiked = false
                                print("* user has not liked comment")
                            } else {
                                reply.isLiked = true
                                print("* comment is liked!")
                            }
                            self.replies = [reply]

                        }
                    } else {
                        print("* reply no longer available")
                    }
                    self.repliesQuery.getDocuments { (snapshot, error) in
                        if let error = error {
                            print("* error fetching replies: \(error)")
                        } else {
                            if let snapshot = snapshot {
                                let mainDispatch = DispatchGroup()
                                for document in snapshot.documents {
                                    let data = document.data()
                                    self.repliesDocuments += [document]
                                    if document.documentID != self.replyToOpen {
                                        var reply = CommentReply(data: data)
                                        mainDispatch.enter()
                                        self.db.collection("posts").document(self.originalPostAuthorID).collection("posts").document(self.originalPostID).collection("comments").document(tappedComment.commentID).collection("comment_replies").document(reply.replyID).collection("likes").whereField("uid", isEqualTo: Auth.auth().currentUser?.uid ?? "").limit(to: 1).getDocuments() { (likesSnapshot, err) in
                                            if likesSnapshot!.isEmpty {
                                                reply.isLiked = false
                                                print("* user has not liked comment")
                                            } else {
                                                reply.isLiked = true
                                                print("* comment is liked!")
                                            }
                                            self.replies.append(reply)
                                            mainDispatch.leave()
                                        }
                                    }
                                    
                                    
                                }
                                
                                if snapshot.isEmpty == true || snapshot.documents.isEmpty == true {
                                    print("* reached end of replies")
                                    self.hasReachedEndOfReplies = true
                                }
                                mainDispatch.notify(queue: .main) {
                                    print("* fetched \(self.replies.count) replies")
                                    self.replies = self.replies.removeDuplicates() // remove duplicate comments
                                    self.repliesTableView.reloadData()
                                    if self.hasDoneInitialReplyFetch == false {
                                        self.repliesTableView.fadeIn()
                                    }
                                    
                                    self.repliesTableView.frame = CGRect(x: self.copyView.frame.minX, y: self.copyView.frame.maxY, width: self.copyView.frame.width, height: self.commentsTableView.frame.height - self.copyView.frame.maxY)
                                    self.hasDoneInitialReplyFetch = true
                                }
                                
                            }
                        }
                    }
                }
            } else {
                repliesQuery.getDocuments { (snapshot, error) in
                    if let error = error {
                        print("* error fetching replies: \(error)")
                    } else {
                        if let snapshot = snapshot {
                            let mainDispatch = DispatchGroup()
                            for document in snapshot.documents {
                                let data = document.data()
                                self.repliesDocuments += [document]
                                if document.documentID != self.replyToOpen {
                                    var reply = CommentReply(data: data)
                                    mainDispatch.enter()
                                    self.db.collection("posts").document(self.originalPostAuthorID).collection("posts").document(self.originalPostID).collection("comments").document(tappedComment.commentID).collection("comment_replies").document(reply.replyID).collection("likes").whereField("uid", isEqualTo: Auth.auth().currentUser?.uid ?? "").limit(to: 1).getDocuments() { (likesSnapshot, err) in
                                        if likesSnapshot!.isEmpty {
                                            reply.isLiked = false
                                            print("* user has not liked comment")
                                        } else {
                                            reply.isLiked = true
                                            print("* comment is liked!")
                                        }
                                        self.replies.append(reply)
                                        mainDispatch.leave()
                                    }
                                }
                                
                                
                            }
                            
                            if snapshot.isEmpty == true || snapshot.documents.isEmpty == true {
                                print("* reached end of replies")
                                self.hasReachedEndOfReplies = true
                            }
                            mainDispatch.notify(queue: .main) {
                                print("* fetched \(self.replies.count) replies")
                                self.replies = self.replies.removeDuplicates() // remove duplicate comments
                                self.repliesTableView.reloadData()
                                if self.hasDoneInitialReplyFetch == false {
                                    self.repliesTableView.fadeIn()
                                }
                                
                                self.repliesTableView.frame = CGRect(x: self.copyView.frame.minX, y: self.copyView.frame.maxY, width: self.copyView.frame.width, height: self.commentsTableView.frame.height - self.copyView.frame.maxY)
                                self.hasDoneInitialReplyFetch = true
                            }
                            
                        }
                    }
                }
            }
            
            
        }
        
    }
}
class EmojiHolderCell: UICollectionViewCell {
    @IBOutlet weak var emojiLabel: UILabel!
    
    func styleCell() {
        emojiLabel.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
    }
}
class CommentSectionPopup: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    // DUPLICATE VIEW CODE
    @IBOutlet weak var copyView: UIView!
    @IBOutlet weak var profilePicImage: UIImageView!
    @IBOutlet weak var usernameButton: UIButton!
    
    @IBOutlet weak var actualCommentLabel: VerticalAlignLabel!
    @IBOutlet weak var timeSincePostedLabel: UILabel!
    @IBOutlet weak var arrowImage: UIImageView!
    
    @IBOutlet weak var bottomGrayView: UIView!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var likesCountLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    @IBOutlet weak var flagButton: UIButton!
    var tappedComment: commentStruct? = nil
    var OGCopyViewRect: CGRect?
    var replies = [CommentReply]()
    
    var repliesQuery: Query!
    var repliesDocuments = [QueryDocumentSnapshot]()
    var hasReachedEndOfReplies = false
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiList?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojicell", for: indexPath) as! EmojiHolderCell
        cell.styleCell()
        cell.emojiLabel.text = emojiList?[indexPath.row] ?? ""
        return cell
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 30, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
                        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        postButton.isUserInteractionEnabled = true
        postButton.alpha = 1
        self.commentTextField.text! += emojiList?[indexPath.row] ?? ""
    }
    
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var repliesTableView: UITableView!
    @IBOutlet weak var emojiCollectionView: UICollectionView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var bottomWhiteView: UIView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var postButton: UIButton!
    
    @IBOutlet weak var dimmedView: UIButton!
    
    private var db = Firestore.firestore()
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == commentsTableView {
            return comments.count
        } else {
            return replies.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == commentsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newCommentCell", for: indexPath) as! CommentSectionTableViewCell
            cell.selectionStyle = .none
            cell.delegate = self
            let comment = comments[indexPath.row]
            cell.actualComment = comment
            cell.commentID = comment.commentID
            cell.originalPostAuthorID = originalPostAuthorID
            cell.originalPostID = originalPostID
            cell.userID = comment.authorID
            cell.parentVC = self
            cell.index = indexPath.row
            if highlightCommentUID != "" && indexPath.row == 0 {
                print("* highlighting comment!")
                cell.shouldHighlight = true
                
            } else {
                cell.shouldHighlight = false
            }
            //        cell.styleCell()
            return cell
        } else {
            // replies tableView
            let cell = tableView.dequeueReusableCell(withIdentifier: "replyCell", for: indexPath) as! ReplyTableViewCell
            cell.selectionStyle = .none
            let reply = replies[indexPath.row]
            cell.originalPostID = actualPost.postID
            cell.originalPostAuthorID = actualPost.userID
            if let tappedComment = tappedComment {
                cell.actualComment = tappedComment
            }
            cell.index = indexPath.row
            cell.reply = reply
            if indexPath.row == 0 && replyToOpen != "" && reply.replyID == replyToOpen {
                cell.shouldHighlight = true
            } else {
                cell.shouldHighlight = false
            }
            cell.styleCell()
            
            return cell
        }
        
        
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Trigger pagination when scrolled to last cell
        // Feel free to adjust when you want pagination to be triggered
        if tableView == commentsTableView {
            if (indexPath.row == comments.count - 1) && hasReachedEndOfComments == false {
                
                print("* fetching more comments. Current comment count: \(comments.count-1)")
                paginate()
            }
        } else if tableView == repliesTableView {
            if (indexPath.row == replies.count - 1) && hasReachedEndOfReplies == false {
                print("* fetching more replies?")
                paginateReplies()
            }
        }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == commentsTableView {
            let expectedLabelHeight = comments[indexPath.row].commentText.height(withConstrainedWidth: UIScreen.main.bounds.width - 15 - 40 - 10 - 25, font: UIFont(name: Constants.globalFont, size: 14)!)
            print("* [\(indexPath.row)] calculated expected height \(expectedLabelHeight)")
            var calculatedHeight = expectedLabelHeight + 50 + 30 + 20
            if expectedLabelHeight > 40 {
                calculatedHeight += 10
            }
            calculatedHeight -= 10
            calculatedHeight -= 5
            print("* [\(indexPath.row)] final height \(calculatedHeight)")
            return calculatedHeight ?? 120
        } else {
            var expectedLabelHeight = replies[indexPath.row].replyText.height(withConstrainedWidth: self.repliesTableView.frame.width - 10 - 80, font: UIFont(name: Constants.globalFont, size: 14)!)
            expectedLabelHeight += 15
            return 40 + expectedLabelHeight
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("* selected row?")
        if tableView == repliesTableView {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
            if commentTextField.text == "" {
                commentTextField.text = "@\(replies[indexPath.row].authorUserName)"
            } else {
                commentTextField.text = "\(commentTextField.text ?? "") @\(replies[indexPath.row].authorUserName)"
            }
            commentTextField.becomeFirstResponder()
        } else if tableView == commentsTableView {
            let cell = tableView.cellForRow(at: indexPath)
            if let cell = cell as? CommentSectionTableViewCell {
                singleTapDetected(in: cell)
            }
            
        }
    }
    var actualPost = imagePost()
    
    var comments: [commentStruct] = []
    
    var originalBottomY = 0
    var originalPostID = ""
    var originalPostAuthorID = ""
    
    var currentUserUsername = ""
    var currentUserProfilePic = ""
    var highlightCommentUID = "" // when opening comment from notifications page
    var replyToOpen = "" // should open specific reply?
    
    var hasReachedEndOfComments = false
    var hasDoneInitialFetch = false
    
    var hasDoneInitialReplyFetch = false
    
    var emojiList: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.backgroundColor.hexToUiColor()
        commentsTableView.dataSource = self
        commentsTableView.delegate = self
        repliesTableView.dataSource = self
        repliesTableView.delegate = self
        repliesTableView.showsVerticalScrollIndicator = false
        repliesTableView.alwaysBounceVertical = false
        repliesTableView.separatorStyle = .none
        repliesTableView.allowsSelection = true
        repliesTableView.isUserInteractionEnabled = true
        
        emojiCollectionView.dataSource = self
        emojiCollectionView.delegate = self
        commentsTableView.showsVerticalScrollIndicator = false
        emojiCollectionView.showsHorizontalScrollIndicator = false
        commentsTableView.alwaysBounceVertical = false
//        commentsTableView.bounces = false
        styleUI()
        
        
        print("* fetching comments from posts/\(actualPost.userID)/posts/\(actualPost.postID)/comments")
        Analytics.logEvent("load_comment_section", parameters: [
            "postAuthor": originalPostAuthorID,
            "postId": originalPostID,
            "currentUID": (Auth.auth().currentUser?.uid)!
        ])
        query = db.collection("posts").document(actualPost.userID).collection("posts").document(actualPost.postID).collection("comments")
            .order(by: "likes_count", descending: true)
            .order(by: "createdAt", descending: false)
            .limit(to: 10)
        if let prefs = UserDefaults(suiteName: "com.apple.EmojiPreferences") {
            if let defaults = prefs.dictionary(forKey: "EMFDefaultsKey"){
                if let recents = defaults["EMFRecentsKey"] as? [String]{
                    emojiList = recents
                    print("* got recent emojis: \(recents)")
                    emojiCollectionView.reloadData()
                } else {
                    //                        makeBottomSmaller()
                }
            } else {
                //                    makeBottomSmaller()
            }
        } else {
            //                makeBottomSmaller()
        }
        if highlightCommentUID == "" {
            fetchComments()
        } else {
            print("* fetching highlight comment from posts/\(actualPost.userID)/posts/\(actualPost.postID)/comments/\(highlightCommentUID)")
            self.db.collection("posts").document(actualPost.userID).collection("posts").document(actualPost.postID).collection("comments").document(highlightCommentUID).getDocument { (result, error) in
                if result?.exists != nil && result?.exists == true {
                    let data = result?.data() as? [String: Any] ?? [:]
                    //Setup your data model
                    var postItem = commentStruct()
                    postItem.authorID = data["authorID"] as? String ?? ""
                    postItem.authorProfilePic = data["authorProfilePic"] as? String ?? ""
                    postItem.authorUserName = data["authorUserName"] as? String ?? ""
                    let commID = data["uid"] as? String ?? ""
                    postItem.commentID = commID
                    postItem.commentText = data["commentText"] as? String ?? ""
                    postItem.createdAt = data["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                    postItem.numberOfReplies = data["replies_count"] as? Int ?? 0
                    postItem.numberOfLikes = data["likes_count"] as? Int ?? 0
                    print("* checking posts/\(self.actualPost.userID)/posts/\(self.actualPost.postID)/comments/\(commID)/likes/\(Auth.auth().currentUser?.uid ?? "")")
                    self.db.collection("posts").document(self.actualPost.userID).collection("posts").document(self.actualPost.postID).collection("comments").document(commID).collection("likes").whereField("uid", isEqualTo: Auth.auth().currentUser?.uid ?? "").limit(to: 1).getDocuments() { (likesSnapshot, err) in
                        if likesSnapshot!.isEmpty {
                            postItem.isLiked = false
                            print("* user has not liked comment")
                        } else {
                            postItem.isLiked = true
                            print("* comment is liked!")
                        }
                        self.comments += [postItem]
                        
                        self.fetchComments()
                        
                        
                    }
//                    self.documents += [result]
                } else {
                    print("* looks like comment not longer exists")
                    self.fetchComments()
                }
               
            }
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.copyViewTapp))
        copyView.addGestureRecognizer(gesture)

        // set textfield delegate
        commentTextField.delegate = self
        postButton.isUserInteractionEnabled = false
       postButton.alpha = 0.5
        self.db.collection("user-locations").document(Auth.auth().currentUser!.uid).getDocument() {(currentUserResult, err4) in
            let currentuserVals = currentUserResult?.data() as? [String: Any]
            self.currentUserUsername = currentuserVals?["username"] as? String ?? ""
            self.currentUserProfilePic = currentuserVals?["profileImageURL"] as? String ?? ""
        }
    }
    // textfield delegate for change text
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == commentTextField {
            if string == "" {
                if textField.text?.count == 1 {
                     postButton.isUserInteractionEnabled = false
                    postButton.alpha = 0.5
                }
            } else {
                postButton.isUserInteractionEnabled = true
                postButton.alpha = 1
                // check if current location where editing is within the @ symbol
                let currentLocation = textField.offset(from: textField.beginningOfDocument, to: textField.selectedTextRange!.start)
                let text: NSString = textField.text as? NSString ?? ""
                let textBeforeCursor = text.substring(to: currentLocation)
                let textAfterCursor = text.substring(from: currentLocation)
//                print("* before: \(textBeforeCursor), after: \(textAfterCursor)")
                

            }
        }
        return true
    }

    func makeBottomSmaller() {
        bottomWhiteView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 150 - 90, width: UIScreen.main.bounds.width, height: 140)
        commentTextField.frame = CGRect(x: 15, y: 20, width: UIScreen.main.bounds.width - 30, height: 50)
        
        let postButtonWidth = 60
        
        let postButtonPadd = 10
        let newWidth = Int(commentTextField.frame.minY) - (2*postButtonPadd)
        postButton.frame = CGRect(x: Int(commentTextField.frame.maxX) - newWidth - postButtonPadd, y: Int(commentTextField.frame.minY)+postButtonPadd, width: newWidth, height: newWidth)
    }
    func styleUI() {
        Analytics.logEvent("loaded_comment_section", parameters: nil)
        commentsTableView.backgroundColor = .clear
        commentsTableView.alwaysBounceVertical = false
        commentsTableView.separatorStyle = .none
        
        let clsoeWidth = 30
        let closeXY = 15
        closeButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - closeXY - clsoeWidth, y: closeXY, width: clsoeWidth, height: clsoeWidth)
        closeButton.layer.cornerRadius = CGFloat(clsoeWidth / 2)
        let closeImage = UIImage(systemName: "xmark")?.applyingSymbolConfiguration(.init(pointSize: 11, weight: .regular, scale: .small))?.image(withTintColor: "#828282".hexToUiColor())
        closeButton.setImage(closeImage, for: .normal)
        closeButton.backgroundColor = "#dcdcdc".hexToUiColor().withAlphaComponent(0.6)
        closeButton.clipsToBounds = true
        closeButton.setTitle("", for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
        
        commentsLabel.text = "\(actualPost.commentCount.delimiter) Comments"
        commentsLabel.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 25)
        commentsLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        commentsLabel.textColor = .darkGray
        commentsLabel.textAlignment = .center
        
        commentsTableView.keyboardDismissMode = .onDrag
        commentsTableView.separatorStyle = .none
        gradientView.frame = CGRect(x: 0, y: commentsLabel.frame.maxY + 10, width: UIScreen.main.bounds.width, height: 30)
        
        
        bottomWhiteView.backgroundColor = Constants.surfaceColor.hexToUiColor()
        bottomWhiteView.layer.cornerRadius = Constants.borderRadius
        bottomWhiteView.clipsToBounds = true
        bottomWhiteView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 150 - 110, width: UIScreen.main.bounds.width, height: 190)
        originalBottomY = Int(bottomWhiteView.frame.minY)
        self.bottomWhiteView.layer.masksToBounds = false
        self.bottomWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.bottomWhiteView.layer.shadowOffset = CGSize(width: 0, height: -5)
        self.bottomWhiteView.layer.shadowOpacity = 0.3
        self.bottomWhiteView.layer.shadowRadius = Constants.borderRadius
        
        commentsTableView.frame = CGRect(x: 0, y: commentsLabel.frame.maxY + 15, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 100 - commentsLabel.frame.maxY - 15 - 140 - 20)
        commentsTableView.isHidden = true
        
        // call the 'keyboardWillShow' function when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self, selector: #selector(CommentSectionPopup.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // call the 'keyboardWillHide' function when the view controlelr receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self, selector: #selector(CommentSectionPopup.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        styleCommentStuff()
        if Constants.isDebugEnabled {
            //            var window : UIWindow = UIApplication.shared.keyWindow!
            //            window.showDebugMenu()
            self.view.debuggingStyle = true
        }
        dimmedView.backgroundColor = .black.withAlphaComponent(0.2)
        dimmedView.isUserInteractionEnabled = true
        dimmedView.setTitle("", for: .normal)
        dimmedView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
    func makeCarbonCopyOfCell(cell: CommentSectionTableViewCell) {
        
    }
    func styleCommentStuff() {
        emojiCollectionView.frame = CGRect(x: 20, y: 10, width: UIScreen.main.bounds.width - 40, height: 30)
        emojiCollectionView.delegate = self
        emojiCollectionView.dataSource = self
        
        commentTextField.placeholder = "Comment on \(actualPost.username)'s post" // OR "Reply to username's comment" for comment replies
        commentTextField.styleSearchBar()
        commentTextField.backgroundColor = Constants.backgroundColor.hexToUiColor()
        commentTextField.frame = CGRect(x: 15, y: 50, width: UIScreen.main.bounds.width - 30, height: 50)
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        commentTextField.leftView = paddingView
        commentTextField.leftViewMode = .always
        
        let postButtonWidth = 60
        
        let postButtonPadd = 10
        let newWidth = Int(commentTextField.frame.minY) - (2*postButtonPadd)
        postButton.frame = CGRect(x: Int(commentTextField.frame.maxX) - newWidth - postButtonPadd, y: Int(commentTextField.frame.minY)+postButtonPadd, width: newWidth, height: newWidth)
        postButton.setTitle("", for: .normal)
        postButton.backgroundColor = Constants.secondaryColor.hexToUiColor()
        postButton.tintColor = Constants.primaryColor.hexToUiColor()
        postButton.layer.cornerRadius = 12
    }
    
    @IBAction func dimmedViewTapped(_ sender: Any) {
        print("* dimmed view tapped")
        self.dismissKeyboard()
        self.dimmedView.fadeOut()
    }
    @IBAction func postButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let postsRef = db.collection("posts")
        let timestamp = NSDate().timeIntervalSince1970
        //        let value: Double = 1
        //        let incr = FieldValue.increment(value)
        //        postsRef.document(originalPostAuthorID).collection("posts").document(originalPostID).updateData(["comments_count":incr])
        if ((commentTextField.placeholder?.contains("Reply")) != nil && (commentTextField.placeholder?.contains("Reply") == true)) {
            let replyRef = postsRef.document(actualPost.userID).collection("posts").document(actualPost.postID).collection("comments").document(tappedComment!.commentID).collection("comment_replies").document()
            let submitData: [String: Any] = [
                "commentText":tappedComment?.commentText as? String ?? "",
                "username":tappedComment?.authorUserName as? String ?? "",
                "profilePicture":tappedComment?.authorProfilePic as? String ?? "",
                "authorID":(Auth.auth().currentUser?.uid)!,
                "timestamp": timestamp,
                "commentID": tappedComment?.commentID as? String ?? "",
                "replyID": replyRef.documentID,
                "authorUserName": currentUserUsername,
                "authorProfilePic": currentUserProfilePic,
                "replyText": commentTextField.text as? String ?? "",
                "likes_count": 0
            ]
            Analytics.logEvent("comment_reply_made", parameters: nil)
            print("* submitting reply: \(submitData)")
            replyRef.setData(submitData, merge: true) { err in
                if err == nil {
                    print("* successfully replied to comment")
                    self.replies.insert(CommentReply(data: submitData), at: 0)
                    self.repliesTableView.beginUpdates()
                    self.repliesTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    self.repliesTableView.endUpdates()
                    self.commentTextField.text = ""
                    self.dismissKeyboard()
                }
            }
        } else {
            let commentRef = postsRef.document(actualPost.userID).collection("posts").document(actualPost.postID).collection("comments").document()
            let userID : String = (Auth.auth().currentUser?.uid)!
            print("* pushing comment:")
            print("  |_ uid = \(commentRef.documentID)")
            print("  |_ authorID = \(userID)")
            print("  |_ commentText = \(commentTextField.text ?? "")")
            print("  |_ createdAt = \(Int(timestamp))")
            print("  |_ authorProfilePic = \(self.currentUserProfilePic)")
            print("  |_ authorUserName = \(self.currentUserUsername)")
            print("  |_ replies_count = 0")
            print("  |_ likes_count = 0")
            Analytics.logEvent("new_comment", parameters: nil)
            commentRef.setData([
                "uid": "\(commentRef.documentID)",
                "authorID": "\(userID)",
                "commentText": "\(commentTextField.text ?? "")",
                "createdAt": Int(timestamp),
                "authorProfilePic": "\(self.currentUserProfilePic)",
                "authorUserName": "\(self.currentUserUsername)",
                "replies_count": 0,
                "likes_count": 0
            ], merge: true) { err in
                if err == nil {
                    print("* successfully commented on post")
                    self.dismissKeyboard()
                    var newComment = commentStruct()
                    newComment.authorID = userID
                    newComment.commentID = commentRef.documentID
                    newComment.commentText = "\(self.commentTextField.text ?? "")"
                    newComment.createdAt = Double(Int(timestamp))
                    newComment.authorProfilePic = "\(self.currentUserProfilePic)"
                    newComment.authorUserName = "\(self.currentUserUsername)"
                    newComment.numberOfReplies = 0
                    newComment.numberOfLikes = 0
                    
                    self.commentTextField.text = ""
                    self.comments.insert(newComment, at: 0)
                    self.commentsTableView.beginUpdates()
                    self.commentsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    self.commentsTableView.endUpdates()
                    if self.comments.count == 1 {
                        self.commentsTableView.fadeIn()
                    }
                } else {
                    print("* looks like there was an error posting comment: \(err)")
                    //                let value: Double = -1
                    //                let incr = FieldValue.increment(value)
                    //                postsRef.document(self.originalPostAuthorID).collection("posts").document(self.originalPostID).updateData(["comments_count":incr])
                }
                
                
                
                
            }
        }
        
    }
    func fetchComments() {
        print("* fetch comments called")
        query.getDocuments() { (querySnapshot, err) in
            let mainCommentsDispatchGroup = DispatchGroup()
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                querySnapshot!.documents.forEach({ (document) in
                    let data = document.data() as [String: AnyObject]
                    
                    //Setup your data model
                    var postItem = commentStruct()
                    postItem.authorID = data["authorID"] as? String ?? ""
                    postItem.authorProfilePic = data["authorProfilePic"] as? String ?? ""
                    postItem.authorUserName = data["authorUserName"] as? String ?? ""
                    let commID = data["uid"] as? String ?? ""
                    postItem.commentID = commID
                    postItem.commentText = data["commentText"] as? String ?? ""
                    postItem.createdAt = data["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
                    postItem.numberOfReplies = data["replies_count"] as? Int ?? 0
                    postItem.numberOfLikes = data["likes_count"] as? Int ?? 0
                    mainCommentsDispatchGroup.enter()
                    print("* checking posts/\(self.actualPost.userID)/posts/\(self.actualPost.postID)/comments/\(commID)/likes/\(Auth.auth().currentUser?.uid ?? "")")
                    self.db.collection("posts").document(self.actualPost.userID).collection("posts").document(self.actualPost.postID).collection("comments").document(commID).collection("likes").whereField("uid", isEqualTo: Auth.auth().currentUser?.uid ?? "").limit(to: 1).getDocuments() { (likesSnapshot, err) in
                        if ((likesSnapshot?.isEmpty) ?? true == true) {
                            postItem.isLiked = false
                            print("* user has not liked comment")
                        } else {
                            postItem.isLiked = true
                            print("* comment is liked!")
                        }
                        self.comments += [postItem]
                        
                        mainCommentsDispatchGroup.leave()
                        
                        
                    }
                    self.documents += [document]
                    
                })
                if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                    
                    self.hasReachedEndOfComments = true
                }
                
            }
            mainCommentsDispatchGroup.notify(queue: .main) {
                if self.highlightCommentUID == "" {
                    self.comments = self.comments.sorted (by: {$0.numberOfLikes > $1.numberOfLikes}) // only sort when not highlighting comment
                }
                
                self.comments = self.comments.removeDuplicates() // remove duplicate comments
                print("* got done working on tasks -- reloading")
                if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                    print("* looks like we've reached the end of comments collection")
                    self.hasReachedEndOfComments = true
                } else {
                    DispatchQueue.main.async {
                        self.commentsTableView.reloadData()
                        if self.hasDoneInitialFetch == false {
                            self.hasDoneInitialFetch = true
                            self.commentsTableView.fadeIn()
                            self.fetchReplies()
                            if self.replyToOpen != "" {
                                print("* we got a reply, opening table view")
                                let seconds = 0.3
                                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
//                                    // Put your code which should be executed with a delay here
////                                    self.commentsTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
                                    let indexPath = IndexPath(row: 0, section: 0)
                                    self.commentsTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                                    self.commentsTableView.delegate?.tableView!(self.commentsTableView, didSelectRowAt: indexPath)
                                }

                            }
                        }
                    }
                }
                
            }
        }
        
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }
        
        // move the root view up by the distance of keyboard height
        self.bottomWhiteView.frame.origin.y = CGFloat(originalBottomY) - keyboardSize.height
        dimmedView.fadeIn()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        // move back the root view origin to zero
        self.bottomWhiteView.frame.origin.y = CGFloat(originalBottomY)
        dimmedView.fadeOut()
    }
    func paginate() {
        //This line is the main pagination code.
        //Firestore allows you to fetch document from the last queryDocument
        query = query.start(afterDocument: documents.last!).limit(to: 4)
        fetchComments()
    }
    func paginateReplies() {
        //This line is the main pagination code.
        //Firestore allows you to fetch document from the last queryDocument
        if hasDoneInitialReplyFetch == true {
            repliesQuery = repliesQuery.start(afterDocument: repliesDocuments.last!).limit(to: 4)
            fetchReplies()
        }
        
    }
    @objc internal func closeButtonPressed(_ button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        self.dismiss(animated: true)
    }
}
extension CommentSectionPopup: PanModalPresentable {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var longFormHeight: PanModalHeight {
        let actualHeight = 750
        
        return .maxHeightWithTopInset(50)
    }
    
    var anchorModalToLongForm: Bool {
        return false
    }
}
extension UIImage {

    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat.pi)
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat.pi
        }

        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size

        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)

        //   // Rotate the image context
        bitmap?.rotate(by: degreesToRadians(degrees))

        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat

        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }

        bitmap?.scaleBy(x: yFlip, y: -1.0)
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)

        bitmap?.draw(cgImage!, in: rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}
extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
extension String {
    func componentSeparate(by: String) -> [String] {
        var out: [String] = [String]()
        var storeStr = ""
        for str in Array(self) {
            if by.contains(str) {
                out.append(storeStr)
                storeStr.removeAll()
                continue
            }
            storeStr.append(str)
        }
        return out
    }
    
    func componentSeparated1(by: String) -> [String] {
        var separateList: [String] = componentSeparate(by: by).map { "\($0)\(by)" }
        separateList[separateList.count-1].removeLast(by.count)
        return separateList
    }
    
    func componentSeparated2(by: String) -> [String] {
        if self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }
        var separateList: [String] = componentSeparate(by: by).map { "\($0)\(by)" }
        separateList[separateList.count-1].removeLast(by.count)
        return separateList
    }
    
    func componentSeparated3(by: String) -> [String] {
        if self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }
        var separateList: [String] = componentSeparate(by: by).map {"\($0)\(by)"}.filter {$0 != "-"}
        separateList[separateList.count-1].removeLast(by.count)
        return separateList
    }
    
    func componentSeparated4(by: String) -> [String] {
        if self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [] }
        let separateList: [String] = componentSeparate(by: by).map {"\($0)\(by)"}.filter {$0 != "-"}
        return separateList
    }
}
