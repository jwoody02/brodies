//
//  Utils.swift
//  Egg.
//
//  Created by Jordan Wood on 5/16/22.
//

import Foundation
import UIKit
import SystemConfiguration
extension UIDevice {
    func vpnConnect1() -> Bool {
        let cfDict = CFNetworkCopySystemProxySettings()
        let nsDict = cfDict!.takeRetainedValue() as NSDictionary
        let keys = nsDict["__SCOPED__"] as! NSDictionary

        for key: String in keys.allKeys as! [String] {
            if (key == "tap" || key == "tun" || key == "ppp" || key == "ipsec" || key == "ipsec0") {
                return true
            }
        }
        return false
    }
    func vpnConnect2() -> Bool {
        let host = "www.google.com"
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            return false
        }
        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(reachability, &flags) == false {
            return false
        }
        let isOnline = flags.contains(.reachable) && !flags.contains(.connectionRequired)
        if !isOnline {
            return false
        }
        let isMobileNetwork = flags.contains(.isWWAN)
        let isTransientConnection = flags.contains(.transientConnection)
        if isMobileNetwork {
            if let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? Dictionary<String, Any>,
                let scopes = settings["__SCOPED__"] as? [String:Any] {
                for (key, _) in scopes {
                    if key.contains("tap") || key.contains("tun") || key.contains("ppp") {
                        return true
                    }
                }
            }
            return false
        } else {
            return isTransientConnection
        }
    }
    func checkForVPNConnection() -> Bool {
        return vpnConnect1() && vpnConnect2()
    }
}
