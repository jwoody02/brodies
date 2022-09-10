//
//  NotificationsViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 5/15/22.
//

import UIKit
import Foundation
import SwiftKeychainWrapper
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics

class NotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let noti = notifications[indexPath.row]
        if let notification = noti as? FollowNotification {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FollowNotifCell", for: indexPath) as! NewFollowercell
            print("* making new follower cell")
            cell.parentViewController = self
            cell.styleCellFor(notification: notification, index: indexPath.row)
            cell.selectionStyle = .none
            return cell
        } else if let notification = noti as? LikedPostNotification {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewLikesCell", for: indexPath) as! NewLikeCell
            print("* making post like cell")
            cell.parentViewController = self
            cell.styleCellFor(notification: notification, index: indexPath.row)
            cell.selectionStyle = .none
            return cell
        } else if let notification = noti as? likedCommentNotif {
            let cell = tableView.dequeueReusableCell(withIdentifier: "commLIkedCell", for: indexPath) as! CommentLikedCell
            print("making comm liked cell: \(notification.comment)")
            cell.parentViewController = self
            cell.styleCellFor(notification: notification, index: indexPath.row)
            cell.selectionStyle = .none
            return cell
        } else if let notification = noti as? ReplyMadeNotification {
            let cell = tableView.dequeueReusableCell(withIdentifier: "newcommentReply", for: indexPath) as! ReplyMadeCell
            cell.parentViewController = self
            cell.styleCellFor(notification: notification, index: indexPath.row)
            cell.selectionStyle = .none
            return cell
        } else if let notification = noti as? likedReplyNotif {
            let cell = tableView.dequeueReusableCell(withIdentifier: "replyLiked", for: indexPath) as! ReplyLikedCell
            cell.parentViewController = self
            cell.styleCellFor(notification: notification, index: indexPath.row)
            cell.selectionStyle = .none
            return cell
        } else if let notification = noti as? ReqFollowNotif {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FLWRequestcell", for: indexPath) as! RequestFollowCell
            print("* making new follower cell")
            cell.parentViewController = self
            cell.styleCellFor(notification: notification, index: indexPath.row)
            cell.selectionStyle = .none
            return cell
        } else {
            // later put this in else statement
            let notification = noti as! CommentMadeNotification
            print("* MAKING CELL WITH COMMENT: \(notification)")
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCommentCell", for: indexPath) as! NewCommentCell
            cell.parentViewController = self
            cell.styleCellFor(notification: notification, index: indexPath.row)
            cell.selectionStyle = .none
            return cell
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var noti = self.notifications[indexPath.row]
        if let _ = noti as? FollowNotification {
            return 90
        } else if let _ = noti as? LikedPostNotification {
            return 90
        } else if let _ = noti as? likedCommentNotif {
            return 90
            
        } else if let _ = noti as? ReqFollowNotif {
            return 90
            
        } else {
            if let notif = noti as? CommentMadeNotification {
                let profWid = 48
                let profXY = Int(16)
                let titleWidths = Int(Int(UIScreen.main.bounds.width - 30) - profXY - profWid - 30 - 50)
                let heightForComment = (notif.comment as? String ?? "").height(withConstrainedWidth: CGFloat(titleWidths), font: UIFont(name: "\(Constants.globalFont)", size: 13)!)
                if heightForComment < 28 {
                    return 90
                } else {
                    return heightForComment + 50 + 30
                }
            } else if let notif = noti as? ReplyMadeNotification {
                let profWid = 48
                let profXY = Int(16)
                let titleWidths = Int(Int(UIScreen.main.bounds.width - 30) - profXY - profWid - 30 - 50)
                let heightForComment = (notif.reply as? String ?? "").height(withConstrainedWidth: CGFloat(titleWidths), font: UIFont(name: "\(Constants.globalFont)", size: 13)!)
                if heightForComment < 28 {
                    return 90
                } else {
                    return heightForComment + 50 + 30
                }
            } else if let notif = noti as? likedReplyNotif {
                let profWid = 48
                let profXY = Int(16)
                let titleWidths = Int(Int(UIScreen.main.bounds.width - 30) - profXY - profWid - 30 - 50)
                let heightForComment = (notif.originalReply as? String ?? "").height(withConstrainedWidth: CGFloat(titleWidths), font: UIFont(name: "\(Constants.globalFont)", size: 13)!)
                if heightForComment < 28 {
                    return 90
                } else {
                    return heightForComment + 50 + 30
                }
            } else {
                return 0
            }
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userID = (Auth.auth().currentUser?.uid)!
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if let notification = self.notifications[indexPath.row] as? LikedPostNotification {
            let nav = self.navigationController
            if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                print("* presenting post")
                //                vc.currentIndex = indexPath.row
                vc.currentIndex = 0
                vc.username = self.currentUsername
                vc.hasValidStory = self.hasValidStory
                vc.imageUrl = self.currentProfilePic
                vc.isFollowing = false
                let imagePostz = notification.currentPost
                vc.imagePosts = [imagePostz!] // only load in one post
                
                vc.profileUID = userID
                nav?.pushViewController(vc, animated: true)
            }
            
        } else if let notification = self.notifications[indexPath.row] as? FollowNotification {
            openProfileForUser(withUID: notification.uid)
        } else if let notification = self.notifications[indexPath.row] as? ReqFollowNotif {
            openProfileForUser(withUID: notification.uid)
        } else if let notification = self.notifications[indexPath.row] as? likedCommentNotif {
            let nav = self.navigationController
            if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                print("* presenting post")
                let imagePostz = notification.currentPost
                vc.currentIndex = 0
                vc.username = imagePostz!.username
                vc.hasValidStory = imagePostz!.hasValidStory
                vc.imageUrl = imagePostz!.userImageUrl
                vc.shouldOpenCommentSection = true
                vc.commentToOpen = notification.commentId
                vc.isFollowing = false
                vc.shouldHideFollowbutton = true
                
                vc.imagePosts = [imagePostz!] // only load in one post
                vc.profileUID = imagePostz!.userID
                nav?.pushViewController(vc, animated: true)
            }
            
        }
        else if let notification = self.notifications[indexPath.row] as? CommentMadeNotification {
            let nav = self.navigationController
            if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                print("* presenting post")
                vc.currentIndex = 0
                vc.username = self.currentUsername
                vc.hasValidStory = self.hasValidStory
                vc.imageUrl = self.currentProfilePic
                vc.shouldOpenCommentSection = true
                vc.commentToOpen = notification.commentId
                vc.isFollowing = false
                let imagePostz = notification.currentPost
                vc.imagePosts = [imagePostz!] // only load in one post
                vc.profileUID = userID
                nav?.pushViewController(vc, animated: true)
            }
        } else if let notification = self.notifications[indexPath.row] as? ReplyMadeNotification {
            let nav = self.navigationController
            if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                print("* presenting post")
                vc.currentIndex = 0
                vc.username = self.currentUsername
                vc.hasValidStory = self.hasValidStory
                vc.imageUrl = self.currentProfilePic
                vc.shouldOpenCommentSection = true
                vc.commentToOpen = notification.commentId
                vc.isFollowing = false
                let imagePostz = notification.currentPost
                vc.imagePosts = [imagePostz!] // only load in one post
                vc.profileUID = userID
                vc.replyToOpen = notification.replyId
                nav?.pushViewController(vc, animated: true)
            }
        } else if let notification = self.notifications[indexPath.row] as? likedReplyNotif {
            let nav = self.navigationController
            if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                print("* presenting post")
                vc.currentIndex = 0
                vc.username = self.currentUsername
                vc.hasValidStory = self.hasValidStory
                vc.imageUrl = self.currentProfilePic
                vc.shouldOpenCommentSection = true
                vc.commentToOpen = notification.commentId
                vc.isFollowing = false
                let imagePostz = notification.currentPost
                vc.imagePosts = [imagePostz!] // only load in one post
                vc.profileUID = userID
                vc.replyToOpen = notification.replyId
                nav?.pushViewController(vc, animated: true)
            }
        }
    }
    let defaults = UserDefaults.standard
    private var db = Firestore.firestore()
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    var notifications: [AnyObject] = []
    var hasReachedEndOfFeed = false
    var hasDoneinitialFetch = false
    var hasDoneinitialFetchForSearch = false
    var currentUsername = ""
    var hasValidStory = false
    var currentProfilePic = ""
    var currentlyLoadingStuff = false
    
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var activityLabel: UILabel!
    
    @IBOutlet weak var allNotificationsButton: UIButton!
    @IBOutlet weak var allNotifNumberLabel: PaddingLabel!
    
    @IBOutlet weak var likesNotificationsButton: UIButton!
    @IBOutlet weak var likesNotifNumberLabel: PaddingLabel!
    
    @IBOutlet weak var commentsNotificationsButton: UIButton!
    @IBOutlet weak var commentsNotifNumberLabel: PaddingLabel!
    
    @IBOutlet weak var mentionsNotificationsButton: UIButton!
    @IBOutlet weak var mentionsNotifNumberLabel: PaddingLabel!
    
    @IBOutlet weak var followersNotificationsButton: UIButton!
    @IBOutlet weak var followersNotifNumberLabel: PaddingLabel!
    
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var gradientView: UIView!
    
    var veryFirstNotificationUID = ""
    
    var notificationsSettings : [String: UIMenuElement.State] = ["likes_enabled" : UIMenuElement.State.on, "comments_enabled":UIMenuElement.State.on, "followers_enabled":UIMenuElement.State.on, "mentions_enabled":UIMenuElement.State.on]
    //    var query: Query!
    //    var documents = [QueryDocumentSnapshot]()
    //    @IBOutlet weak var mentionsNotificationsButton: UIButton! // TBD
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        styleEverything()
        if Auth.auth().currentUser?.uid == nil {
            //            // show login view
            print("not valid user, pushing login")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        } else {
            let userID = (Auth.auth().currentUser?.uid)!
            db.collection("notifications").document(userID).getDocument {
                (document, error) in
                if let document = document, document.exists {
                    let data = document.data() as? [String: AnyObject]
                    let totalnotifications = data?["notifications_count"] as? Int ?? 0
                    let num_likes = data?["num_likes_notifications"] as? Int ?? 0
                    let num_comments = data?["num_comments_notifications"] as? Int ?? 0
                    let num_followers = data?["num_followers_notifications"] as? Int ?? 0
                    let num_mentions = data?["num_mentions_notifications"] as? Int ?? 0
                    
                    self.newLabel.text = "New (\(totalnotifications.delimiter))"
                    self.newLabel.isHidden = true
                    self.allNotifNumberLabel.text = totalnotifications.delimiter
                    self.likesNotifNumberLabel.text = num_likes.delimiter
                    self.commentsNotifNumberLabel.text = num_comments.delimiter
                    self.followersNotifNumberLabel.text = num_followers.delimiter
                    self.mentionsNotifNumberLabel.text = num_mentions.delimiter
                    
                    self.allNotifNumberLabel.sizeToFit()
                    self.allNotifNumberLabel.center.x = self.allNotificationsButton.center.x
                    self.allNotifNumberLabel.center.y = self.allNotificationsButton.frame.maxY
                    if totalnotifications != 0 {
                        self.allNotifNumberLabel.isHidden = false
                    }
                    
                    
                    self.likesNotifNumberLabel.sizeToFit()
                    self.likesNotifNumberLabel.center.x = self.likesNotificationsButton.center.x
                    self.likesNotifNumberLabel.center.y = self.likesNotificationsButton.frame.maxY
                    if num_likes != 0 {
                        self.likesNotifNumberLabel.isHidden = false
                    }
                    
                    self.commentsNotifNumberLabel.sizeToFit()
                    self.commentsNotifNumberLabel.center.x = self.commentsNotificationsButton.center.x
                    self.commentsNotifNumberLabel.center.y = self.commentsNotificationsButton.frame.maxY
                    if num_comments != 0 {
                        self.commentsNotifNumberLabel.isHidden = false
                    }
                    
                    self.followersNotifNumberLabel.sizeToFit()
                    self.followersNotifNumberLabel.center.x = self.followersNotificationsButton.center.x
                    self.followersNotifNumberLabel.center.y = self.followersNotificationsButton.frame.maxY
                    if num_followers != 0 {
                        self.followersNotifNumberLabel.isHidden = false
                    }
                    
                    self.mentionsNotifNumberLabel.sizeToFit()
                    self.mentionsNotifNumberLabel.center.x = self.mentionsNotificationsButton.center.x
                    self.mentionsNotifNumberLabel.center.y = self.mentionsNotificationsButton.frame.maxY
                    if num_mentions != 0 {
                        self.mentionsNotifNumberLabel.isHidden = false
                    }
                }
            }
            Analytics.logEvent("loaded_notifications", parameters: nil)
            query = db.collection("notifications").document(userID).collection("notifications").order(by: "timestamp", descending: true).limit(to: 10)
            handleMoreLoad()
        }
        usersTableView.delegate = self
        usersTableView.dataSource = self
        
        //        updatebasicInfo()
//        attemptToGetSystemNotification()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updatebasicInfo()
    }
    func attemptToGetSystemNotification() {
        let userID = (Auth.auth().currentUser?.uid)!
        let systemQuery = db.collection("notifications").document(userID).collection("notifications").whereField("type", isEqualTo: "system").order(by: "timestamp", descending: true).limit(to: 1)
        systemQuery.getDocuments() { (systemSnapchot, err) in
            print("* got system snapshot: \(systemSnapchot?.documents)")
            if systemSnapchot!.isEmpty || err != nil {
                print(err)
                print("* user has no recent system notifications")
            } else {
                print("* user has a recent system notification")
                print("* data: \(systemSnapchot?.documents.first)")
            }
        }
    }
    func updatebasicInfo() {
        let userID = (Auth.auth().currentUser?.uid)!
        print("* collecting data on uid: \(userID)")
        db.collection("user-locations").document(userID).getDocument() { [self] (document, error) in
            if let document = document {
                let data = document.data()! as [String: AnyObject]
                currentUsername = data["username"] as? String ?? ""
                var isValidStory = false
                if data["latest_story_timestamp"] != nil {
                    //                                    print("* user has a recent story: \(postVals?["latest_story_timestamp"])")
                    if let timestamp: Timestamp = data["latest_story_timestamp"] as? Timestamp {
                        let story_date: Date = timestamp.dateValue()
                        let timeToLive: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours
                        let isExpired = Date().timeIntervalSince(story_date) >= timeToLive
                        if isExpired != true {
                            print("* valid story!")
                            isValidStory = true
                        }
                    }
                    
                }
                hasValidStory = isValidStory
                currentProfilePic = data["profileImageURL"] as? String ?? ""
            }
        }
        db.collection("FCMTokens").document(userID).getDocument() { [self] (document, error) in
            if let document = document {
                if let data = document.data() as? [String: AnyObject] {
                    let likesEnabled = data["likes_enabled"] as? Bool ?? true
                    let commentsEnabled = data["comments_enabled"] as? Bool ?? true
                    let followersEnabled = data["followers_enabled"] as? Bool ?? true
                    let mentionsEnabled = data["mentions_enabled"] as? Bool ?? true
                    if likesEnabled == false {
                        notificationsSettings["likes_enabled"] = UIMenuElement.State.off
                    }
                    if commentsEnabled == false {
                        notificationsSettings["comments_enabled"] = UIMenuElement.State.off
                    }
                    if followersEnabled == false {
                        notificationsSettings["followers_enabled"] = UIMenuElement.State.off
                    }
                    if mentionsEnabled == false {
                        notificationsSettings["mentions_enabled"] = UIMenuElement.State.off
                    }
                    resetMenu()
                }
                
            }
        }
        
    }
    func resetMenu() {
        let userID = (Auth.auth().currentUser?.uid)!
        if #available(iOS 14.0, *) {
            let likesAction : UIAction = .init(title: "Likes", image: UIImage(systemName: "heart"), identifier: UIAction.Identifier.init(rawValue: "likes"), discoverabilityTitle: nil, attributes: .init(), state: notificationsSettings["likes_enabled"]!, handler: { (action) in
                print("* likes tapped")
                var newVal = true
                var newState = UIMenuElement.State.on
                if (self.notificationsSettings["likes_enabled"]) == UIMenuElement.State.on {
                    newVal = false
                    newState = UIMenuElement.State.off
                }
                self.db.collection("FCMTokens").document(userID).setData(["likes_enabled": newVal], merge: true)
                self.notificationsSettings["likes_enabled"] = newState
                self.resetMenu()
            })
            
            let commentsAction : UIAction = .init(title: "Comments", image: UIImage(systemName: "text.bubble"), identifier: UIAction.Identifier.init(rawValue: "comments"), discoverabilityTitle: nil, attributes: .init(), state: notificationsSettings["comments_enabled"]!, handler: { (action) in
                print("* comments tapped")
                var newVal = true
                var newState = UIMenuElement.State.on
                if (self.notificationsSettings["comments_enabled"]) == UIMenuElement.State.on {
                    newVal = false
                    newState = UIMenuElement.State.off
                }
                self.db.collection("FCMTokens").document(userID).setData(["comments_enabled": newVal], merge: true)
                self.notificationsSettings["comments_enabled"] = newState
                self.resetMenu()
            })
            let followsAction : UIAction = .init(title: "New Followers", image: UIImage(systemName: "person.badge.plus"), identifier: UIAction.Identifier.init(rawValue: "followers"), discoverabilityTitle: nil, attributes: .init(), state: notificationsSettings["followers_enabled"]!, handler: { (action) in
                print("* follows tapped")
                var newVal = true
                var newState = UIMenuElement.State.on
                if (self.notificationsSettings["followers_enabled"]) == UIMenuElement.State.on {
                    newVal = false
                    newState = UIMenuElement.State.off
                }
                self.db.collection("FCMTokens").document(userID).setData(["followers_enabled": newVal], merge: true)
                self.notificationsSettings["followers_enabled"] = newState
                self.resetMenu()
            })
            let mentionsAction : UIAction = .init(title: "Mentions", image: UIImage(systemName: "at"), identifier: UIAction.Identifier.init(rawValue: "mentions"), discoverabilityTitle: nil, attributes: .init(), state: notificationsSettings["mentions_enabled"]!, handler: { (action) in
                print("* mentions tapped")
                var newVal = true
                var newState = UIMenuElement.State.on
                if (self.notificationsSettings["mentions_enabled"]) == UIMenuElement.State.on {
                    newVal = false
                    newState = UIMenuElement.State.off
                }
                self.db.collection("FCMTokens").document(userID).setData(["mentions_enabled": newVal], merge: true)
                self.notificationsSettings["mentions_enabled"] = newState
                self.resetMenu()
            })
            let actions = [likesAction, commentsAction, followsAction, mentionsAction]
            
            let menu = UIMenu(title: "Push Notifications", image: UIImage(systemName: "bell"), identifier: nil, options: .displayInline, children: actions)
            //            settingsButton.showsMenuAsPrimaryAction = true
            //            settingsButton.menu = menu
        }
    }
    @IBAction func NotificationsSettingPressed(_ sender: Any) {
        let vc = NotificationsPOpup()
        self.navigationController?.presentPanModal(vc)
    }
    func resetAndGetNotifs() {
        self.notifications.removeAll()
        self.documents.removeAll()
        self.usersTableView.reloadData()
        self.hasReachedEndOfFeed = false
        self.hasDoneinitialFetch = false
        
        // self.query = query.start(at: nil) //reset query?
        handleMoreLoad()
    }
    @IBAction func AllActivityButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = (Auth.auth().currentUser?.uid)!
        query = db.collection("notifications").document(userID).collection("notifications").order(by: "timestamp", descending: true).limit(to: 10)
        styleAllForUnselected()
        allNotificationsButton.styleForSelectednotification()
        resetAndGetNotifs()
    }
    @IBAction func RefreshPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = (Auth.auth().currentUser?.uid)!
        query = db.collection("notifications").document(userID).collection("notifications").order(by: "timestamp", descending: true).limit(to: 10)
        styleAllForUnselected()
        allNotificationsButton.styleForSelectednotification()
        resetAndGetNotifs()
        db.collection("notifications").document(userID).getDocument {
            (document, error) in
            if let document = document, document.exists {
                let data = document.data() as? [String: AnyObject]
                let totalnotifications = data?["notifications_count"] as? Int ?? 0
                let num_likes = data?["num_likes_notifications"] as? Int ?? 0
                let num_comments = data?["num_comments_notifications"] as? Int ?? 0
                let num_followers = data?["num_followers_notifications"] as? Int ?? 0
                let num_mentions = data?["num_mentions_notifications"] as? Int ?? 0
                
                self.newLabel.text = "New (\(totalnotifications.delimiter))"
                self.newLabel.isHidden = true
                self.allNotifNumberLabel.text = totalnotifications.delimiter
                self.likesNotifNumberLabel.text = num_likes.delimiter
                self.commentsNotifNumberLabel.text = num_comments.delimiter
                self.followersNotifNumberLabel.text = num_followers.delimiter
                self.mentionsNotifNumberLabel.text = num_mentions.delimiter
                
                self.allNotifNumberLabel.sizeToFit()
                self.allNotifNumberLabel.center.x = self.allNotificationsButton.center.x
                self.allNotifNumberLabel.center.y = self.allNotificationsButton.frame.maxY
                if totalnotifications != 0 {
                    self.allNotifNumberLabel.isHidden = false
                }
                
                
                self.likesNotifNumberLabel.sizeToFit()
                self.likesNotifNumberLabel.center.x = self.likesNotificationsButton.center.x
                self.likesNotifNumberLabel.center.y = self.likesNotificationsButton.frame.maxY
                if num_likes != 0 {
                    self.likesNotifNumberLabel.isHidden = false
                }
                
                self.commentsNotifNumberLabel.sizeToFit()
                self.commentsNotifNumberLabel.center.x = self.commentsNotificationsButton.center.x
                self.commentsNotifNumberLabel.center.y = self.commentsNotificationsButton.frame.maxY
                if num_comments != 0 {
                    self.commentsNotifNumberLabel.isHidden = false
                }
                
                self.followersNotifNumberLabel.sizeToFit()
                self.followersNotifNumberLabel.center.x = self.followersNotificationsButton.center.x
                self.followersNotifNumberLabel.center.y = self.followersNotificationsButton.frame.maxY
                if num_followers != 0 {
                    self.followersNotifNumberLabel.isHidden = false
                }
                
                self.mentionsNotifNumberLabel.sizeToFit()
                self.mentionsNotifNumberLabel.center.x = self.mentionsNotificationsButton.center.x
                self.mentionsNotifNumberLabel.center.y = self.mentionsNotificationsButton.frame.maxY
                if num_mentions != 0 {
                    self.mentionsNotifNumberLabel.isHidden = false
                }
            }
        }
        Analytics.logEvent("refreshed_notifications", parameters: nil)
    }
    @IBAction func LikesButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = (Auth.auth().currentUser?.uid)!
        //        query = db.collection("notifications").document(userID).collection("notifications").whereField("type", isEqualTo: "liked_post").order(by: "timestamp", descending: true).limit(to: 10)
        query = db.collection("notifications").document(userID).collection("notifications").whereField("type", in: ["liked_post", "comment_liked", "reply_like"]).order(by: "timestamp", descending: true).limit(to: 10)
        styleAllForUnselected()
        likesNotificationsButton.styleForSelectednotification()
        resetAndGetNotifs()
    }
    @IBAction func CommentsButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = (Auth.auth().currentUser?.uid)!
        query = db.collection("notifications").document(userID).collection("notifications").whereField("type", in: ["comment_made", "comment_reply"]).order(by: "timestamp", descending: true).limit(to: 10)
        styleAllForUnselected()
        commentsNotificationsButton.styleForSelectednotification()
        resetAndGetNotifs()
    }
    @IBAction func FollowersButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = (Auth.auth().currentUser?.uid)!
        query = db.collection("notifications").document(userID).collection("notifications").whereField("type", in: ["began_following", "requested_to_follow"]).order(by: "timestamp", descending: true).limit(to: 10)
        styleAllForUnselected()
        followersNotificationsButton.styleForSelectednotification()
        resetAndGetNotifs()
    }
    func styleEverything() {
        self.usersTableView.isHidden = false
        self.usersTableView.alpha = 1
        self.newLabel.isHidden = true
        activityLabel.text = "Activity"
        activityLabel.frame = CGRect(x: 0, y: 60, width: 120, height: 30)
        activityLabel.center.x = self.view.center.x
        allNotificationsButton.setTitle("All activity", for: .normal)
        likesNotificationsButton.setTitle("Likes", for: .normal)
        commentsNotificationsButton.setTitle("Comments", for: .normal)
        followersNotificationsButton.setTitle("Followers", for: .normal)
        mentionsNotificationsButton.setTitle("Mentions", for: .normal)
        
        
        allNotifNumberLabel.backgroundColor = Constants.universalRed.hexToUiColor()
        likesNotifNumberLabel.backgroundColor = Constants.universalRed.hexToUiColor()
        commentsNotifNumberLabel.backgroundColor = Constants.universalRed.hexToUiColor()
        followersNotifNumberLabel.backgroundColor = Constants.universalRed.hexToUiColor()
        mentionsNotifNumberLabel.backgroundColor = Constants.universalRed.hexToUiColor()
        allNotifNumberLabel.textColor = .white
        likesNotifNumberLabel.textColor = .white
        commentsNotifNumberLabel.textColor = .white
        followersNotifNumberLabel.textColor = .white
        mentionsNotifNumberLabel.textColor = .white
        
        styleAllForUnselected()
        allNotificationsButton.styleForSelectednotification()
        
        //        scrollView.frame = CGRect(x: 15, y: activityLabel.frame.maxY + 20, width: UIScreen.main.bounds.width - 30, height: 60)
        scrollView.frame = CGRect(x: 0, y: activityLabel.frame.maxY + 20, width: UIScreen.main.bounds.width, height: 60)
        scrollView.contentSize = CGSize(width: 500, height: scrollView.frame.height)
        //        allNotificationsButton.frame = CGRect(x: 5, y: 5, width: 110, height: scrollView.frame.height - 20)
        allNotificationsButton.frame = CGRect(x: 20, y: 5, width: 110, height: scrollView.frame.height - 20)
        likesNotificationsButton.frame = CGRect(x: allNotificationsButton.frame.maxX + 10, y: allNotificationsButton.frame.minY, width: 80, height: scrollView.frame.height - 20)
        commentsNotificationsButton.frame = CGRect(x: likesNotificationsButton.frame.maxX + 10, y: allNotificationsButton.frame.minY, width: 110, height: scrollView.frame.height - 20)
        followersNotificationsButton.frame = CGRect(x: commentsNotificationsButton.frame.maxX + 10, y: allNotificationsButton.frame.minY, width: 100, height: scrollView.frame.height - 20)
        mentionsNotificationsButton.frame = CGRect(x: followersNotificationsButton.frame.maxX + 10, y: allNotificationsButton.frame.minY, width: 100, height: scrollView.frame.height - 20)
        scrollView.contentSize = CGSize(width: mentionsNotificationsButton.frame.maxX + 20, height: scrollView.frame.height)
        self.newLabel.frame = CGRect(x: scrollView.frame.minX + 2, y: scrollView.frame.maxY + 15, width: UIScreen.main.bounds.width - (scrollView.frame.minX*2), height: 20)
        
        allNotifNumberLabel.layer.cornerRadius = 4
        likesNotifNumberLabel.layer.cornerRadius = 4
        commentsNotifNumberLabel.layer.cornerRadius = 4
        followersNotifNumberLabel.layer.cornerRadius = 4
        mentionsNotifNumberLabel.layer.cornerRadius = 4
        gradientView.frame = CGRect(x: 0, y: allNotifNumberLabel.frame.maxY + 100, width: UIScreen.main.bounds.width, height: 30)
        let tableY = allNotifNumberLabel.frame.maxY + 100
        usersTableView.frame = CGRect(x: 0, y: Int(tableY), width: Int(UIScreen.main.bounds.width), height: Int(UIScreen.main.bounds.height) - Int(tableY) - 85)
        self.usersTableView.backgroundColor = self.view.backgroundColor
        
        let refWidth = 40
        let refY = 50
        refreshButton.setTitle("", for: .normal)
        refreshButton.layer.cornerRadius = 12
        refreshButton.backgroundColor = Constants.secondaryColor.hexToUiColor()
        refreshButton.tintColor = Constants.primaryColor.hexToUiColor()
        refreshButton.frame = CGRect(x: Int(UIScreen.main.bounds.width) - refWidth - 20, y: refY, width: refWidth, height: refWidth)
        refreshButton.isHidden = false
        
        settingsButton.setTitle("", for: .normal)
        settingsButton.layer.cornerRadius = 12
        settingsButton.backgroundColor = Constants.secondaryColor.hexToUiColor()
        settingsButton.tintColor = Constants.primaryColor.hexToUiColor()
        settingsButton.frame = CGRect(x: 20, y: refY, width: refWidth, height: refWidth)
        settingsButton.isHidden = false
    }
    func openProfileForUser(withUID: String) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
            if let navigator = self.parent?.navigationController {
                vc.uidOfProfile = withUID
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigator.pushViewController(vc, animated: true)
                
            }
        }
    }
    func styleAllForUnselected() {
        allNotificationsButton.backgroundColor = .white
        allNotificationsButton.tintColor = .black
        allNotificationsButton.layer.cornerRadius = 12
        allNotificationsButton.layer.shadowOpacity = 0
        
        likesNotificationsButton.backgroundColor = .white
        likesNotificationsButton.tintColor = .black
        likesNotificationsButton.layer.cornerRadius = 12
        likesNotificationsButton.layer.shadowOpacity = 0
        
        commentsNotificationsButton.backgroundColor = .white
        commentsNotificationsButton.tintColor = .black
        commentsNotificationsButton.layer.cornerRadius = 12
        commentsNotificationsButton.layer.shadowOpacity = 0
        
        followersNotificationsButton.backgroundColor = .white
        followersNotificationsButton.tintColor = .black
        followersNotificationsButton.layer.cornerRadius = 12
        followersNotificationsButton.layer.shadowOpacity = 0
        
        mentionsNotificationsButton.backgroundColor = .white
        mentionsNotificationsButton.tintColor = .black
        mentionsNotificationsButton.layer.cornerRadius = 12
        mentionsNotificationsButton.layer.shadowOpacity = 0
        //        allNotificationsButton.titleLabel.font = UIFont(name: "\(Constants.globalFont)", size: 12)
    }
    func getImagePostFrom(values: [String: AnyObject], postID: String) -> imagePost {
        let post = Egg_.imagePost()
        let userID = (Auth.auth().currentUser?.uid)!
        post.userID = userID
        post.postID = postID
        post.commentCount = values["comments_count"] as? Int ?? 0 // fix this
        post.likesCount = values["likes_count"] as? Int ?? 0
        post.imageUrl = values["postImageUrl"] as? String ?? ""
        post.thumbNailImageURL = values["thumbnail_url"] as? String ?? ""
        post.location = values["location"] as? String ?? ""
        post.caption = values["caption"] as? String ?? ""
        post.tags = values["tags"] as? [String] ?? [""]
        post.createdAt = values["createdAt"] as? Double ?? Double(NSDate().timeIntervalSince1970)
        post.imageHash = values["imageHash"] as? String ?? ""
        //        post.username = self.user.username
        post.storageRefForThumbnailImage = values["storage_ref"] as? String ?? ""
        return post
    }
    func handleMoreLoad() {
        let userID = (Auth.auth().currentUser?.uid)!
        //        self.currentu
        if hasDoneinitialFetch {
            if documents.count != 0 {
                query = query.start(afterDocument: documents.last!).limit(to: 10)
            }
            
        }
        hasDoneinitialFetch = true
        query.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                if querySnapshot!.isEmpty {
                    print("* detected empty feed")
                    self.hasReachedEndOfFeed = true
                } else {
                    if self.veryFirstNotificationUID == "" {
                        self.veryFirstNotificationUID = (querySnapshot!.documents.first?.documentID)!
                        print("* setting new last_seen_notification_id notification UID = \(self.veryFirstNotificationUID)")
                        self.db.collection("notifications").document(userID).setData(["last_seen_notification_id":self.veryFirstNotificationUID, "error_message":"", "notifications_count":0, "num_comments_likes_notifications":0, "num_comments_notifications":0, "num_followers_notifications":0, "num_likes_notifications":0, "num_mentions_notifications": 0], merge: true)
                    }
                    let mainPostDispatchQueue = DispatchGroup()
                    if querySnapshot!.documents.count != 0 {
                        mainPostDispatchQueue.enter()
                    }
                    for document in querySnapshot!.documents {
                        self.documents += [document]
                        print("* got user search results: \(document.documentID) => \(document.data())")
                        
                        let usersRef = self.db.collection("user-locations")
                        var idToCheck = ""
                        let docData = document.data() as? [String: AnyObject]
                        let notificationType = (docData)?["type"] as? String ?? ""
                        if notificationType == "began_following" {
                            
                            idToCheck = (docData)?["following_user_id"] as? String ?? ""
                            print("* loading following notification from \(idToCheck)")
                        } else if notificationType == "liked_post" {
                            idToCheck = (docData)?["liked_by_uid"] as? String ?? ""
                            print("* loading like notification from \(idToCheck)")
                        } else if notificationType == "comment_made" {
                            idToCheck = (docData)?["commentUserID"] as? String ?? ""
                            print("* loading comment notification from \(idToCheck)")
                        } else if notificationType == "comment_liked" {
                            idToCheck = (docData)?["commentLikedUserID"] as? String ?? ""
                            print("* loading comment liked notification from \(idToCheck)")
                        } else if notificationType == "comment_reply" {
                            idToCheck = (docData)?["replyUserID"] as? String ?? ""
                            print("* loading comment reply notification from \(idToCheck)")
                        } else if notificationType == "reply_like" {
                            print("* loading reply liked notification from \(idToCheck)")
                            idToCheck = (docData)?["likeUserID"] as? String ?? ""
                        } else if notificationType == "requested_to_follow" {
                            idToCheck = (docData)?["following_user_id"] as? String ?? ""
                        }
                        mainPostDispatchQueue.enter()
                        
                        usersRef.document(idToCheck).getDocument { (document, error) in
                            if let document = document, document.exists {
                                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                                //                                print("Document data: \(dataDescription)")
                                let postVals = document.data() as? [String: Any]
                                let userUID = postVals?["uid"] as? String ?? ""
                                let username = postVals?["username"] as? String ?? ""
                                let profileImageUrl = postVals?["profileImageURL"] as? String ?? ""
                                let full_name = postVals?["full_name"] as? String ?? ""
                                var locationString = "No location"
                                if postVals?["city"] != nil {
                                    if postVals?["state"] != nil {
                                        locationString = "\(postVals?["city"] as! String), \(postVals?["state"] as! String)"
                                    }
                                }
                                var isValidStory = false
                                if postVals?["latest_story_timestamp"] != nil {
                                    //                                    print("* user has a recent story: \(postVals?["latest_story_timestamp"])")
                                    if let timestamp: Timestamp = postVals?["latest_story_timestamp"] as? Timestamp {
                                        let story_date: Date = timestamp.dateValue()
                                        let timeToLive: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours
                                        let isExpired = Date().timeIntervalSince(story_date) >= timeToLive
                                        if isExpired != true {
                                            print("* valid story!")
                                            isValidStory = true
                                        }
                                    }
                                    
                                }
                                if notificationType == "began_following" {
                                    
                                    self.db.collection("followers").document(document.documentID).collection("sub-followers").document(Auth.auth().currentUser!.uid).getDocument { (document, err) in
                                        var following = false
                                        if ((document?.exists) != nil) && document?.exists == true {
                                            following = true
                                        }
                                        
                                        let userResult = FollowNotification()
                                        userResult.followingTimeStamp = Double((docData?["timestamp"] as! Timestamp).seconds)
                                        userResult.fullname = full_name
                                        userResult.hasValidStory = isValidStory
                                        userResult.isFollowing = following
                                        userResult.uid = userUID
                                        userResult.username = username
                                        userResult.profileImageUrl = profileImageUrl
                                        userResult.timeSince = Date(timeIntervalSince1970: TimeInterval(Double((docData?["timestamp"] as! Timestamp).seconds))).simplifiedTimeAgoDisplay()
                                        self.notifications.append(userResult)
                                        mainPostDispatchQueue.leave()
                                    }
                                } else if notificationType == "liked_post" {
                                    self.db.collection("posts").document(userID).collection("posts").document(docData?["liked_post_id"] as! String).getDocument { (documentzz, err) in
                                        if let postVals = (documentzz?.data() as? [String: AnyObject]) {
                                            let post = self.getImagePostFrom(values: postVals, postID: docData?["liked_post_id"] as! String)
                                            let userResult = LikedPostNotification()
                                            userResult.currentPost = post
                                            userResult.profileImageUrl = profileImageUrl
                                            userResult.hasValidStory = isValidStory
                                            userResult.fullname = full_name
                                            userResult.likeUserID = idToCheck
                                            userResult.likeUsername = username
                                            userResult.postID = docData?["liked_post_id"] as! String
                                            userResult.postAuthorID = userID
                                            if let documentzz = documentzz {
                                                let dd = documentzz.data() as? [String: AnyObject]
                                                if let thumnailURL = dd?["thumbnail_url"] as? String {
                                                    userResult.postThumbnailURL = thumnailURL
                                                }
                                            }
                                            userResult.likedTimeStamp = Double((docData?["timestamp"] as! Timestamp).seconds)
                                            userResult.timeSince = Date(timeIntervalSince1970: TimeInterval(Double((docData?["timestamp"] as! Timestamp).seconds))).simplifiedTimeAgoDisplay()
                                            self.notifications.append(userResult)
                                        }
                                        
                                        mainPostDispatchQueue.leave()
                                    }
                                }  else if notificationType == "comment_made" {
                                    self.db.collection("posts").document(userID).collection("posts").document((docData)?["postId"] as! String).getDocument { (documentzz, err) in
                                        if let postVals = (documentzz?.data() as? [String: AnyObject]) {
                                            let post = self.getImagePostFrom(values: postVals, postID: (docData)?["postId"] as! String)
                                            let userResult = CommentMadeNotification()
                                            userResult.currentPost = post
                                            userResult.profileImageUrl = profileImageUrl
                                            userResult.postThumbnailURL = post.thumbNailImageURL
                                            userResult.hasValidStory = isValidStory
                                            userResult.comment = (docData)?["comment"] as? String ?? ""
                                            print("* loaded comment: \((docData)?["comment"] as? String ?? "")")
                                            userResult.commentId = (docData)?["commentId"] as? String ?? ""
                                            userResult.commentUserID = (docData)?["commentUserID"] as? String ?? ""
                                            userResult.commentUserName = (docData)?["commentUserName"] as? String ?? ""
                                            userResult.createdAt = Double((docData?["timestamp"] as! Timestamp).seconds)
                                            userResult.profileImageUrl = (docData)?["commentUserImage"] as? String ?? ""
                                            userResult.postId = (docData)?["postId"] as? String ?? ""
                                            userResult.userId = (docData)?["userId"] as? String ?? ""
                                            
                                            userResult.timeSince = Date(timeIntervalSince1970: TimeInterval(Double((docData?["timestamp"] as! Timestamp).seconds))).simplifiedTimeAgoDisplay()
                                            self.notifications.append(userResult)
                                        }
                                        
                                        mainPostDispatchQueue.leave()
                                    }
                                    
                                } else if notificationType == "comment_liked" {
                                    print("* comment liked!")
                                    self.db.collection("posts").document((docData)?["userId"] as? String ?? "").collection("posts").document((docData)?["postId"] as! String).getDocument { (documentzz, err) in
                                            if let postVals = (documentzz?.data() as? [String: AnyObject]) {
                                                let post = self.getImagePostFrom(values: postVals, postID: (docData)?["postId"] as! String)
                                                let userResult = likedCommentNotif()
                                                
                                                userResult.profileImageUrl = profileImageUrl
                                                userResult.postThumbnailURL = post.thumbNailImageURL
                                                userResult.hasValidStory = isValidStory
                                                userResult.comment = (docData)?["comment"] as? String ?? ""
                                                userResult.commentLikedByUserwithUID = (docData)?["commentLikedUserID"] as? String ?? ""
                                                print("* loaded comment liked: \((docData)?["comment"] as? String ?? "")")
                                                userResult.commentId = (docData)?["commentId"] as? String ?? ""
                                                userResult.commentUserID = (docData)?["commentUserID"] as? String ?? ""
                                                userResult.commentUserName = (docData)?["commentLikedUserName"] as? String ?? ""
                                                
                                                userResult.createdAt = Double((docData?["timestamp"] as! Timestamp).seconds)
                                                userResult.profileImageUrl = profileImageUrl
                                                userResult.postId = (docData)?["postId"] as? String ?? ""
                                                //                                            userResult.userId = (docData)?["userId"] as? String ?? ""
                                                usersRef.document((docData)?["userId"] as? String ?? "").getDocument { (document, error) in
                                                    if let document = document, document.exists {
                                                        post.username = document.data()?["username"] as? String ?? ""
                                                        post.userImageUrl = document.data()?["profileImageURL"] as? String ?? ""
                                                        post.userID = (docData)?["userId"] as? String ?? ""
                                                        userResult.timeSince = Date(timeIntervalSince1970: TimeInterval(Double((docData?["timestamp"] as! Timestamp).seconds))).simplifiedTimeAgoDisplay()
                                                        userResult.currentPost = post
                                                        self.notifications.append(userResult)
                                                    }
                                                    mainPostDispatchQueue.leave()
                                                }
                                               
                                            }
                                            
                                            
                                        
                                        
                                    }
                                } else if notificationType == "comment_reply" {
                                    let reply = ReplyMadeNotification()
                                    reply.timestamp = Double((docData?["timestamp"] as! Timestamp).seconds)
                                    reply.userId = (docData)?["userId"] as? String ?? ""
//                                    print("* [TSB] NOTIFICATIONS REPLY TIMESTAMP: \(reply.timestamp)")
//                                    print("* reply doc data: \(docData)")
                                    reply.postId = (docData)?["postId"] as? String ?? ""
                                    reply.commentId = (docData)?["commentId"] as? String ?? ""
                                    reply.reply = (docData)?["reply"] as? String ?? ""
                                    reply.replyId = (docData)?["replyId"] as? String ?? ""
                                    reply.replyUserID = (docData)?["replyUserID"] as? String ?? ""
                                    reply.replyUserName = (docData)?["replyUserName"] as? String ?? ""
                                    reply.replyUserImage = (docData)?["replyUserImage"] as? String ?? ""
                                    reply.originalComment = (docData)?["originalComment"] as? String ?? ""
                                    reply.timeSince = Date(timeIntervalSince1970: TimeInterval(Double((docData?["timestamp"] as! Timestamp).seconds))).simplifiedTimeAgoDisplay()
                                    self.db.collection("posts").document(reply.userId).collection("posts").document(reply.postId).getDocument { (doc, err) in
                                        if let data = doc?.data() as? [String: AnyObject] {
                                            reply.postThumbnailURL = data["thumbnail_url"] as? String ?? ""
                                            let post = self.getImagePostFrom(values: data, postID: reply.postId)
                                            post.userID = reply.userId
                                            reply.currentPost = post
                                        }
                                        self.notifications.append(reply)
                                        mainPostDispatchQueue.leave()
                                    }
//                                    self.notifications.append(reply)
//                                    mainPostDispatchQueue.leave()
                                    
                                } else if notificationType == "reply_like" {
                                    let reply_like = likedReplyNotif()
                                    reply_like.timestamp = Double((docData?["timestamp"] as! Timestamp).seconds)
//                                    print("* [TSB] NOTIFICATIONS REPLY_LIKE TIMESTAMP: \(reply_like.timestamp)")
                                    reply_like.userId = (docData)?["userId"] as? String ?? ""
                                    reply_like.postId = (docData)?["postId"] as? String ?? ""
                                    reply_like.commentId = (docData)?["commentId"] as? String ?? ""
                                    reply_like.replyId = (docData)?["replyId"] as? String ?? ""
                                    reply_like.likeId = (docData)?["likeId"] as? String ?? ""
                                    reply_like.likeUserID = (docData)?["likeUserID"] as? String ?? ""
                                    reply_like.likeUserName = (docData)?["likeUserName"] as? String ?? ""
                                    reply_like.likeUserImage = (docData)?["likeUserImage"] as? String ?? ""
                                    reply_like.replyUserID = (docData)?["replyUserID"] as? String ?? ""
                                    reply_like.replyUserName = (docData)?["replyUserName"] as? String ?? ""
                                    reply_like.replyUserImage = (docData)?["replyUserImage"] as? String ?? ""
                                    reply_like.originalReply = (docData)?["originalReply"] as? String ?? ""
                                    reply_like.timeSince = Date(timeIntervalSince1970: TimeInterval(Double((docData?["timestamp"] as! Timestamp).seconds))).simplifiedTimeAgoDisplay()
                                    self.db.collection("posts").document(reply_like.userId).collection("posts").document(reply_like.postId).getDocument { (doc, err) in
                                        if let data = doc?.data() as? [String: AnyObject] {
                                            reply_like.postThumbnailURL = data["thumbnail_url"] as? String ?? ""
                                            let post = self.getImagePostFrom(values: data, postID: reply_like.postId)
                                            post.userID = reply_like.userId
                                            reply_like.currentPost = post
                                        }
                                        self.notifications.append(reply_like)
                                        mainPostDispatchQueue.leave()
                                    }
                                    
                                } else if notificationType == "requested_to_follow" {
                                    let flw_request = ReqFollowNotif()
                                    flw_request.username = username
                                    flw_request.followingTimeStamp = Double((docData?["timestamp"] as! Timestamp).seconds)
                                    flw_request.profileImageUrl = profileImageUrl
                                    flw_request.hasAccepted = false
                                    flw_request.timeSince = Date(timeIntervalSince1970: TimeInterval(flw_request.followingTimeStamp)).simplifiedTimeAgoDisplay()
                                    flw_request.uid = postVals?["uid"] as? String ?? ""
                                    self.notifications.append(flw_request)
                                    mainPostDispatchQueue.leave()
                                } else {
                                    // ADD MORE HERE
                                    print("* unknown notification type")
                                    mainPostDispatchQueue.leave()
                                }
//                                print("* notifications fucked: \(self.notifications)")
                            } else {
                                print("Document does not exist")
                                mainPostDispatchQueue.leave()
                            }
                            
                        }
                        if document == querySnapshot?.documents.last {
                            mainPostDispatchQueue.leave()
                        }
                    }
                    mainPostDispatchQueue.notify(queue: .main) {
                        print("* dispatch queue notified, refreshing")
                        self.notifications = self.notifications.sorted(by: {(obj1, obj2) -> Bool in
                            
                            if let im1 = obj1 as? LikedPostNotification {
                                if let im2 = obj2 as? LikedPostNotification {
                                    return im1.likedTimeStamp > im2.likedTimeStamp
                                } else if let im2 = obj2 as? FollowNotification {
                                    return im1.likedTimeStamp > im2.followingTimeStamp
                                } else if let im2 = obj2 as? CommentMadeNotification {
                                    return im1.likedTimeStamp > im2.createdAt
                                } else if let im2 = obj2 as? likedCommentNotif {
                                    return im1.likedTimeStamp > im2.createdAt
                                } else if let im2 = obj2 as? ReplyMadeNotification {
                                    return im1.likedTimeStamp > im2.timestamp
                                } else if let im2 = obj2 as? likedReplyNotif {
                                    return im1.likedTimeStamp > im2.timestamp
                                } else if let im2 = obj2 as? ReqFollowNotif {
                                    return im1.likedTimeStamp > im2.followingTimeStamp
                                } else {
                                    return false
                                }
                            } else if let im1 = obj1 as? FollowNotification {
                                if let im2 = obj2 as? LikedPostNotification {
                                    return im1.followingTimeStamp > im2.likedTimeStamp
                                } else if let im2 = obj2 as? FollowNotification {
                                    return im1.followingTimeStamp > im2.followingTimeStamp
                                } else if let im2 = obj2 as? likedCommentNotif {
                                    return im1.followingTimeStamp > im2.createdAt
                                } else if let im2 = obj2 as? CommentMadeNotification {
                                    return im1.followingTimeStamp > im2.createdAt
                                } else if let im2 = obj2 as? ReplyMadeNotification {
                                    return im1.followingTimeStamp > im2.timestamp
                                } else if let im2 = obj2 as? likedReplyNotif {
                                    return im1.followingTimeStamp > im2.timestamp
                                } else if let im2 = obj2 as? ReqFollowNotif {
                                    return im1.followingTimeStamp > im2.followingTimeStamp
                                } else {
                                    return false
                                }
                            } else if let im1 = obj1 as? CommentMadeNotification {
                                if let im2 = obj2 as? LikedPostNotification {
                                    return im1.createdAt > im2.likedTimeStamp
                                } else if let im2 = obj2 as? FollowNotification {
                                    return im1.createdAt > im2.followingTimeStamp
                                } else if let im2 = obj2 as? likedCommentNotif {
                                    return im1.createdAt > im2.createdAt
                                } else if let im2 = obj2 as? CommentMadeNotification {
                                    return im1.createdAt > im2.createdAt
                                } else if let im2 = obj2 as? ReplyMadeNotification {
                                    return im1.createdAt > im2.timestamp
                                } else if let im2 = obj2 as? likedReplyNotif {
                                    return im1.createdAt > im2.timestamp
                                } else if let im2 = obj2 as? ReqFollowNotif {
                                    return im1.createdAt > im2.followingTimeStamp
                                } else {
                                    return false
                                }
                            } else if let im1 = obj1 as? likedCommentNotif {
                                if let im2 = obj2 as? LikedPostNotification {
                                    return im1.createdAt > im2.likedTimeStamp
                                } else if let im2 = obj2 as? FollowNotification {
                                    return im1.createdAt > im2.followingTimeStamp
                                } else if let im2 = obj2 as? likedCommentNotif {
                                    return im1.createdAt > im2.createdAt
                                } else if let im2 = obj2 as? CommentMadeNotification {
                                    return im1.createdAt > im2.createdAt
                                } else if let im2 = obj2 as? ReplyMadeNotification {
                                    return im1.createdAt > im2.timestamp
                                } else if let im2 = obj2 as? likedReplyNotif {
                                    return im1.createdAt > im2.timestamp
                                } else if let im2 = obj2 as? ReqFollowNotif {
                                    return im1.createdAt > im2.followingTimeStamp
                                } else {
                                    return false
                                }
                            } else if let im1 = obj1 as? ReplyMadeNotification {
                                if let im2 = obj2 as? LikedPostNotification {
                                    return im1.timestamp > im2.likedTimeStamp
                                } else if let im2 = obj2 as? FollowNotification {
                                    return im1.timestamp > im2.followingTimeStamp
                                } else if let im2 = obj2 as? likedCommentNotif {
                                    return im1.timestamp > im2.createdAt
                                } else if let im2 = obj2 as? CommentMadeNotification {
                                    return im1.timestamp > im2.createdAt
                                } else if let im2 = obj2 as? ReplyMadeNotification {
                                    return im1.timestamp > im2.timestamp
                                } else if let im2 = obj2 as? likedReplyNotif {
                                    return im1.timestamp > im2.timestamp
                                } else if let im2 = obj2 as? ReqFollowNotif {
                                    return im1.timestamp > im2.followingTimeStamp
                                } else {
                                    return false
                                }
                            } else if let im1 = obj1 as? likedReplyNotif {
                                if let im2 = obj2 as? LikedPostNotification {
                                    return im1.timestamp > im2.likedTimeStamp
                                } else if let im2 = obj2 as? FollowNotification {
                                    return im1.timestamp > im2.followingTimeStamp
                                } else if let im2 = obj2 as? likedCommentNotif {
                                    return im1.timestamp > im2.createdAt
                                } else if let im2 = obj2 as? CommentMadeNotification {
                                    return im1.timestamp > im2.createdAt
                                } else if let im2 = obj2 as? ReplyMadeNotification {
                                    return im1.timestamp > im2.timestamp
                                } else if let im2 = obj2 as? likedReplyNotif {
                                    return im1.timestamp > im2.timestamp
                                } else if let im2 = obj2 as? ReqFollowNotif {
                                    return im1.timestamp > im2.followingTimeStamp
                                } else {
                                    return false
                                }
                            } else if let im1 = obj1 as? ReqFollowNotif {
                                if let im2 = obj2 as? LikedPostNotification {
                                    return im1.followingTimeStamp > im2.likedTimeStamp
                                } else if let im2 = obj2 as? FollowNotification {
                                    return im1.followingTimeStamp > im2.followingTimeStamp
                                } else if let im2 = obj2 as? likedCommentNotif {
                                    return im1.followingTimeStamp > im2.createdAt
                                } else if let im2 = obj2 as? CommentMadeNotification {
                                    return im1.followingTimeStamp > im2.createdAt
                                } else if let im2 = obj2 as? ReplyMadeNotification {
                                    return im1.followingTimeStamp > im2.timestamp
                                } else if let im2 = obj2 as? likedReplyNotif {
                                    return im1.followingTimeStamp > im2.timestamp
                                } else if let im2 = obj2 as? ReqFollowNotif {
                                    return im1.followingTimeStamp > im2.followingTimeStamp
                                } else {
                                    return false
                                }
                            } else {
                                return false
                            }
                        })
                        self.currentlyLoadingStuff = false
                        print("* sorted notifications array: \(self.notifications)")
                        if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                            print("* looks like we've reached the end of comments collection")
                            self.hasReachedEndOfFeed = true
                        } else {
                            self.usersTableView.reloadData {
                                print("* done reloading")
                                //                                self.usersTableView.fadeIn()
                                
                            }
                            
                            
                        }
                    }
                }
            }
        }
    }
    func paginate() {
        //This line is the main pagination code.
        //Firestore allows you to fetch document from the last queryDocument
        print("* paginate called")
        if hasDoneinitialFetch && documents.count != 0 {
            query = query.start(afterDocument: documents.last!).limit(to: 10)
        }
        if currentlyLoadingStuff == false {
            handleMoreLoad()
            currentlyLoadingStuff = true
        }
        
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Trigger pagination when scrolled to last cell
        // Feel free to adjust when you? want pagination to be triggered
        if (indexPath.row == (notifications.count - 3)) && hasReachedEndOfFeed == false {
            
            print("* fetching more notifications. Current notifications count: \((notifications.count ?? 0))")
            paginate()
        }
        
        // create offset
        //        if let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last {
        //                if indexPath == lastVisibleIndexPath {
        //                    if self.hasDoneinitialFetchForSearch == false {
        //                        DispatchQueue.main.async {
        //                            self.usersTableView.setContentOffset(CGPoint(x: 0, y: 74), animated: false)
        //                            print("* adding offset for table view: 80")
        //                            self.hasDoneinitialFetchForSearch = true
        //                        }
        //                    }
        //                }
        //            }
        
    }
    
    func fetchLatestNotifications() {
        
    }
    let interactor = Interactor()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
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
extension NotificationsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
@IBDesignable
class PaddingLabel: UILabel {
    var textEdgeInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textEdgeInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textEdgeInsets.top, left: -textEdgeInsets.left, bottom: -textEdgeInsets.bottom, right: -textEdgeInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textEdgeInsets))
    }
    
    @IBInspectable
    var paddingLeft: CGFloat {
        set { textEdgeInsets.left = newValue }
        get { return textEdgeInsets.left }
    }
    
    @IBInspectable
    var paddingRight: CGFloat {
        set { textEdgeInsets.right = newValue }
        get { return textEdgeInsets.right }
    }
    
    @IBInspectable
    var paddingTop: CGFloat {
        set { textEdgeInsets.top = newValue }
        get { return textEdgeInsets.top }
    }
    
    @IBInspectable
    var paddingBottom: CGFloat {
        set { textEdgeInsets.bottom = newValue }
        get { return textEdgeInsets.bottom }
    }
}
extension UIButton {
    func styleForSelectednotification() {
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowOpacity = 0.6
        self.layer.shadowRadius = 4
        self.backgroundColor = .black
        self.tintColor = .white
    }
}
extension NSMutableAttributedString{
    func setColorForText(_ textToFind: String, with color: UIColor) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        }
    }
}
