//
//  SceneDelegate.swift
//  Egg.
//
//  Created by Jordan Wood on 5/15/22.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var db = Firestore.firestore()
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
            // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
            // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

            // Create the SwiftUI view that provides the window contents.
//            let rootView = ContentView()
//
//            // Use a UIHostingController as window root view controller.
//            if let windowScene = scene as? UIWindowScene {
//                let window = UIWindow(windowScene: windowScene)
//                window.rootViewController = UIHostingController(rootView: rootView)
//                self.window = window
//                window.makeKeyAndVisible()
//            }

            guard let userActivity = connectionOptions.userActivities.first(where: { $0.webpageURL != nil }) else { return }
            print("url: \(userActivity.webpageURL!)")
        }

        func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
            print("* continuing with url: \(userActivity.webpageURL!)")
            if let ur = userActivity.webpageURL {
                let urlString = ur.absoluteString
                if urlString.contains("profile") {
                    print("* profile shared")
                    let uid = getQueryStringParameter(url: urlString.replacingOccurrences(of: "/?isi=1637329972", with: ""), param: "uid")
                    print("* opening profile for uid \(uid)")
                    if let uid = uid {
                        openProfileForUser(withUID: uid)
                    }
                    
                } else if urlString.contains("post") {
                    print("* post shared")
                    let uid = getQueryStringParameter(url: urlString, param: "uid")
                    let postID = getQueryStringParameter(url: urlString, param: "posti")?.replacingOccurrences(of: "/?isi=1637329972", with: "")
                    let commentID = getQueryStringParameter(url: urlString, param: "commenti")?.replacingOccurrences(of: "/?isi=1637329972", with: "")
                    let replyID = getQueryStringParameter(url: urlString, param: "replyi")?.replacingOccurrences(of: "/?isi=1637329972", with: "")
                    if let uid = uid {
                        if let postID = postID {
                            if let commentID = commentID {
                                if let replyID = replyID {
                                    openComment(userID: uid, postID: postID, commentID: commentID, replyID: replyID)
                                }
                                openComment(userID: uid, postID: postID, commentID: commentID, replyID: "")
                            } else {
                                print("* opening: posts/\(uid)/posts/\(postID)")
                                openPost(userID: uid, postID: postID)
                            }
                            
                        }
                    }
                    
                }
            }
        }
    func openComment(userID: String, postID: String, commentID: String, replyID: String) {
        if var topController = window?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            print("* found navigator, presenting view controller: \(topController)")
            // topController should now be your topmost view controller
            if let navigator = topController.navigationController {
                FindPostAndOpenViaNavi(userID: userID, postID: postID, navigator: navigator)
                return
            }
            if let navigator = topController as? UINavigationController {
//                FindPostAndOpenViaNavi(userID: userID, postID: postID, navigator: navigator)
                if replyID == "" {
                    print("* opening comment")
                    db.collection("user-locations").document(userID).getDocument() { [self] (document, error) in
                        if let document = document {
                            let data = document.data()! as [String: AnyObject]
                            let profileImageUrl = data["profileImageURL"] as? String ?? ""
                            let usrname = data["username"] as? String ?? ""
                            let fullname = data["full_name"] as? String ?? ""
                            let ispriv = data["isPrivate"] as? Bool ?? false
                            self.db.collection("posts").document(userID).collection("posts").document(postID).getDocument { (documentzz, err) in
                                if let postVals = (documentzz?.data() as? [String: AnyObject]) {
                                    let post = self.getImagePostFrom(values: postVals, postID: postID)
                                    if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                                        print("* presenting post")
                                        //                vc.currentIndex = indexPath.row
                                        vc.currentIndex = 0
                                        vc.username = usrname
        //                                vc.hasValidStory = self.hasValidStory
                                        vc.imageUrl = profileImageUrl
                                        vc.isFollowing = false
                                        vc.imagePosts = [post] // only load in one post
                                        vc.shouldOpenCommentSection = true
                                        vc.commentToOpen = commentID
                                        
                                        vc.profileUID = userID
                                        navigator.pushViewController(vc, animated: true)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print("* opening reply")
                    db.collection("user-locations").document(userID).getDocument() { [self] (document, error) in
                        if let document = document {
                            let data = document.data()! as [String: AnyObject]
                            let profileImageUrl = data["profileImageURL"] as? String ?? ""
                            let usrname = data["username"] as? String ?? ""
                            let fullname = data["full_name"] as? String ?? ""
                            let ispriv = data["isPrivate"] as? Bool ?? false
                            self.db.collection("posts").document(userID).collection("posts").document(postID).getDocument { (documentzz, err) in
                                if let postVals = (documentzz?.data() as? [String: AnyObject]) {
                                    let post = self.getImagePostFrom(values: postVals, postID: postID)
                                    if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                                        print("* presenting post")
                                        //                vc.currentIndex = indexPath.row
                                        vc.currentIndex = 0
                                        vc.username = usrname
        //                                vc.hasValidStory = self.hasValidStory
                                        vc.imageUrl = profileImageUrl
                                        vc.isFollowing = false
                                        vc.imagePosts = [post] // only load in one post
                                        vc.shouldOpenCommentSection = true
                                        vc.commentToOpen = commentID
                                        vc.replyToOpen = replyID
                                        vc.profileUID = userID
                                        navigator.pushViewController(vc, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
        
    }
    func openPost(userID: String, postID: String) {
        if var topController = window?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            print("* found navigator, presenting view controller: \(topController)")
            // topController should now be your topmost view controller
            if let navigator = topController.navigationController {
                FindPostAndOpenViaNavi(userID: userID, postID: postID, navigator: navigator)
                return
            }
            if let navigator = topController as? UINavigationController {
                FindPostAndOpenViaNavi(userID: userID, postID: postID, navigator: navigator)
            }
            
        }
    }
        func FindPostAndOpenViaNavi(userID: String, postID: String, navigator: UINavigationController) {
            db.collection("user-locations").document(userID).getDocument() { [self] (document, error) in
                if let document = document {
                    let data = document.data()! as [String: AnyObject]
                    let profileImageUrl = data["profileImageURL"] as? String ?? "" 
                    let usrname = data["username"] as? String ?? ""
                    let fullname = data["full_name"] as? String ?? ""
                    let ispriv = data["isPrivate"] as? Bool ?? false
                    self.db.collection("posts").document(userID).collection("posts").document(postID).getDocument { (documentzz, err) in
                        if let postVals = (documentzz?.data() as? [String: AnyObject]) {
                            let post = self.getImagePostFrom(values: postVals, postID: postID)
                            if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoPageConteiner") as? PhotoPageContainerViewController {
                                print("* presenting post")
                                //                vc.currentIndex = indexPath.row
                                vc.currentIndex = 0
                                vc.username = usrname
//                                vc.hasValidStory = self.hasValidStory
                                vc.imageUrl = profileImageUrl
                                vc.isFollowing = false
                                vc.imagePosts = [post] // only load in one post
                                
                                vc.profileUID = userID
                                navigator.pushViewController(vc, animated: true)
                            }
                        }
                    }
                }
            }
           
        }
    func openProfileForUser(withUID: String) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
            if var topController = window?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                print("* found navigator, presenting view controller: \(topController)")
                // topController should now be your topmost view controller
                if let navigator = topController.navigationController {
                    print("* got navi for top controller: \(topController)")
                    vc.uidOfProfile = withUID
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    navigator.pushViewController(vc, animated: true)
                    return
                }
                if let navigator = topController as? UINavigationController {
                    vc.uidOfProfile = withUID
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    navigator.pushViewController(vc, animated: true)
                    return
                }
            }
            
        }
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
        let images = values["images"] as? [String] ?? []
        if images.count > 1 {
            print("* multiple images detected")
            post.multiImageUrls = images
        }
        //        post.username = self.user.username
        post.storageRefForThumbnailImage = values["storage_ref"] as? String ?? ""
        return post
    }
    func getQueryStringParameter(url: String, param: String) -> String? {
      guard let url = URLComponents(string: url) else { return nil }
      return url.queryItems?.first(where: { $0.name == param })?.value
    }
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

