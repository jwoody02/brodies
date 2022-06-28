//
//  MapsViewController.swift
//  Egg.
//
//  Created by Jordan Wood on 5/15/22.
//

import UIKit
import Foundation
import SwiftKeychainWrapper
import FirebaseCore
import FirebaseAuth
import CoreLocation
import MapKit
import MapKitGoogleStyler
import FirebaseFirestore
import GoogleMobileAds
import FirebaseAnalytics

class MapPin: NSObject, MKAnnotation {
   let title: String?
    let uid: String
   let locationName: String
   let coordinate: CLLocationCoordinate2D
    let imageUrl: String
    let username: String
    let type: String
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D, imageUrl: String, uid: String, username: String, type: String) {
      self.title = title
      self.locationName = locationName
      self.coordinate = coordinate
        self.imageUrl = imageUrl
        self.uid = uid
        self.username = username
        self.type = type
   }
    
}

class MapsViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    
    let defaults = UserDefaults.standard
    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 2500
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var magnifyingGlassImage: UIImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var BottomgradientView: UIView!
    @IBOutlet weak var peepAndEventNearYouLabel: UILabel!
    @IBOutlet weak var currentLocationLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    // For mobile ads
    var adNativeUnit = "ca-app-pub-3940256099942544/3986624511" //ca-app-pub-2174656505812203/9454834911 (actual native)
    
    // Admob variables
    var adiPath = 6 // Nth item for ads
    var adReq = 0
    var adToShow = 0 // Nuber of ads to show
    var adRetCnt = 0 // Number of items returned
    
    /// The native ads.
    var nativeAds = [GADNativeAd]()
    
    /// The ad loader that loads the native ads.
    var adLoader: GADAdLoader!
    
    let isMinimalEnabled = true
    
    private var db = Firestore.firestore()
    var searchTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = hexStringToUIColor(hex: "#f5f5f5")
        searchBar.styleComponents()
        searchBar.frame = CGRect(x: 20, y: 70, width: UIScreen.main.bounds.width - 40, height: 50)
        gradientView.frame = CGRect(x: 0, y: searchBar.frame.maxY+60, width: UIScreen.main.bounds.width, height: 250)
        gradientView.isUserInteractionEnabled = false
        BottomgradientView.isUserInteractionEnabled = false
        peepAndEventNearYouLabel.frame = CGRect(x: 0, y: searchBar.frame.maxY+20, width: UIScreen.main.bounds.width, height: 20)
        currentLocationLabel.frame = CGRect(x: 0, y: peepAndEventNearYouLabel.frame.maxY + 5, width: UIScreen.main.bounds.width, height: 20)
        
        peepAndEventNearYouLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 16)
        currentLocationLabel.font = UIFont(name: "\(Constants.globalFont)", size: 14)
        if isMinimalEnabled {
            peepAndEventNearYouLabel.isHidden = true
            gradientView.frame = CGRect(x: 0, y: searchBar.frame.maxY+40, width: UIScreen.main.bounds.width, height: 150)
            currentLocationLabel.frame = CGRect(x: 0, y: searchBar.frame.maxY+20, width: UIScreen.main.bounds.width, height: 20)
            currentLocationLabel.isHidden = true
            segmentedControl.frame = CGRect(x: 20, y: searchBar.frame.maxY+10, width: UIScreen.main.bounds.width - 40, height: 35)
            BottomgradientView.isHidden = true
//            segmentedControl.backgroundColor = .white
//            segmentedControl.selectedSegmentTintColor = hexStringToUIColor(hex: Constants.primaryColor)
        }
        BottomgradientView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 200, width: UIScreen.main.bounds.width, height: 200)
        magnifyingGlassImage.frame = CGRect(x: searchBar.frame.minX + 15, y: searchBar.frame.minY + 15, width: 20, height: 20)
        searchBar.font = UIFont(name: "\(Constants.globalFont)", size: 15)
        searchBar.textColor = .darkGray
        hideKeyboardWhenTappedAround()
        searchBar.delegate = self
        // handle the editingChanged event by calling (textFieldDidEditingChanged(-:))
        self.searchBar.addTarget(self, action: #selector(textFieldDidEditingChanged(_:)), for: .editingChanged)
        
        //        configureTileOverlay()
        mapView.frame = CGRect(x: 0, y: searchBar.frame.maxY + 50, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - (searchBar.frame.maxY + 10))
        mapView.delegate = self
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }
        if currentLocationAccess() == .authorizedWhenInUse || currentLocationAccess() == .authorizedAlways {
            styleMap()
        } else {
            print("* damn we aint got access bre")
            // Disable location features
            let alert = UIAlertController(title: "Allow Location Access", message: "To find people and events near you, we need access to your location. Turn on Location Services in your device settings.", preferredStyle: UIAlertController.Style.alert)
            
            // Button to Open Settings
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: { action in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)")
                    })
                }
            }))
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        mapView.delegate = self
    }
    func addPinUsing(location: CLLocationCoordinate2D, name: String, username: String, uid: String, imageUrl: String, type: String) {
        if type == "user" {
            let pin = MapPin(title: String(name.split(separator: " ")[0]).replacingOccurrences(of: " ", with: ""), locationName: "", coordinate: location, imageUrl: imageUrl, uid: uid, username: username, type: type)
            mapView.addAnnotations([pin])
        } else if type == "group" {
            let pin = MapPin(title: name, locationName: "", coordinate: location, imageUrl: imageUrl, uid: uid, username: username, type: type)
            mapView.addAnnotations([pin])
        } else if type == "event" {
            let pin = MapPin(title: name, locationName: "", coordinate: location, imageUrl: imageUrl, uid: uid, username: username, type: type)
            mapView.addAnnotations([pin])
        }
        
    }
    let interactor = Interactor()

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? CameraViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
    }
    func styleMap() {
        let darkLayer = CALayer()
        darkLayer.frame = self.view.bounds
        darkLayer.compositingFilter = "colorBlendMode"
        darkLayer.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
        
        let newLightFilter = CIFilter(name: "CIColorMonochrome")
//        self.mapView.layer.addSublayer(darkLayer)
        //        mapView.mapType = .mu
        mapView.alpha = 1
        mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: []))
        centerMapOnLocation(location: locationManager.location!)
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
    func centerMapOnLocation(location: CLLocation)
    {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if error == nil {
                if let firstLocation = placemarks?[0], let cityName = firstLocation.locality, let stateName = firstLocation.administrativeArea, let countryName = firstLocation.country { // get the city name
                    self?.locationManager.stopUpdatingLocation()
                    print("* got user city: \(cityName)")
                    self?.defaults.set(cityName, forKey: "city")
                    self?.defaults.set(stateName, forKey: "state")
                    self?.defaults.set(countryName, forKey: "country")
                    self?.getUsersAndEventsInHomeTown()
                    DispatchQueue.main.async {
                        self?.currentLocationLabel.text = "\(cityName), \(stateName)"
                        
                        if self?.defaults.object(forKey: "last-update-location") != nil {
                            let datee = self?.defaults.date(forKey: "last-update-location")
                            let diffInDays = Calendar.current.dateComponents([.day], from: datee ?? Date(), to: Date()).day
                            if diffInDays! >= 6 {
                                print("* difference in days is >= 6, updating")
                                FirebaseAnalytics.Analytics.logEvent("updated_location", parameters: [AnalyticsParameterScreenName: "map_view"])
                                self?.updateFirestoreLocation(city: cityName, state: stateName, country: countryName)
                                self?.defaults.set(date: Date(), forKey: "last-update-location")
                            } else {
                                print("* it has been \(diffInDays) days since location updated, wait")
                            }
                        } else {
                            self?.defaults.set(date: Date(), forKey: "last-update-location")
                            print("* last-update-location not set, set \(Date()) as new value")
                            FirebaseAnalytics.Analytics.logEvent("init_location", parameters: [AnalyticsParameterScreenName: "map_view"])
                            self?.updateFirestoreLocation(city: cityName, state: stateName, country: countryName)
                        }
                    }
                    
                }
            }
        }
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    func getUsersAndEventsInHomeTown() {
        let city = defaults.string(forKey: "city")!
        let state = defaults.string(forKey: "state")!
        let country = defaults.string(forKey: "country")!
        let user = Auth.auth().currentUser?.uid
        
        let locationsRef = db.collection("user-locations")
        print("* finding users without id \(user! as! String)")
        locationsRef.whereField("city", isEqualTo: city).whereField("state", isEqualTo: state).whereField("country", isEqualTo: country).whereField("uid", isNotEqualTo: user! ?? "").limit(to: 10).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                if querySnapshot!.isEmpty {
                    print("* no users near by")
                } else {
                    for document in querySnapshot!.documents {
//                        print("* got user near by: \(document.documentID) => \(document.data())")
                        let randomLocation = self.locationManager.location!.movedBy(latitudinalMeters: (self.randomFloatBetween(-( Double(self.regionRadius) - 500), andBig: Double(self.regionRadius) - 500)), longitudinalMeters: self.randomFloatBetween(-( Double(self.regionRadius) - 500), andBig: Double(self.regionRadius) - 500)).coordinate
                        let profileImage = document.data()["profileImageURL"] as? String ?? "https://qph.cf2.quoracdn.net/main-qimg-2b21b9dd05c757fe30231fac65b504dd"
                        let fullName = document.data()["full_name"] as? String ?? ""
                        print("* got user near by: \(document.documentID) => \(fullName)")
                        self.addPinUsing(location: randomLocation, name: fullName, username: "\(document.data()["username"] as? String ?? "")", uid: "\(document.data()["uid"] as? String ?? "")", imageUrl: profileImage, type: "user")
                        
                    }
                    self.locationManager.stopUpdatingLocation()
                }
                
            }
        }
        let groupsRef = db.collection("groups")
        
        groupsRef.whereField("city", isEqualTo: city).whereField("state", isEqualTo: state).whereField("country", isEqualTo: country).order(by: "members_count", descending: true).limit(to: 3).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                if querySnapshot!.isEmpty {
                    print("* no groups near by")
                } else {
                    for document in querySnapshot!.documents {
                        
                        let randomLocation = self.locationManager.location!.movedBy(latitudinalMeters: (self.randomFloatBetween(-( Double(self.regionRadius)), andBig: Double(self.regionRadius))), longitudinalMeters: self.randomFloatBetween(-( Double(self.regionRadius)), andBig: Double(self.regionRadius))).coordinate
                        let profileImage = document.data()["profileImageURL"] as? String ?? "https://qph.cf2.quoracdn.net/main-qimg-2b21b9dd05c757fe30231fac65b504dd"
                        let fullName = document.data()["name"] as? String ?? ""
                        print("* got group near by: \(document.documentID) => \(fullName)")
                        self.addPinUsing(location: randomLocation, name: fullName, username: "\(document.data()["username"] as? String ?? "")", uid: "\(document.data()["uid"] as? String ?? "")", imageUrl: profileImage, type: "group")
                        
                    }
                    self.locationManager.stopUpdatingLocation()
                }
                
            }
        }
        
        let eventsRef = db.collection("events")
        
        eventsRef.whereField("city", isEqualTo: city).whereField("state", isEqualTo: state).whereField("country", isEqualTo: country).order(by: "num_people_going", descending: true).limit(to: 3).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                if querySnapshot!.isEmpty {
                    print("* no groups near by")
                } else {
                    for document in querySnapshot!.documents {
//                        print("* got group near by: \(document.documentID) => \(document.data())")
                        let randomLocation = self.locationManager.location!.movedBy(latitudinalMeters: (self.randomFloatBetween(-( Double(self.regionRadius)), andBig: Double(self.regionRadius))), longitudinalMeters: self.randomFloatBetween(-( Double(self.regionRadius)), andBig: Double(self.regionRadius))).coordinate
                        let profileImage = document.data()["profileImageURL"] as? String ?? "https://qph.cf2.quoracdn.net/main-qimg-2b21b9dd05c757fe30231fac65b504dd"
                        let fullName = document.data()["name"] as? String ?? ""
                        print("* got event near by: \(document.documentID) => \(fullName)")
                        self.addPinUsing(location: randomLocation, name: fullName, username: "\(document.data()["username"] as? String ?? "")", uid: "\(document.data()["uid"] as? String ?? "")", imageUrl: profileImage, type: "event")
                        
                    }
                    self.locationManager.stopUpdatingLocation()
                }
                
            }
        }
    }
    private func randomFloatBetween(_ smallNumber: Double, andBig bigNumber: Double) -> Double {
        let diff: Double = bigNumber - smallNumber
        return ((Double(arc4random() % (UInt32(RAND_MAX) + 1)) / Double(RAND_MAX)) * diff) + smallNumber
    }
    func updateFirestoreLocation(city: String, state: String, country: String) {
        var user = Auth.auth().currentUser?.uid
        
        if ((user) != nil) {
          // User is signed in.
            self.db.collection("user-locations").document(user!).setData([
                "city": "\(city)",
                "state": "\(state)",
                "country": "\(country)",
                "uid": "\(user!)"
            ], merge: true) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                    
                } else {
                    print("* Successfully updated users location to firestore")
                    
                }
            }
        }

        
    }
    func searchWith(term: String) {
        let usersRef = db.collection("users")
        
        let userID = Auth.auth().currentUser?.uid
        let end = "\(term.dropLast())\(nextChar(str: "\(term.last!)"))"
        //            .whereField("username", isLessThan: "\(term.dropLast())\(nextChar(str: "\(term.last!)"))")
        usersRef.whereField("username", isGreaterThanOrEqualTo: term.lowercased()).whereField("username", isLessThan: end).limit(to: 3).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                if querySnapshot!.isEmpty {
                    print("* detected empty feed")
                } else {
                    for document in querySnapshot!.documents {
                        print("* got user search results: \(document.documentID) => \(document.data())")
                    }
                }
                
            }
        }
    }
    // reset the searchTimer whenever the textField is editingChanged
    @objc func textFieldDidEditingChanged(_ textField: UITextField) {
        
        // if a timer is already active, prevent it from firing
        if searchTimer != nil {
            searchTimer?.invalidate()
            searchTimer = nil
        }
        
        // reschedule the search: in 1.0 second, call the searchForKeyword method on the new textfield content
        searchTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(searchForKeyword(_:)), userInfo: textField.text!, repeats: false)
    }
    
    @objc func searchForKeyword(_ timer: Timer) {
        
        // retrieve the keyword from user info
        let keyword = timer.userInfo!
        
        print("Searching for keyword \(keyword)")
        if keyword as! String != "" {
            searchWith(term: keyword as! String)
        }
        
    }
    func currentLocationAccess() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    func checkUsersLocationServicesAuthorization() {
        /// Check if user has authorized Total Plus to use Location Services
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                // Request when-in-use authorization initially
                // This is the first and the ONLY time you will be able to ask the user for permission
                print("* unknown location authorization")
                self.locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
                break
                
            case .restricted, .denied:
                // Disable location features
                let alert = UIAlertController(title: "Allow Location Access", message: "To find people and events near you, we need access to your location. Turn on Location Services in your device settings.", preferredStyle: UIAlertController.Style.alert)
                
                // Button to Open Settings
                alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: { action in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)")
                        })
                    }
                }))
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                break
                
            case .authorizedWhenInUse, .authorizedAlways:
                // Enable features that require location services here.
                print("Full Access to location")
                break
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser?.uid == nil {
            //            // show login view
            print("not valid user, pushing login")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            vc.modalPresentationStyle = .fullScreen
            self.parent!.present(vc, animated: true)
        } else {
            checkUsersLocationServicesAuthorization()
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
extension CLLocation {
    func movedBy(latitudinalMeters: CLLocationDistance, longitudinalMeters: CLLocationDistance) -> CLLocation {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: abs(latitudinalMeters), longitudinalMeters: abs(longitudinalMeters))

        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta

        let latitudialSign = CLLocationDistance(latitudinalMeters.sign == .minus ? -1 : 1)
        let longitudialSign = CLLocationDistance(longitudinalMeters.sign == .minus ? -1 : 1)

        let newLatitude = coordinate.latitude + latitudialSign * latitudeDelta
        let newLongitude = coordinate.longitude + longitudialSign * longitudeDelta

        let newCoordinate = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)

        let newLocation = CLLocation(coordinate: newCoordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: Date())

        return newLocation
    }
}

extension MapsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // This is the final step. This code can be copied and pasted into your project
        // without thinking on it so much. It simply instantiates a MKTileOverlayRenderer
        // for displaying the tile overlay.
        if let tileOverlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let uid = (view.annotation as! MapPin).uid
        print("* pin with uid \(uid) tapped")
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }

        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"

        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        let tmp = annotation as! MapPin
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
//            annotationView.image = UIImage(named: "imm2.jpeg")
            let url = URL(string: tmp.imageUrl)
            annotationView.alpha = 0
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    annotationView.frame.size = CGSize(width: 45, height: 70)
                    
                    let profileImageView = UIImageView(frame: CGRect(x: 0, y: 3, width: annotationView.frame.width - 3, height: annotationView.frame.width - 3))
                    profileImageView.image = UIImage(data: data!)
                    profileImageView.frame.size = CGSize(width: 45, height: 45)
                    profileImageView.contentMode = .scaleAspectFill
                    profileImageView.layer.cornerRadius = Constants.borderRadius
                    profileImageView.clipsToBounds = true
                    if tmp.type == "user" {
                        profileImageView.layer.borderColor = self.hexStringToUIColor(hex:"\(Constants.primaryColor)").cgColor
                        profileImageView.layer.borderWidth = 3
                        annotationView.insertSubview(profileImageView, at: 0)
    //                    annotationView.layer.masksToBounds = true
                        
                        /*Make name label*/
                        let nameLabel = UILabel(frame: CGRect(x: -15, y: profileImageView.frame.height + 7, width: 80, height: 16))
                        nameLabel.backgroundColor = self.hexStringToUIColor(hex: Constants.secondaryColor)
                        nameLabel.text = tmp.title
                        nameLabel.sizeToFit()
                        nameLabel.center.x = annotationView.frame.width / 2
                        nameLabel.textColor = self.hexStringToUIColor(hex: Constants.primaryColor)
                        nameLabel.textAlignment = .center
                        nameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 10)
                        nameLabel.layer.cornerRadius = 4
                        nameLabel.clipsToBounds = true

                            /*Set circle's tag to 1*/
                        nameLabel.accessibilityLabel = tmp.uid
                            /*Add the circle beneath the annotation*/
                        annotationView.insertSubview(nameLabel, at: 0)
                        annotationView.fadeIn()
                    } else if tmp.type == "group" {
                        profileImageView.layer.borderColor = self.hexStringToUIColor(hex:"\(Constants.groupPrimaryColor)").cgColor
                        profileImageView.layer.borderWidth = 3
                        annotationView.insertSubview(profileImageView, at: 0)
    //                    annotationView.layer.masksToBounds = true
                        
                        /*Make name label*/
                        let nameLabel = UILabel(frame: CGRect(x: -15, y: profileImageView.frame.height + 7, width: 80, height: 16))
                        nameLabel.backgroundColor = self.hexStringToUIColor(hex: Constants.groupSecondaryColor)
                        nameLabel.text = tmp.title
                        nameLabel.sizeToFit()
                        nameLabel.center.x = annotationView.frame.width / 2
                        nameLabel.textColor = self.hexStringToUIColor(hex: Constants.groupPrimaryColor)
                        nameLabel.textAlignment = .center
                        nameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 10)
                        nameLabel.layer.cornerRadius = 4
                        nameLabel.clipsToBounds = true

                            /*Set circle's tag to 1*/
                        nameLabel.accessibilityLabel = tmp.uid
                            /*Add the circle beneath the annotation*/
                        annotationView.insertSubview(nameLabel, at: 0)
                        annotationView.fadeIn()
                    } else if tmp.type == "event" {
                        profileImageView.layer.borderColor = self.hexStringToUIColor(hex:"\(Constants.eventPrimaryColor)").cgColor
                        profileImageView.layer.borderWidth = 3
                        annotationView.insertSubview(profileImageView, at: 0)
    //                    annotationView.layer.masksToBounds = true
                        
                        /*Make name label*/
                        let nameLabel = UILabel(frame: CGRect(x: -15, y: profileImageView.frame.height + 7, width: 80, height: 16))
                        nameLabel.backgroundColor = self.hexStringToUIColor(hex: Constants.eventSecondaryColor)
                        nameLabel.text = tmp.title
                        nameLabel.sizeToFit()
                        nameLabel.center.x = annotationView.frame.width / 2
                        nameLabel.textColor = self.hexStringToUIColor(hex: Constants.eventPrimaryColor)
                        nameLabel.textAlignment = .center
                        nameLabel.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 10)
                        nameLabel.layer.cornerRadius = 4
                        nameLabel.clipsToBounds = true

                            /*Set circle's tag to 1*/
                        nameLabel.accessibilityLabel = tmp.uid
                            /*Add the circle beneath the annotation*/
                        annotationView.insertSubview(nameLabel, at: 0)
                        annotationView.fadeIn()
                    }
                    
                }
            }
//            annotationView.frame.size = CGSize(width: 30, height: 30)
        }

        return annotationView
    }
}
@IBDesignable
public class Gradient: UIView {
    @IBInspectable var startColor:   UIColor = .black { didSet { updateColors() }}
    @IBInspectable var endColor:     UIColor = .white { didSet { updateColors() }}
    @IBInspectable var startLocation: Double =   0.05 { didSet { updateLocations() }}
    @IBInspectable var endLocation:   Double =   0.95 { didSet { updateLocations() }}
    @IBInspectable var horizontalMode:  Bool =  false { didSet { updatePoints() }}
    @IBInspectable var diagonalMode:    Bool =  false { didSet { updatePoints() }}
    
    override public class var layerClass: AnyClass { CAGradientLayer.self }
    
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
    
    func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? .init(x: 1, y: 0) : .init(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 0, y: 1) : .init(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? .init(x: 0, y: 0) : .init(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 1, y: 1) : .init(x: 0.5, y: 1)
        }
    }
    func updateLocations() {
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }
    func updateColors() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePoints()
        updateLocations()
        updateColors()
    }
    
}
extension UserDefaults {
    func set(date: Date?, forKey key: String){
        self.set(date, forKey: key)
    }
    
    func date(forKey key: String) -> Date? {
        return self.value(forKey: key) as? Date
    }
}

extension MapsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
