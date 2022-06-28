//
//  AddViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 5/19/22.
//

import UIKit
import Foundation
import SwiftKeychainWrapper
import FirebaseCore
import FirebaseAuth

class AddViewController: UIViewController {
    let defaults = UserDefaults.standard
    @IBOutlet weak var StaticMapImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = hexStringToUIColor(hex: "#f5f5f5")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        if Auth.auth().currentUser?.uid == nil {
//            // show login view
//            DispatchQueue.main.async {
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
//                vc.modalPresentationStyle = .fullScreen
//                self.present(vc, animated: true)
//            }
//        }
        
            //            // show login view
            print("pushing camera view")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController")
            vc.modalPresentationStyle = .fullScreen
            self.parent!.present(vc, animated: true)
       
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

