//
//  userListViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 7/24/22.
//

import UIKit
import SkeletonView
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct userListConfig {
    var type = "" // likes, followers, following, blocked
    var originalAuthorID = "" // author ID to look for
    var postID = "" //post id if applicable
    var numberToPutInFront = 0
    var shouldhideBackbutton = false // should hide backbutton?
}
class SearchTableFooter: UITableViewHeaderFooterView, UITextFieldDelegate {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}
class TableHeader: UITableViewHeaderFooterView, UITextFieldDelegate {
    var searchTimer: Timer?
    // view used at top of tableview for searching and what not
    static let identifier = "searchHeader"
    private let searchBar: UITextField = {
        let searchbar = UITextField()
        searchbar.styleSearchBar()
        return searchbar
    }()
    
    private let magnifyingGlassImage: UIImageView = {
        let magnifyingGlass = UIImageView()
        magnifyingGlass.image = UIImage(systemName: "magnifyingglass")
        magnifyingGlass.tintColor = .lightGray
//        magnifyingGlass.frame =
        magnifyingGlass.contentMode = .scaleAspectFit
        return magnifyingGlass
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        searchBar.font = UIFont(name: "\(Constants.globalFont)", size: 15)
        searchBar.textColor = .darkGray
        searchBar.delegate = self
        // handle the editingChanged event by calling (textFieldDidEditingChanged(-:))
        self.searchBar.addTarget(self, action: #selector(textFieldDidEditingChanged(_:)), for: .editingChanged)
        searchBar.clearButtonMode = .whileEditing
        contentView.addSubview(searchBar)
        contentView.addSubview(magnifyingGlassImage)
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        searchBar.frame = CGRect(x: 10, y: 20, width: contentView.frame.width - 20, height: 50)
        searchBar.placeholder = "Search..."
        searchBar.setLeftPaddingPoints(45)
        magnifyingGlassImage.frame = CGRect(x: searchBar.frame.minX + 15, y: searchBar.frame.minY + 15, width: 20, height: 20)
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    @objc func textFieldDidEditingChanged(_ textField: UITextField) {
        
        // if a timer is already active, prevent it from firing
        if searchTimer != nil {
            searchTimer?.invalidate()
            searchTimer = nil
        }
        
        // reschedule the search: in 1.0 second, call the searchForKeyword method on the new textfield content
        searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(searchForKeyword(_:)), userInfo: textField.text!, repeats: false)
    }
    
    @objc func searchForKeyword(_ timer: Timer) {
        
        // retrieve the keyword from user info
        let keyword = timer.userInfo!
        
        let className = NSStringFromClass(self.findViewController()!.classForCoder)
        if className == "Egg_.userListViewController" {
            print("* accessing parent")
            let vc = self.findViewController() as? userListViewController
            if searchBar.text ?? "" == "" {
                print("* resetting table view")
                vc?.resetTableView()
            } else {
                vc?.search(keyword: (searchBar.text ?? "").lowercased())
            }
        }
        
    }
}
class userListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UITextFieldDelegate {
    
    
    var userConfig = userListConfig()
    @IBOutlet weak var usersTableView: UITableView!
    private var db = Firestore.firestore()
    var query: Query!
    var documents = [QueryDocumentSnapshot]()
    var searchResults: [User] = []
    
    var hasReachedEndOfFeed = false
    var hasDoneinitialFetch = false
    var hasDoneinitialFetchForSearch = false
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var magnifyingGlassImage: UIImageView!
    var searchTimer: Timer?
    var tmp = false
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle("", for: .normal)
        if userConfig.type == "likes" {
            if userConfig.numberToPutInFront != 0 {
                topLabel.text = "\(userConfig.numberToPutInFront) Likes"
            } else {
                topLabel.text = "Likes"
            }
            let likesRef = db.collection("posts").document(userConfig.originalAuthorID).collection("posts").document(userConfig.postID).collection("likes")
            print("* set query to posts/\(userConfig.originalAuthorID)/posts/\(userConfig.postID)/likes")
            query = likesRef.order(by: "likedAtTimeStamp", descending: true).limit(to: 10)
            Analytics.logEvent("initial_likes_list_loaded", parameters: nil)
            
        } else if userConfig.type == "followers" {
            if userConfig.numberToPutInFront != 0 {
                topLabel.text = "\(userConfig.numberToPutInFront) Followers"
            } else {
                topLabel.text = "Followers"
            }
            let userID = Auth.auth().currentUser?.uid
            let followersRef = db.collection("followers")
            query = followersRef.document(userConfig.originalAuthorID).collection("sub-followers").order(by: "timestamp", descending: true).limit(to: 10)
            Analytics.logEvent("initial_followers_list_loaded", parameters: nil)
        } else if userConfig.type == "following" {
            if userConfig.numberToPutInFront != 0 {
                topLabel.text = "\(userConfig.numberToPutInFront) Following"
            } else {
                topLabel.text = "Following"
            }
            let followersRef = db.collection("following")
            query = followersRef.document(userConfig.originalAuthorID).collection("sub-following").order(by: "timestamp", descending: true).limit(to: 10)
            Analytics.logEvent("initial_following_list_loaded", parameters: nil)
        } else if userConfig.type == "blocked" {
            if userConfig.numberToPutInFront != 0 {
                topLabel.text = "\(userConfig.numberToPutInFront) Blocked"
            } else {
                topLabel.text = "Blocked"
            }
            let followersRef = db.collection("blocked")
            query = followersRef.document(userConfig.originalAuthorID).collection("blocked_users").order(by: "blocked_at", descending: true).limit(to: 10)
            Analytics.logEvent("initial_blocked_list_loaded", parameters: nil)
        }
        
        usersTableView.delegate = self
        usersTableView.dataSource = self
        handleMoreLoad() // loads likes/follwers/following
        styleTopAndBottom()
        if Auth.auth().currentUser?.uid == nil {
        } else {
            
        }
        if Constants.isDebugEnabled {
            //            var window : UIWindow = UIApplication.shared.keyWindow!
            //            window.showDebugMenu()
            self.view.debuggingStyle = true
        }
//        usersTableView.tableHeaderView = searchBar
        usersTableView.register(TableHeader.self, forHeaderFooterViewReuseIdentifier: "searchHeader")
        usersTableView.register(SearchTableFooter.self, forHeaderFooterViewReuseIdentifier: "searchFooter")
        // Set the content offset to the height of the search bar's height
                // to hide it when the view is first presented.
        self.view.backgroundColor = hexStringToUIColor(hex: "#f5f5f5")
        self.usersTableView.showsVerticalScrollIndicator = false
//        self.usersTableView.isHidden = false
//        self.usersTableView.alpha = 1
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    func handleMoreLoad() {
        if hasDoneinitialFetch {
            if documents.count != 0 {
                query = query.start(afterDocument: documents.last!).limit(to: 10)
            }
            
        }
        tmp = hasDoneinitialFetch
        
        
        if userConfig.type == "likes" {
            Analytics.logEvent("more_likes_loaded", parameters: nil)
            
        } else if userConfig.type == "followers" {
            Analytics.logEvent("more_followers_loaded", parameters: nil)
        } else if userConfig.type == "following" {
            Analytics.logEvent("initial_following_list_loaded", parameters: nil)
        } else if userConfig.type == "following" {
            Analytics.logEvent("initial_blocked_list_loaded", parameters: nil)
        }
        query.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                if querySnapshot!.isEmpty {
                    print("* detected empty feed")
                    self.hasReachedEndOfFeed = true
                } else {
                    let mainPostDispatchQueue = DispatchGroup()
                    for document in querySnapshot!.documents {
                        self.documents += [document]
                        print("* got user search results: \(document.documentID) => \(document.data())")
                        
                        let usersRef = self.db.collection("user-locations")
                        mainPostDispatchQueue.enter()
                        
                        usersRef.document(document.documentID).getDocument { (document, error) in
                            if let document = document, document.exists {
                                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                                print("Document data: \(dataDescription)")
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
                                    print("* user has a recent story: \(postVals?["latest_story_timestamp"])")
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
                                //                        let latest_story_timestamp =
                                
                                self.db.collection("followers").document(document.documentID).collection("sub-followers").document(Auth.auth().currentUser!.uid).getDocument { (document, err) in
                                    
                                    var following = false
                                    if ((document?.exists) != nil) && document?.exists == true {
                                        print("* current user is following user")
                                        following = true
                                    }
                                    var userResult = User(uid: userUID, username: username, profileImageUrl: profileImageUrl, bio: "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: full_name, hasValidStory: isValidStory, isFollowing: following)
                                    userResult.location = locationString
                                    self.searchResults.append(userResult)
                                    mainPostDispatchQueue.leave()
                                }
                                
                                
                            } else {
                                print("Document does not exist")
                            }
                            
                        }
                        
                    }
                    mainPostDispatchQueue.notify(queue: .main) {
                        print("* dispatch queue notified, refreshing")
                        if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                            print("* looks like we've reached the end of comments collection")
                            self.hasReachedEndOfFeed = true
                        } else {
                            self.usersTableView.reloadData {
                                print("* done reloading")
                                if self.hasDoneinitialFetch == false {
                                    self.usersTableView.fadeIn()
                                    self.hasDoneinitialFetch = true
                                }
                                
                            }
                            
                            
                        }
                    }
                }
            }
        }
    }
    func search(keyword: String) {
        print("Searching for keyword \(keyword)")
        let usersRef = db.collection("user-locations")
        searchResults.removeAll()
        documents.removeAll()
        let userID = Auth.auth().currentUser?.uid
        let end = "\(keyword.dropLast())\(nextChar(str: "\(keyword.last!)"))"
        let followersRef = db.collection("following")
        var queryz = followersRef.document(userConfig.originalAuthorID).collection("sub-following")
        if userConfig.type == "followers" {
            queryz = db.collection("followers").document(userConfig.originalAuthorID).collection("sub-followers")
        } else if userConfig.type == "likes" {
            queryz = db.collection("posts").document(userConfig.originalAuthorID).collection("posts").document(userConfig.postID).collection("likes")
        } else if userConfig.type == "blocked" {
            queryz = db.collection("blocked").document(userConfig.originalAuthorID).collection("blocked_users")
        }
        queryz.whereField("username", isGreaterThanOrEqualTo: keyword.lowercased()).whereField("username", isLessThan: end).limit(to: 10).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                if querySnapshot!.isEmpty {
                    print("* detected empty feed")
                } else {
                    let mainPostDispatchQueue = DispatchGroup()
                    for document in querySnapshot!.documents {
                        self.documents += [document]
                        print("* got user search results: \(document.documentID) => \(document.data())")
                        
                        let usersRef = self.db.collection("user-locations")
                        mainPostDispatchQueue.enter()
                        
                        usersRef.document(document.documentID).getDocument { (document, error) in
                            if let document = document, document.exists {
                                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                                print("Document data: \(dataDescription)")
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
                                    print("* user has a recent story: \(postVals?["latest_story_timestamp"])")
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
                                //                        let latest_story_timestamp =
                                
                                self.db.collection("followers").document(document.documentID).collection("sub-followers").document(Auth.auth().currentUser!.uid).getDocument { (document, err) in
                                    
                                    var following = false
                                    if ((document?.exists) != nil) && document?.exists == true {
                                        print("* current user is following user")
                                        following = true
                                    }
                                    var userResult = User(uid: userUID, username: username, profileImageUrl: profileImageUrl, bio: "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: full_name, hasValidStory: isValidStory, isFollowing: following)
                                    userResult.location = locationString
                                    self.searchResults.append(userResult)
                                    mainPostDispatchQueue.leave()
                                }
                                
                                
                            } else {
                                print("Document does not exist")
                            }
                            
                        }
                        
                    }
                    mainPostDispatchQueue.notify(queue: .main) {
                        print("* dispatch queue notified, refreshing")
                        if ((querySnapshot?.documents.isEmpty) != nil) && querySnapshot?.documents.isEmpty == true {
                        } else {
//                            self.usersTableView.reloadData {
//                                print("* done reloading")
////                                self.usersTableView.fadeIn()
//                            }
                            self.usersTableView.reloadData()
                            
                            
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
    func styleTopAndBottom() {
        topWhiteView.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
        topWhiteView.layer.cornerRadius = Constants.borderRadius
        topWhiteView.clipsToBounds = true
        if userConfig.shouldhideBackbutton == true {
            topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60)
            topLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
            topLabel.sizeToFit()
            topLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (topLabel.frame.width / 2), y: 20, width: topLabel.frame.width, height: topLabel.frame.height)
        } else {
            topWhiteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 90)
            topLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
            topLabel.sizeToFit()
            topLabel.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (topLabel.frame.width / 2), y: 50, width: topLabel.frame.width, height: topLabel.frame.height)
        }
        
        self.topWhiteView.layer.masksToBounds = false
        self.topWhiteView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.topWhiteView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.topWhiteView.layer.shadowOpacity = 0.3
        self.topWhiteView.layer.shadowRadius = Constants.borderRadius
        

        usersTableView.backgroundColor = .clear
        backButton.frame = CGRect(x: 0, y: 30, width: 50, height: 60)
        backButton.tintColor = .darkGray
        usersTableView.keyboardDismissMode = .onDrag
        usersTableView.separatorStyle = .none
        usersTableView.frame = CGRect(x: 10, y: topWhiteView.frame.maxY, width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height - topWhiteView.frame.height + 20)
        
        searchBar.styleSearchBar()
        searchBar.frame = CGRect(x: 40, y: topWhiteView.frame.maxY + 20, width: UIScreen.main.bounds.width - 80, height: 50)
        searchBar.font = UIFont(name: "\(Constants.globalFont)", size: 15)
        searchBar.textColor = .darkGray
        hideKeyboardWhenTappedAround()
        searchBar.delegate = self
        // handle the editingChanged event by calling (textFieldDidEditingChanged(-:))
        self.searchBar.addTarget(self, action: #selector(textFieldDidEditingChanged(_:)), for: .editingChanged)
        
        magnifyingGlassImage.frame = CGRect(x: searchBar.frame.minX + 15, y: searchBar.frame.minY + 15, width: 20, height: 20)
        usersTableView.backgroundColor = .clear
//        usersTableView.frame = CGRect(x: 10, y: searchBar.frame.maxY + 20, width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height - searchBar.frame.maxY)
        usersTableView.rowHeight = 90
        usersTableView.separatorStyle = .none
        
        
        usersTableView.frame = CGRect(x: 10, y: topWhiteView.frame.maxY, width: UIScreen.main.bounds.width - 20, height: UIScreen.main.bounds.height - topWhiteView.frame.maxY)
        if userConfig.shouldhideBackbutton == true {
            backButton.isHidden = true
        }
    }
    @objc func textFieldDidEditingChanged(_ textField: UITextField) {
        
        // if a timer is already active, prevent it from firing
        if searchTimer != nil {
            searchTimer?.invalidate()
            searchTimer = nil
        }
        
        // reschedule the search: in 1.0 second, call the searchForKeyword method on the new textfield content
        searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(searchForKeyword(_:)), userInfo: textField.text!, repeats: false)
    }
    
    @objc func searchForKeyword(_ timer: Timer) {
        
        // retrieve the keyword from user info
        let keyword = timer.userInfo!
    }
    func resetTableView() {
        hasDoneinitialFetch = false
        documents.removeAll()
        searchResults.removeAll()
        handleMoreLoad()
    }
    func nextChar(str:String) -> String {
        var ret = ""
        if let firstChar = str.unicodeScalars.first {
            let nextUnicode = firstChar.value + 1
            if let var4 = UnicodeScalar(nextUnicode) {
                var nextString = ""
                nextString.append(Character(UnicodeScalar(var4)))
                print(nextString)
                ret = nextString
            }
        }
        return ret
    }
    
    let cellSpacingHeight: CGFloat = 20
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userListCell", for: indexPath) as! userListCell
        let res = searchResults[indexPath.row]
        if userConfig.type == "blocked" {
            cell.isUnblockView = true
        }
        cell.index = indexPath.row
        cell.parentViewController = self
        cell.result = res
        cell.titleLabel.text = res.fullname
        cell.subTitleLabel.text = res.username
        cell.locationLabel.text = res.location ?? "No location"
        cell.selectionStyle = .none
        if res.hasValidStory {
            print("* valid story")
            cell.profilePicButton.isUserInteractionEnabled = true
            cell.profilePicButton.condition = .init(display: .unseen, color: .custom(colors: [hexStringToUIColor(hex: Constants.primaryColor), .blue, hexStringToUIColor(hex: Constants.primaryColor).withAlphaComponent(0.6)]))
        } else {
            print("* no valid story")
            cell.profilePicButton.condition = .init(display: .none, color: .none)
        }
        cell.isUserInteractionEnabled = true
        if Constants.isDebugEnabled {
            //            var window : UIWindow = UIApplication.shared.keyWindow!
            //            window.showDebugMenu()
            self.view.debuggingStyle = true
        }
//        if indexPath.row == searchResults.count - 1 && hasDoneinitialFetch == false {
//            self.usersTableView.setContentOffset(CGPoint(x: 0, y: 80), animated: false)
//            hasDoneinitialFetch = true
//        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("* cell selected: \(searchResults[indexPath.row].uid)")
//        print("* adding offset for table view: \(self.searchBar.frame.height)")
        openProfileForUser(withUID: searchResults[indexPath.row].uid)
        
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "searchHeader") as? TableHeader
        
        return header
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "searchFooter") as? SearchTableFooter
       
        
        return footer
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            // Trigger pagination when scrolled to last cell
        // Feel free to adjust when you? want pagination to be triggered
        if (indexPath.row == (searchResults.count ?? 0)) && hasReachedEndOfFeed == false {
                
            print("* fetching more comments. Current comment count: \((searchResults.count ?? 0))")
                paginate()
            }
        
        // create offset
        if let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last {
                if indexPath == lastVisibleIndexPath {
                    if self.hasDoneinitialFetchForSearch == false {
                        DispatchQueue.main.async {
                            self.usersTableView.setContentOffset(CGPoint(x: 0, y: 74), animated: false)
                            print("* adding offset for table view: 80")
                            self.hasDoneinitialFetchForSearch = true
                        }
                    }
                }
            }
        
    }
    func openProfileForUser(withUID: String) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MyProfileViewController") as? MyProfileViewController {
            vc.uidOfProfile = withUID
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    func paginate() {
            //This line is the main pagination code.
            //Firestore allows you to fetch document from the last queryDocument
        print("* paginate called")
        if hasDoneinitialFetch && documents.count != 0 {
            query = query.start(afterDocument: documents.last!).limit(to: 10)
        }
        handleMoreLoad()
    }
    @IBAction func goBackPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        navigationController?.delegate = self
        _ = navigationController?.popViewController(animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}
class userListCell: UITableViewCell {
    private var db = Firestore.firestore()
    @IBOutlet weak var profilePicButton: IGStoryButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var arrButton: UIButton!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationImage: UIImageView!
    
    @IBOutlet weak var followButton: UIButton!
    
    @IBOutlet weak var unblockButton: UIButton!
    
    var parentViewController: userListViewController?
    var index = 0
    var isUnblockView = false
    
    var result = User(uid: "", username: "", profileImageUrl: "", bio: "", followingCount: 0, followersCount: 0, postsCount: 0, fullname: "", hasValidStory: false, isFollowing: false)
    func styleCell() {
        profilePicButton.setTitle("", for: .normal)
        
        
        let profWid = Int(self.contentView.frame.height - 32)
        let profXY = Int(16)
        profilePicButton.frame = CGRect(x: profXY, y: profXY, width: profWid, height: profWid)
        profilePicButton.layer.cornerRadius = 12
        titleLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
        subTitleLabel.font = UIFont(name: "\(Constants.globalFont)", size: 13)
        
        let titleWidths = Int(Int(self.contentView.frame.width) - profXY - profWid - 10 - 30)
        titleLabel.frame = CGRect(x: Int(profXY + profWid + 10), y: 17, width: titleWidths, height: 16)
        subTitleLabel.frame = CGRect(x: titleLabel.frame.minX + 2, y: titleLabel.frame.maxY, width: CGFloat(titleWidths), height: 15)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true

        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 12
        self.layer.cornerRadius = 12
        self.layer.shadowOpacity = 0.1
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = hexStringToUIColor(hex: "#f0f0f5").cgColor
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        arrButton.layer.cornerRadius = 12
        let arrWit = 30
        arrButton.frame = CGRect(x: Int(self.contentView.frame.width) - arrWit - 15, y: 26, width: arrWit, height: arrWit)
        arrButton.backgroundColor = hexStringToUIColor(hex: "#f0f0f5")
        
        locationImage.frame = CGRect(x: titleLabel.frame.minX-1, y: subTitleLabel.frame.maxY+3, width: 10, height: 10)
        locationImage.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        locationLabel.frame = CGRect(x: locationImage.frame.maxX + 3, y: locationImage.frame.minY - 2, width: self.contentView.frame.width - CGFloat(profWid) - 30, height: 14)
        locationLabel.textColor = hexStringToUIColor(hex: Constants.primaryColor)
        locationLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 10)
        if result.profileImageUrl == "" {
            profilePicButton.image = UIImage(named: "no-profile-img.jpeg")
        } else {
            downloadImage(with: result.profileImageUrl)
        }
        
        arrButton.isHidden = true
        if result.isFollowing {
            print("* styling button for isfollowing")
            styleForFollowing()
        } else {
            print("* styling for not following")
            styleForNotFollowing()
        }
        let followbuttonwidth = 100
        followButton.frame = CGRect(x: Int(self.contentView.frame.width) - followbuttonwidth - 20, y: Int(22.5), width: followbuttonwidth, height: 35)
        if result.uid == Auth.auth().currentUser?.uid || isUnblockView == true {
            followButton.isHidden = true
        }
        if isUnblockView == true {
            unblockButton.isHidden = false
            unblockButton.frame = followButton.frame
            self.unblockButton.setTitle("Unblock", for: .normal)
            self.unblockButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
            self.unblockButton.tintColor = .black
            self.unblockButton.clipsToBounds = true
            self.unblockButton.layer.cornerRadius = 12
        }
//        self.followButton.center.y = self.contentView.frame.center.y
//        self.followButton.fadeIn()
//        arrButton.center.y = self.contentView.center.y
    }
    @IBAction func unblockButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
        print("* unblocking \(result.uid)")
        db.collection("blocked").document(userID!).collection("blocked_users").document(result.uid).delete()
        print("* removing row at index \(index)")
        self.parentViewController?.usersTableView.beginUpdates()
        self.parentViewController?.searchResults.remove(at: index)
        self.parentViewController?.usersTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        self.parentViewController?.usersTableView.endUpdates()
        self.parentViewController?.usersTableView.reloadData()
    }
    @IBAction func followButtonPressed(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let userID = Auth.auth().currentUser?.uid
//        self.isUserInteractionEnabled = false
        print("* follow button pressed")
        if self.parentViewController?.searchResults[self.index].isFollowing == false {
            print("* following user")
            styleForFollowing()
            let timestamp = NSDate().timeIntervalSince1970
            self.db.collection("user-locations").document(userID!).getDocument { (document, err) in
                print("* doc: \(document)")
                if ((document?.exists) != nil) && document?.exists == true {
                    let data = document?.data()! as [String: AnyObject]
                    self.db.collection("followers").document(self.result.uid).collection("sub-followers").document(userID!).setData(["uid": userID, "timestamp": Int(timestamp), "username": data["username"] as? String ?? ""]) { err in
//                        self.isUserInteractionEnabled = true
                        
                        if let err = err {
                            print("Error writing document: \(err)")
                            self.styleForNotFollowing()
                        } else {
                            print("succesfully followed user!")
                            self.parentViewController?.searchResults[self.index].isFollowing = true
                        }
                    }
                }
            }
        } else {
            print("* unfollowing user")
            styleForNotFollowing()
            self.db.collection("followers").document(result.uid).collection("sub-followers").document(userID!).delete() { err in
                if let err = err {
                    print("Error writing document: \(err)")
                    self.styleForFollowing()
                } else {
                    print("succesfully unfollowed user!")
                    self.parentViewController?.searchResults[self.index].isFollowing = false
                }
            }
        }
    }
    func styleForFollowing() {
        self.followButton.setTitle("Following", for: .normal)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: "#ececec")
        self.followButton.tintColor = .black
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 8
        self.followButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.followButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.followButton.setImage(UIImage(systemName: "chevron.down")?.applyingSymbolConfiguration(.init(pointSize: 8, weight: .semibold, scale: .medium))?.image(withTintColor: .black), for: .normal)
        self.followButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        let spacing = CGFloat(-10); // the amount of spacing to appear between image and title
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: -2, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    }
    func styleForNotFollowing() {
        self.followButton.setTitle("Follow", for: .normal)
        self.followButton.backgroundColor = self.hexStringToUIColor(hex: Constants.primaryColor)
        self.followButton.tintColor = .white
        self.followButton.clipsToBounds = true
        self.followButton.layer.cornerRadius = 8
        self.followButton.setImage(nil, for: .normal)
        followButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        followButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func downloadImage(`with` urlString : String) {
        guard let url = URL.init(string: urlString) else {
            return
        }
        let resource = ImageResource(downloadURL: url)
        let processor = DownsamplingImageProcessor(size: CGSize(width: profilePicButton.frame.width, height: profilePicButton.frame.height))
        KingfisherManager.shared.retrieveImage(with: resource, options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.25)),
            .cacheOriginalImage
        ], progressBlock: nil) { result in
            switch result {
            case .success(let value):
                self.profilePicButton.image = value.image
            case .failure(let error):
                print("Error: \(error)")
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
    // Inside UITableViewCell subclass

    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
        styleCell()
    }
}
extension UITableView {
    func reloadData(completion:@escaping ()->()) {
        UIView.animate(withDuration: 0, animations: reloadData)
            { _ in completion() }
    }
}
