//
//  LoginViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 5/17/22.
//
import UIKit
import Foundation
import SwiftKeychainWrapper
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics
import Presentr
import GoogleSignIn
import CryptoKit
import AuthenticationServices
//import IHProgressHUD
//import SnapS
//import SCSDKLoginKit
extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}
class LoginViewController: UIViewController, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    @IBOutlet weak var LoginView: UIView!
    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var DontHaveAnAccountButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var otherSigninOptionsLabel: UILabel!
    @IBOutlet weak var googleSignInButton: UIButton!
    @IBOutlet weak var appleSignInButton: UIButton!
    @IBOutlet weak var twitterSignInButton: UIButton!
    @IBOutlet weak var googleSignInImage: UIImageView!
    @IBOutlet weak var appleSignInImage: UIImageView!
    @IBOutlet weak var twitterSignInImage: UIImageView!
    
    
    @IBOutlet weak var SignUpView: UIView!
    @IBOutlet weak var SignupButton: UIButton!
    @IBOutlet weak var backbutton: UIButton!
    @IBOutlet weak var GoBackToLoginButton: UIButton!
    @IBOutlet weak var SignupemailTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var SignuppasswordTextField: UITextField!
    
    @IBOutlet weak var signUpLabel: UILabel!
    
    @IBOutlet weak var brodiesDudeLogo: UIImageView!
    @IBOutlet weak var brodiesLogo: UIImageView!
    
    // Unhashed nonce.
    fileprivate var currentNonce: String?
    
    var alert: UIAlertController?
    let presenter = Presentr(presentationType: .alert)
    var numberOfFailedAttempts = 0
    
    private var db = Firestore.firestore()
    
    var hasTopNotch: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.backgroundColor = hexStringToUIColor(hex: "#f5f5f5")
        self.view.backgroundColor = Constants.surfaceColor.hexToUiColor()
        backbutton.setTitle("", for: .normal)
        if UIDevice.current.hasNotch {
            //... consider notch
            hasTopNotch = true
        }
//        SCSDKLoginClient.startFirebaseAuth(from: self, completion: <#T##SCFirebaseAuthCompletionBlock##SCFirebaseAuthCompletionBlock##(String?, Error?) -> Void#>)
        StyleLoginComponents()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser?.uid == nil {
//            LoginButton.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 40 - 60, width: UIScreen.main.bounds.width - 80, height: 53) //put it at bottom
            print("loaded login screen")
            
            self.hideKeyboardWhenTappedAround()
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(self.googleImageTapped))
            googleSignInImage.addGestureRecognizer(tapGR)
            googleSignInImage.isUserInteractionEnabled = true
        } else {
            print("looks like user is logged in, going back to home")
            navigationController?.popViewController(animated: true)

            dismiss(animated: true, completion: nil)
        }
    }
    func StyleLoginComponents() {
        let widHeight = 110
        brodiesDudeLogo.frame = CGRect(x: (Int(UIScreen.main.bounds.width) / 2)-widHeight/2, y: 70, width: widHeight, height: widHeight)
        let brodWidth = 80
        let brodHeight = 40
        brodiesLogo.frame = CGRect(x: 0, y: Int(brodiesDudeLogo.frame.maxY), width: brodWidth, height: brodHeight)
        signInLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
        signInLabel.frame = CGRect(x: 20, y: brodiesLogo.frame.maxY + 30, width: UIScreen.main.bounds.width - 40, height: 30)
        backbutton.frame = CGRect(x: 20, y: 60, width: 30, height: 30)
        DontHaveAnAccountButton.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 80, width: UIScreen.main.bounds.width - 80, height: 30)
        if hasTopNotch == false {
            print("* no notch, addapting")
            brodiesDudeLogo.frame = CGRect(x: (Int(UIScreen.main.bounds.width) / 2)-60/2, y: 30, width: 60, height: 60)
            brodiesLogo.frame = CGRect(x: 0, y: Int(brodiesDudeLogo.frame.maxY), width: 60, height: 30)
            signInLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 13)
            signInLabel.frame = CGRect(x: 20, y: brodiesLogo.frame.maxY + 10, width: UIScreen.main.bounds.width - 40, height: 30)
            backbutton.frame = CGRect(x: 20, y: 20, width: 30, height: 30)
            DontHaveAnAccountButton.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 40, width: UIScreen.main.bounds.width - 80, height: 30)
        }
        brodiesLogo.center.x = UIScreen.main.bounds.width / 2
        LoginButton.backgroundColor = hexStringToUIColor (hex:Constants.primaryColor)
        LoginButton.layer.cornerRadius = 4
        LoginButton.layer.shadowColor = hexStringToUIColor (hex:Constants.primaryColor).withAlphaComponent(0.3).cgColor
        LoginButton.layer.shadowOffset = CGSize(width: 4, height: 10)
        LoginButton.layer.shadowOpacity = 0.5
        LoginButton.layer.shadowRadius = 4
        LoginButton.titleLabel!.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        passwordTextField.isSecureTextEntry = true
        
        SignupButton.backgroundColor = hexStringToUIColor (hex:Constants.primaryColor)
        SignupButton.layer.cornerRadius = 4
        SignupButton.layer.shadowColor = hexStringToUIColor (hex:Constants.primaryColor).withAlphaComponent(0.3).cgColor
        SignupButton.layer.shadowOffset = CGSize(width: 4, height: 10)
        SignupButton.layer.shadowOpacity = 0.5
        SignupButton.layer.shadowRadius = 4
        SignupButton.titleLabel!.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        
//        backbutton.layer.cornerRadius = 4
//        backbutton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
//        backbutton.layer.shadowOffset = CGSize(width: 4, height: 10)
//        backbutton.layer.shadowOpacity = 0.5
//        backbutton.layer.shadowRadius = 4
        
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
//        emailTextField.leftView = paddingView
//        emailTextField.leftViewMode = .always
//        passwordTextField.leftView = paddingView
//        passwordTextField.leftViewMode = .always
        
        
        DontHaveAnAccountButton.backgroundColor = .clear
        DontHaveAnAccountButton.titleLabel?.textColor = hexStringToUIColor(hex: Constants.primaryColor)
        DontHaveAnAccountButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 12)
        DontHaveAnAccountButton.tintColor = hexStringToUIColor(hex: Constants.primaryColor)
        
        
        
        signUpLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
        signUpLabel.frame = CGRect(x: backbutton.frame.maxX + 10, y: backbutton.frame.minY, width: UIScreen.main.bounds.width - 40, height: 30)
        
        emailTextField.frame = CGRect(x: 20, y: signInLabel.frame.maxY + 20, width: UIScreen.main.bounds.width - 40, height: 53)
        emailTextField.styleSearchBar()
        emailTextField.backgroundColor = Constants.backgroundColor.hexToUiColor()
//        emailTextField.frame = CGRect(x: 40, y: signInLabel.frame.maxY + 20, width: UIScreen.main.bounds.width - 80, height: 53)
        let paddingViewz: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        emailTextField.leftView = paddingViewz
        emailTextField.leftViewMode = .always
        
        passwordTextField.frame = CGRect(x: 20, y: emailTextField.frame.maxY + 20, width: UIScreen.main.bounds.width - 40, height: 53)
        passwordTextField.styleSearchBar()
        passwordTextField.backgroundColor = Constants.backgroundColor.hexToUiColor()
        let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        passwordTextField.leftView = paddingView2
        passwordTextField.leftViewMode = .always
        
        LoginButton.frame = CGRect(x: 40, y: passwordTextField.frame.maxY + 30, width: UIScreen.main.bounds.width - 80, height: 53)
        
        otherSigninOptionsLabel.frame = CGRect(x: 40, y: LoginButton.frame.maxY + 100, width: UIScreen.main.bounds.width - 80, height: 20)
        if hasTopNotch == false {
            otherSigninOptionsLabel.frame = CGRect(x: 40, y: LoginButton.frame.maxY + 20, width: UIScreen.main.bounds.width - 80, height: 20)
        }
        otherSigninOptionsLabel.textAlignment = .center
        otherSigninOptionsLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
        
        let spaceBetweenOtherSignins = 10
        let widthForOtherSignins = (Int(UIScreen.main.bounds.width) - 80 - (spaceBetweenOtherSignins*2)) / 2
        let signinOptionsY = otherSigninOptionsLabel.frame.maxY + 20
        var signinbuttonsHeight = 53
        if hasTopNotch == false {
            signinbuttonsHeight = 40
        }
        googleSignInButton.frame = CGRect(x: 40, y: Int(signinOptionsY), width: widthForOtherSignins, height: signinbuttonsHeight)
        appleSignInButton.frame = CGRect(x: Int(googleSignInButton.frame.maxX) + spaceBetweenOtherSignins, y: Int(signinOptionsY), width: widthForOtherSignins, height: signinbuttonsHeight)
        twitterSignInButton.frame = CGRect(x: Int(appleSignInButton.frame.maxX) + spaceBetweenOtherSignins, y: Int(signinOptionsY), width: widthForOtherSignins, height: signinbuttonsHeight)
        googleSignInButton.layer.cornerRadius = 4
        appleSignInButton.layer.cornerRadius = 4
        twitterSignInButton.layer.cornerRadius = 4
        
        let imageSize = 25 //in pixels
        let xForImage = (widthForOtherSignins - (imageSize*2)) / 2
        googleSignInImage.frame = CGRect(x: Int(googleSignInButton.frame.maxX)+xForImage, y: Int(googleSignInButton.frame.minY) + ((signinbuttonsHeight - imageSize) / 2), width: imageSize, height: imageSize)
        googleSignInImage.frame.centerX = googleSignInButton.frame.centerX
        twitterSignInImage.frame = CGRect(x: Int(twitterSignInButton.frame.maxX)+xForImage, y: Int(twitterSignInButton.frame.minY) + ((signinbuttonsHeight - imageSize) / 2), width: imageSize, height: imageSize)
        twitterSignInImage.frame.centerX = twitterSignInButton.frame.centerX
        appleSignInImage.frame = CGRect(x: Int(appleSignInButton.frame.maxX)+xForImage, y: Int(appleSignInButton.frame.minY) + ((signinbuttonsHeight - imageSize) / 2), width: imageSize, height: imageSize)
        appleSignInImage.frame.centerX = appleSignInButton.frame.centerX
        
        googleSignInButton.layer.cornerRadius = 4
        googleSignInButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        googleSignInButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        googleSignInButton.layer.shadowOpacity = 0.5
        googleSignInButton.layer.shadowRadius = 4
        googleSignInButton.backgroundColor = Constants.backgroundColor.hexToUiColor()
        
//        twitterSignInButton.layer.cornerRadius = 4
//        twitterSignInButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
//        twitterSignInButton.layer.shadowOffset = CGSize(width: 0, height: 4)
//        twitterSignInButton.layer.shadowOpacity = 0.5
//        twitterSignInButton.layer.shadowRadius = 4
//        SignupButton.setTitle("Continue", for: .normal)
        appleSignInButton.layer.cornerRadius = 4
        appleSignInButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        appleSignInButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        appleSignInButton.layer.shadowOpacity = 0.5
        appleSignInButton.layer.shadowRadius = 4
        appleSignInButton.backgroundColor = Constants.backgroundColor.hexToUiColor()
        
        LoginView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        SignUpView.frame = LoginView.frame
    }
    func dismissAndReload() {
        self.dismiss(animated: true)
        UIApplication.shared.keyWindow?.rootViewController = storyboard!.instantiateViewController(withIdentifier: "Root_View")
    }
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError(
              "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }

        
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
        
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.presentationContextProvider = self
      authorizationController.performRequests()
    }
    @IBAction func signInWithApplePayPressed(_ sender: Any) {
        startSignInWithAppleFlow()
    }
    @IBAction func dontHaveAccountPressed(_ sender: Any) {
        LoginView.fadeOut()
        emailTextField.fadeOut()
        passwordTextField.fadeOut()
        googleSignInImage.fadeOut()
        appleSignInImage.fadeOut()
        twitterSignInImage.fadeOut()
        googleSignInButton.fadeOut()
        appleSignInButton.fadeOut()
        twitterSignInButton.fadeOut()
        otherSigninOptionsLabel.fadeOut()
        brodiesLogo.fadeOut()
        brodiesDudeLogo.fadeOut()
        DispatchQueue.global(qos: .background).async {
            let second: Double = 1000000
            usleep(useconds_t(0.3 * second))
            print("Active after 0.3 sec, and doesn't block main")
            DispatchQueue.main.async{
                //do stuff in the main thread here
                self.signUpLabel.fadeIn()
                self.SignupButton.fadeIn()
                self.emailTextField.fadeIn()
                self.passwordTextField.fadeIn()
                self.firstNameTextField.frame = CGRect(x: 20, y: self.signUpLabel.frame.maxY + 20, width: ((UIScreen.main.bounds.width - 40) / 2) - 5, height: 53)
                self.firstNameTextField.styleSearchBar()
                self.firstNameTextField.backgroundColor = Constants.backgroundColor.hexToUiColor()
                let paddingView2: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
                self.firstNameTextField.leftView = paddingView2
                self.firstNameTextField.leftViewMode = .always
                self.lastNameTextField.frame = CGRect(x: self.firstNameTextField.frame.maxX + 10, y: self.firstNameTextField.frame.minY, width: ((UIScreen.main.bounds.width - 40) / 2) - 5, height: 53)
                self.lastNameTextField.styleSearchBar()
                self.lastNameTextField.backgroundColor = Constants.backgroundColor.hexToUiColor()
                let paddingView3: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
                self.lastNameTextField.leftView = paddingView3
                self.lastNameTextField.leftViewMode = .always
                self.usernameTextField.frame = CGRect(x: 20, y: self.lastNameTextField.frame.maxY + 10, width: UIScreen.main.bounds.width - 40, height: 53)
                self.usernameTextField.styleSearchBar()
                self.usernameTextField.backgroundColor = Constants.backgroundColor.hexToUiColor()
                let paddingView5: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
                self.usernameTextField.leftView = paddingView5
                self.usernameTextField.leftViewMode = .always
                self.emailTextField.frame = CGRect(x: 20, y: self.usernameTextField.frame.maxY + 10, width: UIScreen.main.bounds.width - 40, height: 53)
                self.passwordTextField.frame = CGRect(x: 20, y: self.emailTextField.frame.maxY + 10, width: UIScreen.main.bounds.width - 40, height: 53)
                self.LoginButton.frame = CGRect(x: 20, y: self.passwordTextField.frame.maxY + 30, width: UIScreen.main.bounds.width - 40, height: 53)
//                self.SignuppasswordTextField.frame = CGRect(x: 40, y: self.passwordTextField.frame.maxY + 10, width: UIScreen.main.bounds.width - 80, height: 53)
                self.SignupButton.frame = CGRect(x: 40, y: self.passwordTextField.frame.maxY + 30, width: UIScreen.main.bounds.width - 80, height: 53)
                self.otherSigninOptionsLabel.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 150, width: UIScreen.main.bounds.width - 80, height: 20)
                
                
                
                let spaceBetweenOtherSignins = 10
                let widthForOtherSignins = (Int(UIScreen.main.bounds.width) - 80 - (spaceBetweenOtherSignins*2)) / 2
                let signinOptionsY = self.otherSigninOptionsLabel.frame.maxY + 10
                
                self.googleSignInButton.frame = CGRect(x: 40, y: Int(signinOptionsY), width: widthForOtherSignins, height: 53)
                self.appleSignInButton.frame = CGRect(x: Int(self.googleSignInButton.frame.maxX) + spaceBetweenOtherSignins, y: Int(signinOptionsY), width: widthForOtherSignins, height: 53)
                self.twitterSignInButton.frame = CGRect(x: Int(self.appleSignInButton.frame.maxX) + spaceBetweenOtherSignins, y: Int(signinOptionsY), width: widthForOtherSignins, height: 53)
                self.googleSignInButton.layer.cornerRadius = 4
                self.appleSignInButton.layer.cornerRadius = 4
                self.twitterSignInButton.layer.cornerRadius = 4
                
                let imageSize = 25 //in pixels
                let xForImage = (widthForOtherSignins - (imageSize*2)) / 2
                self.googleSignInImage.frame = CGRect(x: Int(self.googleSignInButton.frame.maxX)+xForImage, y: Int(self.googleSignInButton.frame.minY) + ((53 - imageSize) / 2), width: imageSize, height: imageSize)
                self.googleSignInImage.frame.centerX = self.googleSignInButton.frame.centerX
                self.twitterSignInImage.frame = CGRect(x: Int(self.twitterSignInButton.frame.maxX)+xForImage, y: Int(self.twitterSignInButton.frame.minY) + ((53 - imageSize) / 2), width: imageSize, height: imageSize)
                self.twitterSignInImage.frame.centerX = self.twitterSignInButton.frame.centerX
                self.appleSignInImage.frame = CGRect(x: Int(self.appleSignInButton.frame.maxX)+xForImage, y: Int(self.appleSignInButton.frame.minY) + ((53 - imageSize) / 2), width: imageSize, height: imageSize)
                self.appleSignInImage.frame.centerX = self.appleSignInButton.frame.centerX
                
                self.googleSignInImage.fadeIn()
                self.appleSignInImage.fadeIn()
                self.twitterSignInImage.fadeIn()
                self.googleSignInButton.fadeIn()
                self.appleSignInButton.fadeIn()
//                self.twitterSignInButton.fadeIn()
                self.otherSigninOptionsLabel.fadeIn()
                self.SignUpView.fadeIn()
            }
        }
    }
    @IBAction func signUpPressed(_ sender: Any) {
        let firstName = firstNameTextField.text
        let lastName = lastNameTextField.text
        let email = emailTextField.text
        let username = usernameTextField.text
        let password = passwordTextField.text
        let password_confirmation = SignuppasswordTextField.text
        
        if firstName != "" && lastName != "" && email != "" && password != "" && username != "" {
            LoadingOverlay.shared.showOverlay(view: self.view)
            FirebaseAnalytics.Analytics.logEvent("email_account_INIT", parameters: [AnalyticsParameterScreenName: "login_view"])
            Auth.auth().createUser(withEmail: email!, password: password!) { authResult, error in
              // ...
//              "email": "\(email ?? "")",
                self.db.collection("users").document((authResult?.user.uid)!).setData([
                    "full_name": "\(firstName ?? "") \(lastName ?? "")",
                    "profileImageURL": "",
                    "username": "\(username?.lowercased() ?? "")"
                ], merge: true) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        DispatchQueue.main.async {
                            LoadingOverlay.shared.hideOverlayView()
                            self.showErrorMessage(title: "Error Signing up", body: "There was some internal server error, please try again.")
                        }
                    } else {
                        print("Document successfully written!")
                        self.db.collection("user-locations").document((authResult?.user.uid)!).setData([
                            "username": "\(username?.lowercased() ?? "")",
                            "profileImageURL": "",
                            "uid": "\((authResult?.user.uid)!)",
                            "full_name": "\(firstName ?? "") \(lastName ?? "")"
                        ], merge: true) { err in
                            if let err = err {
                                print("Error writing document: \(err)")
                                
                            } else {
                                print("* Successfully updated users location to firestore")
                                self.db.collection("followers").document((authResult?.user.uid)!).setData(["followers":[],"last_post":[]])
                                self.db.collection("following").document((authResult?.user.uid)!).setData(["following_users":[(authResult?.user.uid)!]])
                                DispatchQueue.main.async {
                                    LoadingOverlay.shared.hideOverlayView()
                                }
                                self.presentingViewController?.dismiss(animated: true, completion: nil)
                                
                            }
                        }
                        
                    }
                }
            }
            
        } else {
            showErrorMessage(title: "Error Signing up", body: "Some fields are empty, make sure to put all info required in and try again.")
        }
        
    }
    @IBAction func goBackPressed(_ sender: Any) {
        
        SignUpView.fadeOut()
        emailTextField.fadeOut()
        passwordTextField.fadeOut()
        googleSignInImage.fadeOut()
        appleSignInImage.fadeOut()
        twitterSignInImage.fadeOut()
        googleSignInButton.fadeOut()
        appleSignInButton.fadeOut()
        twitterSignInButton.fadeOut()
        otherSigninOptionsLabel.fadeOut()
        
        DispatchQueue.global(qos: .background).async {
            let second: Double = 1000000
            usleep(useconds_t(0.3 * second))
            print("Active after 0.3 sec, and doesn't block main")
            DispatchQueue.main.async{
                self.StyleLoginComponents()
                self.LoginView.fadeIn()
                self.emailTextField.fadeIn()
                self.passwordTextField.fadeIn()
                self.LoginButton.fadeIn()
                self.googleSignInImage.fadeIn()
                self.appleSignInImage.fadeIn()
                self.twitterSignInImage.fadeIn()
                self.googleSignInButton.fadeIn()
                self.appleSignInButton.fadeIn()
                self.twitterSignInButton.fadeIn()
                self.otherSigninOptionsLabel.fadeIn()
                self.brodiesLogo.fadeIn()
                self.brodiesDudeLogo.fadeIn()
            }
            
        }
    }
    @IBAction func googleSignInPressed(_ sender: Any) {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in


          guard
            let authentication = user?.authentication,
            let idToken = authentication.idToken
          else {
            return
          }

          let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: authentication.accessToken)
            if let error = error {
                showErrorMessage(title: "Error with Login", body: "There was an error while logging into google. Please Try Again.")
              print(error.localizedDescription)
              return
            }
        // When user is signed in
            LoadingOverlay.shared.showOverlay(view: self.view)
            Auth.auth().signIn(with: credential, completion: { (user, error) in
              if let error = error {
                print("Sigin error: \(error.localizedDescription)")
                  DispatchQueue.main.async {
                      LoadingOverlay.shared.hideOverlayView()
                  }
                  self.showErrorMessage(title: "Error with Login", body: "There was an error while logging into google. Please Try Again.")
                return
              }
                print("user is signed in!")
                FirebaseAnalytics.Analytics.logEvent("google_signin", parameters: [AnalyticsParameterScreenName: "login_view"])
                
                self.db.collection("users").document((user?.user.uid)!).setData([
                    "full_name": "\(user?.user.displayName ?? "")",
                    "email": "\(user?.user.email ?? "")",
                    "profileImageURL": "\(user?.user.photoURL?.absoluteString ?? "")",
                    "username": "\((user?.user.email?.split(separator: "@")[0].replacingOccurrences(of: "@", with: "") ?? "").lowercased())"
                ], merge: true) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        DispatchQueue.main.async {
                            LoadingOverlay.shared.hideOverlayView()
                            self.showErrorMessage(title: "Error with login", body: "We are having trouble communicating with our servers. Please try again.")
                        }
                    } else {
                        print("Document successfully written!")
                        self.db.collection("user-locations").document((user?.user.uid)!).setData([
                            "username": "\((user?.user.email?.split(separator: "@")[0].replacingOccurrences(of: "@", with: "") ?? "").lowercased())",
                            "profileImageURL": "\(user?.user.photoURL?.absoluteString ?? "")",
                            "uid": "\((user?.user.uid)!)",
                            "full_name": "\(user?.user.displayName ?? "")"
                        ], merge: true) { err in
                            if let err = err {
                                print("Error writing document: \(err)")
                                
                            } else {
                                print("* Successfully updated users location to firestore")
                                DispatchQueue.main.async {
                                    LoadingOverlay.shared.hideOverlayView()
                                }
                                self.presentingViewController?.dismiss(animated: true, completion: nil)
                                
                            }
                        }
                    }
                }
                

    //            self.dismiss(animated: true, completion: nil)
            })

          // ...
        }
    }
    @objc func googleImageTapped(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
                print("UIImageView tapped")
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }

            // Create Google Sign In configuration object.
            let config = GIDConfiguration(clientID: clientID)
            // Start the sign in flow!
            GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in

              if let error = error {
                // ...
                return
              }

              guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
              else {
                return
              }

              let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: authentication.accessToken)
                if let error = error {
                    showErrorMessage(title: "Error with Login", body: "There was an error while logging into google. Please Try Again.")
                  print(error.localizedDescription)
                  return
                }
            // When user is signed in
                LoadingOverlay.shared.showOverlay(view: self.view)
                Auth.auth().signIn(with: credential, completion: { (user, error) in
                  if let error = error {
                    print("Sigin error: \(error.localizedDescription)")
                      DispatchQueue.main.async {
                          LoadingOverlay.shared.hideOverlayView()
                      }
                      self.showErrorMessage(title: "Error with Login", body: "There was an error while logging into google. Please Try Again.")
                    return
                  }
                    print("user is signed in!")
                    FirebaseAnalytics.Analytics.logEvent("google_signin", parameters: [AnalyticsParameterScreenName: "login_view"])
                    
                    self.db.collection("users").document((user?.user.uid)!).setData([
                        "full_name": "\(user?.user.displayName ?? "")",
                        "email": "\(user?.user.email ?? "")",
                        "profileImageURL": "\(user?.user.photoURL?.absoluteString ?? "")",
                        "username": "\((user?.user.email?.split(separator: "@")[0].replacingOccurrences(of: "@", with: "") ?? "").lowercased())"
                    ], merge: true) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                            DispatchQueue.main.async {
                                LoadingOverlay.shared.hideOverlayView()
                                self.showErrorMessage(title: "Error with login", body: "We are having trouble communicating with our servers. Please try again.")
                            }
                        } else {
                            print("Document successfully written!")
                            self.db.collection("user-locations").document((user?.user.uid)!).setData([
                                "username": "\((user?.user.email?.split(separator: "@")[0].replacingOccurrences(of: "@", with: "") ?? "").lowercased())",
                                "profileImageURL": "\(user?.user.photoURL?.absoluteString ?? "")",
                                "uid": "\((user?.user.uid)!)",
                                "full_name": "\(user?.user.displayName ?? "")"
                            ], merge: true) { err in
                                if let err = err {
                                    print("Error writing document: \(err)")
                                    
                                } else {
                                    print("* Successfully updated users location to firestore")
                                    DispatchQueue.main.async {
                                        LoadingOverlay.shared.hideOverlayView()
                                    }
                                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                                    
                                }
                            }
                        }
                    }
                    

        //            self.dismiss(animated: true, completion: nil)
                })

              // ...
            }
        }
    }
      // Start Google OAuth2 Authentication
      func sign(_ signIn: GIDSignIn?, present viewController: UIViewController?) {
      
        // Showing OAuth2 authentication window
        if let aController = viewController {
          present(aController, animated: true) {() -> Void in }
        }
      }
      // After Google OAuth2 authentication
      func sign(_ signIn: GIDSignIn?, dismiss viewController: UIViewController?) {
        // Close OAuth2 authentication window
        dismiss(animated: true) {() -> Void in }
      }
    @IBAction func loginPressed(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            guard let email = emailTextField.text else { return }
            guard let password = passwordTextField.text else { return }
            Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
                self.dismiss(animated: true)
                if let error = err {
                    print("Failed to sign in with email:", error)
                    self.numberOfFailedAttempts += 1
                    FirebaseAnalytics.Analytics.logEvent("failed_email_login", parameters: [AnalyticsParameterScreenName: "login_view", "failed_attempts": self.numberOfFailedAttempts])
                    self.showErrorMessage(title: "Login Error", body: "There was an error logging in to your account. Try again.")
                    return
                }
                //signed in
                FirebaseAnalytics.Analytics.logEvent("successful_email_login", parameters: [AnalyticsParameterScreenName: "login_view","failed_attempts": self.numberOfFailedAttempts])
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        } else {
            numberOfFailedAttempts += 1
            showErrorMessage(title: "Login Error", body: "Bruh you gotta put an email and password in.")
        }
        
    }
    func showErrorMessage(title: String, body: String) {
        DispatchQueue.main.async {
            
        
        var alertController: AlertViewController = {
            let font = UIFont(name: "CourierNewPSMT", size: 16)
            let alertController = AlertViewController(title: title, body: body, titleFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14), bodyFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14), buttonFont: UIFont(name: "\(Constants.globalFont)-Bold", size: 14))
            let cancelAction = AlertAction(title: "Ok", style: .custom(textColor: self.hexStringToUIColor(hex: Constants.primaryColor))) {
                
            }
            alertController.addAction(cancelAction)
            //                        alertController.addAction(okAction)
            return alertController
        }()
        self.presenter.presentationType = .alert
        self.presenter.transitionType = nil
        self.presenter.dismissTransitionType = nil
        self.presenter.dismissAnimated = true
        let animation = CoverVerticalAnimation(options: .spring(duration: 0.5,
                                                                delay: 0,
                                                                damping: 0.7,
                                                                velocity: 0))
        let coverVerticalWithSpring = TransitionType.custom(animation)
        self.presenter.transitionType = coverVerticalWithSpring
        self.presenter.dismissTransitionType = coverVerticalWithSpring
        self.customPresentViewController(self.presenter, viewController: alertController, animated: true)
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
extension UIImage {
    func addPadding(_ padding: CGFloat) -> UIImage {
        let alignmentInset = UIEdgeInsets(top: -padding, left: -padding,
                                          bottom: -padding, right: -padding)
        return withAlignmentRectInsets(alignmentInset)
    }
}
// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
extension UIView {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIView.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
}
extension UIView {

    func fadeIn( _ alphaz: CGFloat? = 1, onCompletion: (() -> Void)? = nil) {
        var duration: TimeInterval?
        duration = 0.2
        self.alpha = 0
        self.isHidden = false
        UIView.animate(withDuration: duration!,
                       animations: { self.alpha = alphaz! },
                       completion: { (value: Bool) in
                          if let complete = onCompletion { complete() }
                       }
        )
    }

    func fadeOut(_ duration: TimeInterval? = 0.2, onCompletion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration!,
                       animations: { self.alpha = 0 },
                       completion: { (value: Bool) in
                           self.isHidden = true
                           if let complete = onCompletion { complete() }
                       }
        )
    }

}
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
extension UITextField {
    func styleComponents() {
        self.setLeftPaddingPoints(10)
        self.font = UIFont(name: "\(Constants.globalFont)", size: 14)
        self.layer.cornerRadius = 4
        self.backgroundColor = .white
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 4
        self.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
        self.layer.borderWidth = 1
        self.leftViewMode = .always
    }
    func styleSearchBar() {
        self.setLeftPaddingPoints(10)
        self.font = UIFont(name: "\(Constants.globalFont)", size: 14)
//        self.layer.cornerRadius = 25
        self.layer.cornerRadius = 20
        self.backgroundColor = .white
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 4
        self.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
        self.layer.borderWidth = 1
        self.leftViewMode = .always
    }
}
@available(iOS 13.0, *)
extension LoginViewController: ASAuthorizationControllerDelegate {

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      guard let nonce = currentNonce else {
        fatalError("Invalid state: A login callback was received, but no login request was sent.")
      }
      guard let appleIDToken = appleIDCredential.identityToken else {
        print("Unable to fetch identity token")
        return
      }
      guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        return
      }
      // Initialize a Firebase credential.
      let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                idToken: idTokenString,
                                                rawNonce: nonce)
      // Sign in with Firebase.
      Auth.auth().signIn(with: credential) { (authResult, error) in
          if (error != nil) {
          // Error. If error.code == .MissingOrInvalidNonce, make sure
          // you're sending the SHA256-hashed nonce as a hex string with
          // your request to Apple.
              print(error?.localizedDescription)
          return
        }
        // User is signed in to Firebase with Apple.
        // ...
          print("* finished login with apple")
          let fullname = authResult?.user.displayName
          let email = authResult?.user.email
          let uid = authResult?.user.uid
          FirebaseAnalytics.Analytics.logEvent("apple_signin", parameters: [AnalyticsParameterScreenName: "login_view"])
          
          self.db.collection("users").document((uid)!).setData([
              "full_name": "\(fullname as! String)",
              "email": "\(email as! String)",
              "profileImageURL": "\(authResult?.user.photoURL?.absoluteString ?? "")",
              "username": "\((email?.split(separator: "@")[0].replacingOccurrences(of: "@", with: "") ?? "").lowercased())",
              "uid": uid as! String
          ], merge: true) { err in
              if let err = err {
                  print("Error writing document: \(err)")
                  DispatchQueue.main.async {
                      LoadingOverlay.shared.hideOverlayView()
                      self.showErrorMessage(title: "Error with login", body: "We are having trouble communicating with our servers. Please try again.")
                  }
              } else {
                  print("Document successfully written!")
                  self.db.collection("user-locations").document((uid)!).setData([
                    "username": "\((email?.split(separator: "@")[0].replacingOccurrences(of: "@", with: "") ?? "").lowercased())",
                    "profileImageURL": "\(authResult?.user.photoURL?.absoluteString ?? "")",
                      "uid": "\(uid as! String)",
                      "full_name": "\(fullname as! String)"
                  ], merge: true) { err in
                      if let err = err {
                          print("Error writing document: \(err)")
                          
                      } else {
                          print("* Successfully updated users location to firestore")
                          DispatchQueue.main.async {
                              LoadingOverlay.shared.hideOverlayView()
                          }
                          self.presentingViewController?.dismiss(animated: true, completion: nil)
                          
                      }
                  }
              }
          }
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    print("Sign in with Apple errored: \(error)")
  }

}
