//  Egg.
//
//  Created by Jordan Wood on 5/15/22.
//

import UIKit
import Foundation
import SwiftKeychainWrapper
import SwipeableTabBarController
import FirebaseAuth
import FirebaseFirestore
struct Constants {
    static let borderRadius: CGFloat = 12
//    static let globalFont: String = "HelveticaNeue"
    static let globalFont: String = "PlusJakartaSans-Regular"
    static let globalFontBold: String = "PlusJakartaSansRoman-Bold"
    static let globalFontMedium: String = "PlusJakartaSansRoman-SemiBold"
    static let globalFontItali: String = "PlusJakartaSans-Italic"
    
//    purple theme
    static let primaryColor: String = "#5e5cf5"
    static let secondaryColor: String = "#dddcfd"
    static let backgroundColor: String = "#f8f8f8"
    static let surfaceColor: String = "#ffffff"
    static let textColor: String = "#000000"
    
    // blue theme
//    static let primaryColor: String = "#3484f0"
//    static let secondaryColor: String = "#c4dbfa"
    

    
//    static let backgroundColor: String = "#000000"
//    static let surfaceColor: String = "#222222"
//    static let textColor: String = "#ffffff"
//    static let secondaryColor: String = "#222222"
    
    static let groupPrimaryColor: String = "#8D4AC0"
    static let groupSecondaryColor: String = "#e4cbf7"
    
    static let eventPrimaryColor: String = "#e69030"
    static let eventSecondaryColor: String = "#f7e0c6"
    
    static let isDebugEnabled = false
    
    static let imagePadding = 1
    
    static let universalRed: String = "#d9554e"
    
    static let isDarkmode: Bool = false
    
}
class mainTabBarController: UITabBarController, UITabBarControllerDelegate {
    let defaults = UserDefaults.standard
    var customTabBarView = UIView(frame: .zero)
    var selectedTabBarViewMover: UIView?
    var plusButton: UIImageView?
    var profileImageView: UIImageView?
    let tabBarWidthHeight = 40
    var hasSetDefaultCase = false
    var shouldSetRedTing = false
    
    private var db = Firestore.firestore()
    
    var redNotificationsCircle: UIView?
    
    var notificationsPopup = UIView(frame: .zero)
    override func viewDidLoad() {
        super.viewDidLoad()
//        logout()
        
        // Do any additional setup after loading the view.
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
        self.setupTabBarUI()
        self.addCustomTabBarView()
        self.setupTabBarViewer()
        self.tabBarController?.selectedIndex = 0
        self.delegate = self
        if  let arrayOfTabBarItems = self.tabBar.items as! AnyObject as? NSArray,let tabBarItem = arrayOfTabBarItems[2] as? UITabBarItem {
            tabBarItem.isEnabled = false
            }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(plusTapped(tapGestureRecognizer:)))
        self.plusButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        plusButton?.isUserInteractionEnabled = true
        plusButton?.addGestureRecognizer(tapGestureRecognizer)
        plusButton?.image = UIImage(systemName: "plus.app.fill")
        plusButton?.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        let widthHeight = 30
        plusButton?.frame = CGRect(x: Int(UIScreen.main.bounds.width) / 2 - widthHeight / 2, y: 18, width: widthHeight, height: widthHeight)
        plusButton?.contentMode = .scaleAspectFit
        self.tabBar.bringSubviewToFront(plusButton!)
        self.tabBar.addSubview(plusButton!)
        
        notificationsPopup.isUserInteractionEnabled = false
        notificationsPopup.backgroundColor = Constants.universalRed.hexToUiColor()
        notificationsPopup.layer.cornerRadius = 8
        notificationsPopup.frame = CGRect(x: Int(UIScreen.main.bounds.width) / 2 - widthHeight / 2, y: -18, width: widthHeight, height: widthHeight)
        
        self.profileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        profileImageView?.isUserInteractionEnabled = false
        profileImageView?.layer.cornerRadius = 10
        profileImageView?.clipsToBounds = true
        profileImageView?.image = UIImage(named: "no-profile-img.jpeg")
//        profileImageView?.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
//        let widthHeight = 30
        let xee = Int(UIScreen.main.bounds.width) - widthHeight - 25
        profileImageView?.frame = CGRect(x: Int(xee), y: Int(18), width: widthHeight+2, height: widthHeight+2)
            profileImageView?.contentMode = .scaleAspectFill
        profileImageView?.layer.borderColor = UIColor.white.cgColor
        profileImageView?.layer.borderWidth = 3
        DispatchQueue.global(qos: .background).async {
            if let savedImage = self.retrieveImage(forKey: "profilepic",
                                                   inStorageType: .fileSystem) {
                DispatchQueue.main.async {
                    self.profileImageView?.image = savedImage
                }
            }
        }
            self.tabBar.addSubview(profileImageView!)
        
        
        if Constants.isDebugEnabled {
//            var window : UIWindow = UIApplication.shared.keyWindow!
//            window.showDebugMenu()
            self.view.debuggingStyle = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("* DID LAYOUT SUBVIEWS")
        self.setupCustomTabBarFrame()
        if hasSetDefaultCase == false {
            selectedTabBarViewMover?.frame = CGRect(x: Int(self.tabBar.getFrameForTabAt(index: 0)!.centerX) - tabBarWidthHeight / 2, y: Int(self.tabBar.getFrameForTabAt(index: 0)!.centerY) - (tabBarWidthHeight / 2) + 2, width: tabBarWidthHeight, height: tabBarWidthHeight)
            
            hasSetDefaultCase = true
        }
        
        
        
    }
    @objc func plusTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
        print("pushing camera view")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController")
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        //This method will be called when user changes tab.
        //move tab bar view mover
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            let newXC = Int(self.tabBar.getFrameForTabAt(index: (tabBar.items?.firstIndex(of: item))!)!.centerX) - self.tabBarWidthHeight / 2
            self.selectedTabBarViewMover?.frame = CGRect(x: newXC, y: Int(self.tabBar.getFrameForTabAt(index: (tabBar.items?.firstIndex(of: item))!)!.centerY) - (self.tabBarWidthHeight / 2) + 2, width: self.tabBarWidthHeight, height: self.tabBarWidthHeight)
            if (tabBar.items?.firstIndex(of: item))! == 3 {
                self.redNotificationsCircle?.alpha = 0
                self.shouldSetRedTing = false
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        })
    }
    private func setupTabBarViewer() {
        selectedTabBarViewMover = UIView()
        
        
        selectedTabBarViewMover?.frame = CGRect(x: Int(self.tabBar.getFrameForTabAt(index: 0)!.centerX) - tabBarWidthHeight / 2, y: Int(self.tabBar.getFrameForTabAt(index: 0)!.centerY) - (tabBarWidthHeight / 2) + 2, width: tabBarWidthHeight, height: tabBarWidthHeight)
        selectedTabBarViewMover?.backgroundColor = hexStringToUIColor(hex: Constants.secondaryColor) //used to be white
        selectedTabBarViewMover?.layer.cornerRadius = Constants.borderRadius
        self.tabBar.addSubview(selectedTabBarViewMover!)
        self.tabBar.sendSubviewToBack(selectedTabBarViewMover!)
        
        self.selectedTabBarViewMover!.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.selectedTabBarViewMover!.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.selectedTabBarViewMover!.layer.shadowOpacity = 0.5
        self.selectedTabBarViewMover!.layer.shadowRadius = Constants.borderRadius
        if #available(iOS 15, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.backgroundColor = hexStringToUIColor(hex: Constants.surfaceColor)
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black]
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray //used to be black
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = hexStringToUIColor(hex: Constants.primaryColor) //used to be black
            self.tabBar.standardAppearance = tabBarAppearance
            self.tabBar.scrollEdgeAppearance = tabBarAppearance
            self.tabBar.layer.cornerRadius = Constants.borderRadius
            self.customTabBarView.layer.cornerRadius = Constants.borderRadius
            self.tabBar.clipsToBounds = true
        }
        handleRedView()
    }
    func handleRedView() {
        
        let userID = Auth.auth().currentUser?.uid
        if userID != nil {
            let notifQuery = db.collection("notifications").document(userID!)
            notifQuery.getDocument() { [self] (document, error) in
                if let document = document {
                    let data = document.data() as? [String: AnyObject]
                    let totalCount = data?["notifications_count"] as? Int ?? 0
                    let commentsCount = data?["num_comments_notifications"] as? Int ?? 0
                    let followersCount = data?["num_followers_notifications"] as? Int ?? 0
                    let numPostLikes = data?["num_likes_notifications"] as? Int ?? 0
                    let numCommentLikes = data?["num_comments_likes_notifications"] as? Int ?? 0
                    let numMentiones = data?["num_mentions_notifications"] as? Int ?? 0
                    UIApplication.shared.applicationIconBadgeNumber = totalCount
                    if commentsCount == 0 && followersCount == 0 && numPostLikes == 0 && numCommentLikes == 0 && numMentiones == 0 {
                        print("* [tab bar] user has no new notifications")
                        shouldSetRedTing = false
                        
                    } else {
                        print("* [tab bar] user has some new notifs")
                        shouldSetRedTing = true
                        let wid = 5
                        redNotificationsCircle = UIView(frame: CGRect(x: 0, y: Int((self.tabBar.getFrameForTabAt(index: 3)!).maxY) - 16, width: wid, height: wid))
                        redNotificationsCircle?.center.x = (self.tabBar.getFrameForTabAt(index: 3)!).centerX
                        redNotificationsCircle?.layer.cornerRadius = (redNotificationsCircle?.frame.width ?? 0) / 2
                        print("* red circle frame = \(redNotificationsCircle!)")
                        redNotificationsCircle?.backgroundColor = Constants.universalRed.hexToUiColor()
                        self.tabBar.addSubview(redNotificationsCircle!)
                        self.tabBar.bringSubviewToFront(redNotificationsCircle!)
                        redNotificationsCircle?.alpha = 0
                        redNotificationsCircle?.fadeIn()
                    }
                }
            }
        }
//        if shouldSetRedTing {
//            print("* [tab bar] handleredview -- showing red circle")
//            
//        } else {
//            print("* [tab bar] handleredview -- not showing red circle")
//            
//        }
    }
    // MARK: Private methods
    
    private func setupCustomTabBarFrame() {
        let height = self.view.safeAreaInsets.bottom + 64
        
        var tabFrame = self.tabBar.frame
        tabFrame.size.height = height
        tabFrame.origin.y = self.view.frame.size.height - height
        
        self.tabBar.frame = tabFrame
        self.tabBar.setNeedsLayout()
        self.tabBar.layoutIfNeeded()
        customTabBarView.frame = tabBar.frame
        
        if let fr = self.tabBar.getFrameForTabAt(index: 4) {
            self.profileImageView?.center.x = CGFloat(fr.centerX)
        }
        
//        self.profileImageView?.center.y = CGFloat(self.tabBar.getFrameForTabAt(index: 4)!.centerY)
    }
    private func setupTabBarUI() {
        // Setup your colors and corner radius
        self.tabBar.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        self.tabBar.layer.cornerRadius = Constants.borderRadius
        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.tabBar.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        self.tabBar.tintColor = UIColor.lightGray //used to be black
        self.tabBar.unselectedItemTintColor = UIColor.lightGray //used to be black
        // Remove the line
        if #available(iOS 13.0, *) {
            let appearance = self.tabBar.standardAppearance
            appearance.shadowImage = nil
            appearance.shadowColor = nil
            self.tabBar.standardAppearance = appearance
        } else {
            self.tabBar.shadowImage = UIImage()
            self.tabBar.backgroundImage = UIImage()
        }
    }
    
    private func addCustomTabBarView() {
        self.customTabBarView.frame = tabBar.frame
        
        self.customTabBarView.backgroundColor = hexStringToUIColor(hex: Constants.backgroundColor)
        self.customTabBarView.layer.cornerRadius = 30
        self.customTabBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        self.customTabBarView.layer.masksToBounds = false
        self.customTabBarView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        self.customTabBarView.layer.shadowOffset = CGSize(width: 0, height: -10)
        self.customTabBarView.layer.shadowOpacity = 0.3
        self.customTabBarView.layer.shadowRadius = 20
        
        self.view.addSubview(customTabBarView)
        self.view.bringSubviewToFront(self.tabBar)
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


extension UITabBar {
    
    func getFrameForTabAt(index: Int) -> CGRect? {
        var frames = self.subviews.compactMap { return $0 is UIControl ? $0.frame : nil }
        frames.sort { $0.origin.x < $1.origin.x }
        return frames[safe: index]
    }
    
}

extension Collection {
    
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}
extension CGRect
{
    /** Creates a rectangle with the given center and dimensions
     - parameter center: The center of the new rectangle
     - parameter size: The dimensions of the new rectangle
     */
    init(center: CGPoint, size: CGSize)
    {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
    
    /** the coordinates of this rectangles center */
    var center: CGPoint
    {
        get { return CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }
    
    /** the x-coordinate of this rectangles center
     - note: Acts as a settable midX
     - returns: The x-coordinate of the center
     */
    var centerX: CGFloat
    {
        get { return midX }
        set { origin.x = newValue - width * 0.5 }
    }
    
    /** the y-coordinate of this rectangles center
     - note: Acts as a settable midY
     - returns: The y-coordinate of the center
     */
    var centerY: CGFloat
    {
        get { return midY }
        set { origin.y = newValue - height * 0.5 }
    }
    
    // MARK: - "with" convenience functions
    
    /** Same-sized rectangle with a new center
     - parameter center: The new center, ignored if nil
     - returns: A new rectangle with the same size and a new center
     */
    func with(center: CGPoint?) -> CGRect
    {
        return CGRect(center: center ?? self.center, size: size)
    }
    
    /** Same-sized rectangle with a new center-x
     - parameter centerX: The new center-x, ignored if nil
     - returns: A new rectangle with the same size and a new center
     */
    func with(centerX: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX ?? self.centerX, y: centerY), size: size)
    }
    
    /** Same-sized rectangle with a new center-y
     - parameter centerY: The new center-y, ignored if nil
     - returns: A new rectangle with the same size and a new center
     */
    func with(centerY: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX, y: centerY ?? self.centerY), size: size)
    }
    
    /** Same-sized rectangle with a new center-x and center-y
     - parameter centerX: The new center-x, ignored if nil
     - parameter centerY: The new center-y, ignored if nil
     - returns: A new rectangle with the same size and a new center
     */
    func with(centerX: CGFloat?, centerY: CGFloat?) -> CGRect
    {
        return CGRect(center: CGPoint(x: centerX ?? self.centerX, y: centerY ?? self.centerY), size: size)
    }
}
