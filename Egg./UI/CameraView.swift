



import UIKit
import AVFoundation
import Photos
 import NextLevel
import iOSPhotoEditor
import MapKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Loady
import FirebaseAnalytics
import MobileCoreServices
import SwiftyGif

class CameraViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    

    static let nextLevelAlbumTitle = "NextLevel"

    // MARK: - UIViewController
    override public var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - properties
    internal var previewView: UIView?
    internal var gestureView: UIView?
    internal var focusView: FocusIndicatorView?
    internal var controlDockView: UIView?
    internal var metadataObjectViews: [UIView]?

    internal var recordButton: UIImageView?
    internal var cameraPhotoResult: UIImageView?
    internal var devicePosition: NextLevelDevicePosition?
    
    internal var snapPicButton: UIButton?
    internal var flipButton: UIButton?
    internal var flashButton: UIButton?
    internal var saveButton: UIButton?
    internal var photoGallery: UIButton?
    internal var closeButton: UIButton?
    internal var actualPostButton: LoadyButton?
    
    internal var locationSearchResults: UITableView?
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    internal var distanceAway: UILabel?
    
    internal var AddLocationView: UIView?
    internal var addLocationIcon: UIImageView?
    internal var AddLocationTextField: UITextField?
    
    internal var AddPeopleView: UIView?
    internal var addPeopleIcon: UIImageView?
    internal var AddPeopleTextField: UITextField?
    internal var rightArrowPeople: UIImageView?
    
    internal var AddTagsView: UIView?
    internal var addTagsIcon: UIImageView?
    internal var AddTagsTextField: UITextField?
    
    internal var glimpsView: UIView?
    internal var gimpsText: UILabel? // *new*
    internal var glimpsLogo: UIImageView? // either system image: "timelapse" or "flame" or "flame.fill"
    
    var prevPostType = "story"
    
    var interactor:Interactor? = nil
    
    var postType = "story"
    private var db = Firestore.firestore()
    
    internal var OriginalPostImageForFiltering: UIImage?
    
    internal var filterImageCollectionView: UICollectionView!
    private var isFilterEnable:Bool = false
    var index = 0
    
    var CIFilterNames = [
        "Default",
        "CISRGBToneCurveToLinear",
        "CIColorMonochrome",
        "CIColorPosterize",
        "CIFalseColor",
        "CIMaskToAlpha",
        "CIMaximumComponent",
        "CIMinimumComponent",
        "CIPhotoEffectChrome",
        "CIPhotoEffectFade",
        "CIPhotoEffectInstant",
        "CIPhotoEffectMono",
        "CIPhotoEffectNoir",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTonal",
        "CIPhotoEffectTransfer",
        "CISepiaTone",
        "CIVignette",
        "CICMYKHalftone",
        "CIDotScreen",
        "CIHatchedScreen",
        "CILineScreen",
        "CIComicEffect",
        "CICrystallize",
        "CIHexagonalPixellate"
    ]
    
    var postPhotos: [UIImage] = []
    
    internal var stepNameLabel: UILabel?
    internal var nextButton: UIButton?
    internal var captionView: UITextView?
    internal var goBackButton: UIButton?
    internal var numOfImageLabel: UILabel?
    
    internal var longPressGestureRecognizer: UILongPressGestureRecognizer?
    internal var photoTapGestureRecognizer: UITapGestureRecognizer?
    internal var focusTapGestureRecognizer: UITapGestureRecognizer?
    internal var flipDoubleTapGestureRecognizer: UITapGestureRecognizer?
    
    var currentFlashMode: NextLevelFlashMode?
    
    internal var menubarUIView: UIView?
    internal var littleBottomBar: UIView?

    private var _panStartPoint: CGPoint = .zero
    private var _panStartZoom: CGFloat = 0.0
    
    var zoomScaleRange: ClosedRange<CGFloat> = 1...10
    private var initialScale: CGFloat = 0
    
    let locationManager = CLLocationManager()
    let imagePicker = UIImagePickerController()
    
    var uploadedFromCameraRoll = false

    // MARK: - object lifecycle
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    deinit {
    }

    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isUserInteractionEnabled = true
        let loader = ColorCubeLoader(bundle: .main)
        let filters: [FilterColorCube]? = try? loader.load()

    ColorCubeStorage.default.filters = filters ?? []
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.sourceType = .photoLibrary
        searchCompleter.delegate = self
        self.view.backgroundColor = UIColor.black
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        locationManager.delegate = self
//            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager.requestWhenInUseAuthorization()
//            locationManager.requestLocation()
        let screenBounds = UIScreen.main.bounds
        currentFlashMode = .auto
        NextLevel.shared._currentDevice = AVCaptureDevice.default(for: .video)
        NextLevel.shared.flashMode = .auto
        print("* is NL flash available: \(NextLevel.shared.isFlashAvailable)")
        // preview (default is story
        if UIDevice.current.hasNotch {
            self.previewView = UIView(frame: CGRect(x: 0, y: 40, width: screenBounds.width, height: screenBounds.width*1.77777777))
        } else {
            self.previewView = UIView(frame: CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.width*1.5))
        }
        if let previewView = self.previewView {
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            previewView.layer.cornerRadius = Constants.borderRadius
            previewView.clipsToBounds = true
            previewView.backgroundColor = UIColor.black
            NextLevel.shared.previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(NextLevel.shared.previewLayer)
            NextLevel.shared.flashMode = .auto
            self.view.addSubview(previewView)
        }
        
        self.focusView = FocusIndicatorView(frame: .zero)

        // buttons
        self.recordButton = UIImageView(image: UIImage(named: "record_button"))
        self.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDragDown(_:))))
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureRecognizer(_:)))
        if let recordButton = self.recordButton,
            let longPressGestureRecognizer = self.longPressGestureRecognizer {
            recordButton.isUserInteractionEnabled = true
            recordButton.sizeToFit()
            recordButton.layer.cornerRadius = recordButton.frame.width / 2
            recordButton.layer.borderColor = hexStringToUIColor(hex: Constants.primaryColor).cgColor
            recordButton.layer.borderWidth = 2
            recordButton.isUserInteractionEnabled = true
            longPressGestureRecognizer.delegate = self
            longPressGestureRecognizer.minimumPressDuration = 0.05
            longPressGestureRecognizer.allowableMovement = 10.0
            recordButton.addGestureRecognizer(longPressGestureRecognizer)
        }
        self.actualPostButton = LoadyButton(frame: .zero)
        if let actualPostButton = actualPostButton {
//            actualPostButton.backgroundColor = hexStringToUIColor (hex:Constants.primaryColor)
            actualPostButton.layer.cornerRadius = 4
            actualPostButton.layer.shadowColor = hexStringToUIColor (hex:Constants.primaryColor).withAlphaComponent(0.3).cgColor
            actualPostButton.layer.shadowOffset = CGSize(width: 4, height: 10)
            actualPostButton.layer.shadowOpacity = 0.5
            actualPostButton.layer.shadowRadius = 4
            actualPostButton.titleLabel!.font = UIFont(name: Constants.globalFontBold, size: 13)
            actualPostButton.setTitle("Post", for: .normal)
            actualPostButton.alpha = 0
            actualPostButton.titleLabel?.textColor = .white
            actualPostButton.backgroundColor = hexStringToUIColor(hex:Constants.primaryColor)
            actualPostButton.addTarget(self, action: #selector(handlePostButton(_:)), for: .touchUpInside)
            actualPostButton.isUserInteractionEnabled = true
            self.view.addSubview(actualPostButton)
        }
        self.nextButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let nextButton = nextButton {
            nextButton.backgroundColor = .darkGray
            nextButton.layer.cornerRadius = 4
            nextButton.layer.shadowColor = UIColor.darkGray.withAlphaComponent(0.3).cgColor
            nextButton.layer.shadowOffset = CGSize(width: 4, height: 10)
            nextButton.layer.shadowOpacity = 0.5
            nextButton.layer.shadowRadius = 4
            nextButton.titleLabel!.font = UIFont(name: Constants.globalFontBold, size: 13)
            nextButton.setTitle("Next", for: .normal)
            nextButton.addTarget(self, action: #selector(handleNextButton(_:)), for: .touchUpInside)
            nextButton.setTitleColor(.white, for: .normal)
            nextButton.isUserInteractionEnabled = true
        }
        self.stepNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let stepNameLabel = stepNameLabel {
            stepNameLabel.textAlignment = .center
            stepNameLabel.textColor = .white
            stepNameLabel.text = "Choose Filter"
            let stepNameWidth = 100
            stepNameLabel.frame = CGRect(x: CGFloat((Int(Float16(UIScreen.main.bounds.width)) / 2) - stepNameWidth/2), y: (previewView?.frame.minY)! + 20, width: CGFloat(stepNameWidth), height: 40)
            stepNameLabel.font = UIFont(name: Constants.globalFont, size: 15)
        }
        self.flipButton = UIButton(type: .custom)
        if let flipButton = self.flipButton {
            flipButton.setImage(UIImage(named: "flip_button"), for: .normal)
            flipButton.sizeToFit()
            flipButton.isUserInteractionEnabled = true
            flipButton.addTarget(self, action: #selector(handleFlipButton(_:)), for: .touchUpInside)
        }

        self.saveButton = UIButton(type: .custom)
        if let saveButton = self.saveButton {
            saveButton.setImage(UIImage(named: "save_button"), for: .normal)
            saveButton.sizeToFit()
            saveButton.addTarget(self, action: #selector(handleSaveButton(_:)), for: .touchUpInside)
        }

        // capture control "dock"
        let controlDockHeight = screenBounds.height * 0.15
//        self.controlDockView = UIView(frame: CGRect(x: 0, y: screenBounds.height - controlDockHeight, width: screenBounds.width, height: controlDockHeight))
        self.controlDockView = UIView(frame: CGRect(x: 0, y: (previewView?.frame.maxY)! - controlDockHeight, width: screenBounds.width, height: 0))
        if let controlDockView = self.controlDockView {
            controlDockView.backgroundColor = UIColor.clear
            controlDockView.autoresizingMask = [.flexibleTopMargin]
            self.view.addSubview(controlDockView)

            if let recordButton = self.recordButton {
                recordButton.center = CGPoint(x: controlDockView.bounds.midX, y: controlDockView.bounds.midY)
//                controlDockView.addSubview(recordButton)
            }

            

//            if let saveButton = self.saveButton, let recordButton = self.recordButton {
//                saveButton.center = CGPoint(x: controlDockView.bounds.width * 0.25 - saveButton.bounds.width * 0.5, y: recordButton.center.y)
//                controlDockView.addSubview(saveButton)
//            }
        }
        self.captionView = UITextView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let captionView = self.captionView {
            
            captionView.textColor = .white
            captionView.delegate = self
            captionView.backgroundColor = .darkGray.withAlphaComponent(0.5)
            captionView.alpha = 0
            self.view.addSubview(captionView)
        }
        AddLocationView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let AddLocationView = AddLocationView {
            addLocationIcon = UIImageView(image: UIImage(systemName: "location")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .light, scale: .small)))
            if let addLocationIcon = addLocationIcon {
                addLocationIcon.backgroundColor = .clear
                addLocationIcon.tintColor = .lightGray.withAlphaComponent(0.7)
                addLocationIcon.contentMode = .scaleAspectFit
                addLocationIcon.layer.cornerRadius = 4
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backAddressTapped(tapGestureRecognizer:)))
                addLocationIcon.isUserInteractionEnabled = true
                addLocationIcon.addGestureRecognizer(tapGestureRecognizer)
                AddLocationView.addSubview(addLocationIcon)
            }
            AddLocationTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let AddLocationTextField = AddLocationTextField {
                AddLocationTextField.backgroundColor = .clear
                AddLocationTextField.font = UIFont(name: Constants.globalFont, size: 13)
                AddLocationTextField.attributedPlaceholder = NSAttributedString(string: "Enter a location",
                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
                AddLocationTextField.textColor = .white
                AddLocationTextField.delegate = self
                AddLocationTextField.addTarget(self, action: #selector(handleLocationViewTapped(_:)), for: .touchDown)
                AddLocationTextField.addTarget(self, action: #selector(CameraViewController.textFieldDidChange(_:)), for: .editingChanged)
                AddLocationView.addSubview(AddLocationTextField)
            }
            distanceAway = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let distanceAway = distanceAway {
                distanceAway.textColor = .lightGray
                distanceAway.text = ""
                distanceAway.frame = CGRect(x: (addLocationIcon?.frame.maxX)!+10, y: 10, width: 60, height: 10)
                distanceAway.font = UIFont(name: Constants.globalFont, size: 9)
                AddLocationView.addSubview(distanceAway)
            }
            AddLocationView.backgroundColor = .darkGray.withAlphaComponent(0.5)
            AddLocationView.layer.cornerRadius = 4
            AddLocationView.alpha = 0
            let locationTapped = UITapGestureRecognizer(target: self, action: #selector(handleLocationViewTapped(_:)))
            AddLocationView.addGestureRecognizer(locationTapped)
            AddLocationView.isUserInteractionEnabled = true
//            AddLocationTextField?.addGestureRecognizer(locationTapped)
            self.view.addSubview(AddLocationView)
        }
        AddPeopleView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let AddPeopleView = AddPeopleView {
            addPeopleIcon = UIImageView(image: UIImage(systemName: "person.badge.plus")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .light, scale: .small)))
            if let addPeopleIcon = addPeopleIcon {
                addPeopleIcon.backgroundColor = .clear
                addPeopleIcon.tintColor = .lightGray.withAlphaComponent(0.7)
                addPeopleIcon.contentMode = .scaleAspectFit
                addPeopleIcon.layer.cornerRadius = 4
//                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backAddressTapped(tapGestureRecognizer:)))
//                addPeopleIcon.isUserInteractionEnabled = true
//                addPeopleIcon.addGestureRecognizer(tapGestureRecognizer)
                AddPeopleView.addSubview(addPeopleIcon)
            }
            AddPeopleTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let AddPeopleTextField = AddPeopleTextField {
                AddPeopleTextField.backgroundColor = .clear
                AddPeopleTextField.font = UIFont(name: Constants.globalFont, size: 13)
                AddPeopleTextField.attributedPlaceholder = NSAttributedString(string: "Tag People - Coming soon :P",
                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
                AddPeopleTextField.textColor = .white
                AddPeopleTextField.isUserInteractionEnabled = false
//                AddPeopleTextField.delegate = self
//                AddPeopleTextField.addTarget(self, action: #selector(handleLocationViewTapped(_:)), for: .touchDown)
//                AddPeopleTextField.addTarget(self, action: #selector(CameraViewController.textFieldDidChange(_:)), for: .editingChanged)
                AddPeopleView.addSubview(AddPeopleTextField)
            }
            //            AddPeopleView.backgroundColor = .darkGray.withAlphaComponent(0.5)
            AddPeopleView.backgroundColor = .darkGray.withAlphaComponent(0.2)
            AddPeopleView.layer.cornerRadius = 4
            AddPeopleView.alpha = 0
            AddPeopleView.isUserInteractionEnabled = false
            rightArrowPeople = UIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let rightArrowPeople = rightArrowPeople {
                rightArrowPeople.image = UIImage(systemName: "chevron.right")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .light, scale: .small))
                rightArrowPeople.tintColor = .lightGray.withAlphaComponent(0.7)
                rightArrowPeople.contentMode = .scaleAspectFit
                AddPeopleView.addSubview(rightArrowPeople)
            }
//            let locationTapped = UITapGestureRecognizer(target: self, action: #selector(handleLocationViewTapped(_:)))
//            AddLocationView.addGestureRecognizer(locationTapped)
//            AddLocationTextField?.addGestureRecognizer(locationTapped)
            self.view.addSubview(AddPeopleView)
        }
        AddTagsView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let AddTagsView = AddTagsView {
            addTagsIcon = UIImageView(image: UIImage(systemName: "number")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .light, scale: .small)))
            if let addTagsIcon = addTagsIcon {
                addTagsIcon.backgroundColor = .clear
                addTagsIcon.tintColor = .lightGray.withAlphaComponent(0.7)
                addTagsIcon.contentMode = .scaleAspectFit
                addTagsIcon.layer.cornerRadius = 4
//                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backAddressTapped(tapGestureRecognizer:)))
                AddTagsView.isUserInteractionEnabled = false
//                addPeopleIcon.addGestureRecognizer(tapGestureRecognizer)
                AddTagsView.addSubview(addTagsIcon)
            }
            AddTagsTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let AddTagsTextField = AddTagsTextField {
                AddTagsTextField.backgroundColor = .clear
                AddTagsTextField.font = UIFont(name: Constants.globalFont, size: 13)
                AddTagsTextField.attributedPlaceholder = NSAttributedString(string: "Hashtags - Coming soon :P",
                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
                AddTagsTextField.textColor = .white
                AddTagsTextField.isUserInteractionEnabled = false
//                AddPeopleTextField.delegate = self
//                AddPeopleTextField.addTarget(self, action: #selector(handleLocationViewTapped(_:)), for: .touchDown)
//                AddPeopleTextField.addTarget(self, action: #selector(CameraViewController.textFieldDidChange(_:)), for: .editingChanged)
                AddTagsView.addSubview(AddTagsTextField)
            }
//            AddTagsView.backgroundColor = .darkGray.withAlphaComponent(0.5)
            AddTagsView.backgroundColor = .darkGray.withAlphaComponent(0.2)
            AddTagsView.layer.cornerRadius = 4
            AddTagsView.alpha = 0
            AddTagsView.isUserInteractionEnabled = false
//            let locationTapped = UITapGestureRecognizer(target: self, action: #selector(handleLocationViewTapped(_:)))
//            AddLocationView.addGestureRecognizer(locationTapped)
//            AddLocationTextField?.addGestureRecognizer(locationTapped)
            self.view.addSubview(AddTagsView)
        }
        locationSearchResults = UITableView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let locationSearchResults = locationSearchResults {
            locationSearchResults.delegate = self
            locationSearchResults.dataSource = self
            locationSearchResults.backgroundColor = .clear
            locationSearchResults.alpha = 0
            self.view.addSubview(locationSearchResults)
        }
        self.flashButton = UIButton(type: .custom)
        if let flashButton = self.flashButton {
            flashButton.setImage(UIImage(systemName: "bolt.badge.a.fill")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
            flashButton.addTarget(self, action: #selector(handleFlashButton(_:)), for: .touchUpInside)
            
//            flashButton.imageView?.contentMode = .scaleAspectFit
            flashButton.frame = CGRect(x: UIScreen.main.bounds.width - 20 - 40, y: (previewView?.frame.minY)! + 20, width: 40, height: 40)
            flashButton.setTitleColor(.white, for: .normal)
            flashButton.tintColor = .white
            flashButton.backgroundColor = .clear
//            toggleTorch(on: true)
//            flashButton.setTitle("Auto", for: .normal)
            print("adding flash button")
            print(" is flash mode available: \(NextLevel.shared.isFlashAvailable)")
            print(" is torch mode available: \(NextLevel.shared.isTorchAvailable)")
            if NextLevel.shared.isFlashAvailable == false || NextLevel.shared.isTorchAvailable == false {
                flashButton.setImage(UIImage(systemName: "bolt.slash.fill")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
            }
            let flashToggle = UITapGestureRecognizer(target: self, action: #selector(handleFlashButton(_:)))
            flashButton.addGestureRecognizer(flashToggle)
            flashButton.isUserInteractionEnabled = true
            self.view.addSubview(flashButton)
            
        }
        self.goBackButton = UIButton(type: .custom)
        if let goBackButton = self.goBackButton {
            goBackButton.setImage(UIImage(systemName: "chevron.left")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
            goBackButton.addTarget(self, action: #selector(handleBackbutton(_:)), for: .touchUpInside)
            goBackButton.frame = CGRect(x: 20, y: (previewView?.frame.minY)! + 20, width: 40, height: 40)
            goBackButton.setTitleColor(.white, for: .normal)
            goBackButton.tintColor = .white
            goBackButton.backgroundColor = .darkGray.withAlphaComponent(0.5)
            goBackButton.isUserInteractionEnabled = true
            goBackButton.layer.cornerRadius = Constants.borderRadius
        }
        self.closeButton = UIButton(type: .custom)
        if let closeButton = self.closeButton {
            closeButton.setImage(UIImage(systemName: "xmark")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
            closeButton.addTarget(self, action: #selector(handleCloseButton(_:)), for: .touchUpInside)
            closeButton.frame = CGRect(x: 20, y: (previewView?.frame.minY)! + 20, width: 40, height: 40)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.tintColor = .white
            closeButton.backgroundColor = .clear
            closeButton.isUserInteractionEnabled = true
            self.view.addSubview(closeButton)
        }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self.filterImageCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: layout)
        if let filterImageCollectionView = self.filterImageCollectionView {
            let nib = UINib(nibName: "FilterCollectionViewCell", bundle: nil)
            filterImageCollectionView.register(nib, forCellWithReuseIdentifier: "filterCell")
            filterImageCollectionView.delegate = self
            filterImageCollectionView.dataSource = self
            filterImageCollectionView.alpha = 0
            filterImageCollectionView.backgroundColor = .black
            self.view.addSubview(filterImageCollectionView)
        }
        
        let menuViewHeight = UIScreen.main.bounds.height - (previewView?.frame.maxY)!
        self.menubarUIView = UIView(frame: CGRect(x: 0, y: (previewView?.frame.maxY)!, width: UIScreen.main.bounds.width, height: menuViewHeight))
        if let menubarUIView = menubarUIView {
            menubarUIView.backgroundColor = .black
            self.view.addSubview(menubarUIView)
            
//            let LeftAndRightPaddingInView = 80
//            let PaddingBetweenEachother = 10
//            let buttonWidths = (Int(UIScreen.main.bounds.width) - (LeftAndRightPaddingInView*2) - (PaddingBetweenEachother * 2)) / 3
            
            let LeftAndRightPaddingInView = 100
            let PaddingBetweenEachother = 0
            let buttonWidths = 100
            let buttonY = 0
            let buttonHeights = menubarUIView.frame.height - 10
            
//            let postButton = UIButton(frame: CGRect(x: LeftAndRightPaddingInView, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            let postButton = UIButton(frame: CGRect(x: (Int(UIScreen.main.bounds.width) / 2) - buttonWidths, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            
            postButton.tintColor = UIColor.white.withAlphaComponent(0.4)
            postButton.backgroundColor = UIColor.clear
            postButton.setTitle("POST", for: .normal)
            postButton.titleLabel?.font = UIFont(name: Constants.globalFontBold, size: 13)
            postButton.isUserInteractionEnabled = true
            postButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            
//            let storyButton = UIButton(frame: CGRect(x: Int(postButton.frame.maxX) + PaddingBetweenEachother, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            let storyButton = UIButton(frame: CGRect(x: Int(UIScreen.main.bounds.width) / 2, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            storyButton.tintColor = UIColor.white
            storyButton.backgroundColor = UIColor.clear
            storyButton.setTitle("STORY", for: .normal)
            storyButton.titleLabel?.font = UIFont(name: Constants.globalFontBold, size: 13)
            storyButton.isUserInteractionEnabled = true
            storyButton.setTitleColor(UIColor.white.withAlphaComponent(1), for: .normal)
            
            let textButton = UIButton(frame: CGRect(x: Int(storyButton.frame.maxX) + PaddingBetweenEachother, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            textButton.tintColor = UIColor.white.withAlphaComponent(0.4)
            textButton.backgroundColor = UIColor.clear
            textButton.setTitle("GLIMPSE", for: .normal)
            textButton.isHidden = true // REMOVE THIS TO SHOW GLIMPSE BUITTON
            textButton.titleLabel?.font = UIFont(name: Constants.globalFontBold, size: 13)
            textButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            
            
            postButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
            storyButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
            textButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
            self.glimpsView = UIView(frame: CGRect(x: 0, y: Int(textButton.frame.minY) + 25, width: 30, height: 15))
            if let glimpsView = self.glimpsView {
                glimpsView.backgroundColor = Constants.secondaryColor.hexToUiColor()
                glimpsView.layer.cornerRadius = 4
                glimpsView.clipsToBounds = true
                glimpsView.isUserInteractionEnabled = false
                self.gimpsText = UILabel(frame: CGRect(x: 0, y: 0, width: glimpsView.frame.width, height: glimpsView.frame.height))
                if let gimpsText = gimpsText {
                    gimpsText.text = "NEW"
                    gimpsText.textAlignment = .center
                    gimpsText.font = UIFont(name: Constants.globalFontBold, size: 7)
                    gimpsText.textColor = Constants.primaryColor.hexToUiColor()
                    glimpsView.addSubview(gimpsText)
                    self.glimpsLogo = UIImageView(frame: CGRect(x: gimpsText.frame.maxX, y: 0, width: 10, height: glimpsView.frame.height))
                    if let glimpsLogo = self.glimpsLogo {
                        glimpsLogo.image = UIImage(systemName: "timelapse")?.applyingSymbolConfiguration(.init(pointSize: 12, weight: .medium, scale: .medium))?.image(withTintColor: Constants.primaryColor.hexToUiColor())
                        glimpsLogo.contentMode = .scaleAspectFit
//                        glimpsView.addSubview(glimpsLogo)
                    }
                    
                }
                glimpsView.center.x = textButton.center.x
                self.menubarUIView?.addSubview(postButton)
                self.menubarUIView?.addSubview(storyButton)
                self.menubarUIView?.addSubview(textButton)
//                self.menubarUIView?.addSubview(glimpsView)
                
            }
            
            
            
            let littleBarHeight = 2
//            self.littleBottomBar = UIView(frame: CGRect(x: 0, y: (Int(buttonHeights) / 2) + 10, width: buttonWidths - 10, height: littleBarHeight))
            self.littleBottomBar = UIView(frame: CGRect(x: 0, y: (Int(buttonHeights) / 2) + 10, width: buttonWidths - 40, height: littleBarHeight))
            self.littleBottomBar?.center.x = storyButton.center.x
            self.littleBottomBar?.backgroundColor = .white
            self.littleBottomBar?.layer.cornerRadius = 4
            
            
            self.menubarUIView?.addSubview(littleBottomBar!)
            
            if let flipButton = self.flipButton, let recordButton = self.recordButton {
//                let flipButtonWidth = UIScreen.main.bounds.width - textButton.frame.maxX - PaddingBetweenEachother - (PaddingBetweenEachother*2)
//                flipButton.frame = CGRect(x: Int(textButton.frame.maxX) + LeftAndRightPaddingInView / 4, y: 30, width: 40, height: 40)
                flipButton.frame = CGRect(x: UIScreen.main.bounds.width - 40 - 25, y: 30, width: 40, height: 40)
                flipButton.backgroundColor = .darkGray.withAlphaComponent(0.5)
                flipButton.center.y = (postButton.center.y)
                flipButton.layer.cornerRadius = flipButton.frame.width / 2
                flipButton.clipsToBounds = true
                menubarUIView.addSubview(flipButton)
            }
            photoGallery = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let photoGallery = self.photoGallery {
                photoGallery.frame = CGRect(x: LeftAndRightPaddingInView / 4, y: 30, width: 40, height: 40)
                photoGallery.backgroundColor = .darkGray.withAlphaComponent(0.5)
                photoGallery.center.y = (postButton.center.y)
                photoGallery.layer.cornerRadius = Constants.borderRadius
                photoGallery.clipsToBounds = true
                photoGallery.layer.borderColor = UIColor.white.cgColor
                photoGallery.layer.borderWidth = 2
                print("fetching last image")
                photoGallery.addTarget(self, action: #selector(handleGalaryTapped(_:)), for: .touchUpInside)
                loadLastImageThumb { [weak self] (image) in
                      DispatchQueue.main.async {
                          self?.photoGallery?.setImage(image, for: .normal)
                          photoGallery.contentMode = .scaleAspectFill
                          photoGallery.imageView?.contentMode = .scaleAspectFill
                          menubarUIView.addSubview(photoGallery)
                      }
                }
            }
        }
        snapPicButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let snapPicButton = snapPicButton {
            snapPicButton.layer.borderWidth = 6
            snapPicButton.layer.borderColor = UIColor.white.cgColor
            let snapWidthHeight = 80
            let snapX = (Int(Float16(UIScreen.main.bounds.width)) / 2) - (snapWidthHeight / 2)
            snapPicButton.frame = CGRect(x: snapX, y: Int((previewView?.frame.maxY)!) - snapWidthHeight - 40, width: snapWidthHeight, height: snapWidthHeight)
            snapPicButton.layer.cornerRadius = snapPicButton.frame.width / 2
//            snapPicButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
//            handlePhotoTapGestureRecognizer
            let tapTakePhoto = UITapGestureRecognizer(target: self, action: #selector(handlePhotoTapGestureRecognizer(_:)))
            snapPicButton.addGestureRecognizer(tapTakePhoto)
            snapPicButton.isUserInteractionEnabled = true
            self.view.addSubview(snapPicButton)
        }
        // gestures
        self.gestureView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let gestureView = self.gestureView, let controlDockView = self.controlDockView {
            gestureView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            gestureView.frame.size.height -= controlDockView.frame.height
            gestureView.backgroundColor = .clear
            let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))

           pinchRecognizer.delegate = self
            previewView?.addGestureRecognizer(pinchRecognizer)
//            self.view.addSubview(gestureView)

            self.focusTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleFocusTapGestureRecognizer(_:)))
            if let focusTapGestureRecognizer = self.focusTapGestureRecognizer {
                focusTapGestureRecognizer.delegate = self
                focusTapGestureRecognizer.numberOfTapsRequired = 1
                previewView?.addGestureRecognizer(focusTapGestureRecognizer)
            }
        }
        
        
        
        
        // Configure NextLevel by modifying the configuration ivars
        let nextLevel = NextLevel.shared
        nextLevel.delegate = self
        nextLevel.deviceDelegate = self
        nextLevel.flashDelegate = self
        nextLevel.videoDelegate = self
        nextLevel.photoDelegate = self
        nextLevel.metadataObjectsDelegate = self

        // video configuration
        nextLevel.videoConfiguration.preset = AVCaptureSession.Preset.hd1280x720
        nextLevel.videoConfiguration.bitRate = 5500000
        nextLevel.videoConfiguration.maxKeyFrameInterval = 30
        nextLevel.videoConfiguration.profileLevel = AVVideoProfileLevelH264HighAutoLevel

        // audio configuration
        nextLevel.audioConfiguration.bitRate = 96000

        // metadata objects configuration
        nextLevel.metadataObjectTypes = [AVMetadataObject.ObjectType.qr] //AVMetadataObject.ObjectType.face, AVMetadataObject.ObjectType.qr
        
        
        // double tap to reverse camera
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        self.previewView?.addGestureRecognizer(tap)
        do {
//            try NextLevel.shared.start()
            NextLevel.shared.flashMode = .auto
        } catch {
            print("* some error starting nextlevel \(error)")
        }
        
//
        let seconds = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
//            NextLevel.shared.flipCaptureDevicePosition()
            NextLevel.shared.devicePosition = .front
        }
        searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.pointOfInterest])
    }
    func toggleTorch(on: Bool) {
        guard
            let device = AVCaptureDevice.default(for: AVMediaType.video),
            device.hasTorch
        else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    func uploadPic(image: UIImage, completion: @escaping (_ url: String?, _ locationUID: String?) -> Void) {
        let userID : String = (Auth.auth().currentUser?.uid)!
        let randomString = randomString(length: 20)
        let storageRef = Storage.storage().reference().child("post_photos/\(userID)/\(randomString)")
//        guard let imageData = cameraPhotoResult!.image!.jpegData(compressionQuality: 0.75) else { return }
        print("* cropped image")
        guard let imageData = image.nx_croppedImage(to: 1.25).jpegData(compressionQuality: 0.75) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        // Add a progress observer to an upload task
        
        let uploadTask = storageRef.putData(imageData, metadata: metaData) { metaData, error in
            if error == nil, metaData != nil {
                
                storageRef.downloadURL { url, error in
                    completion(url?.absoluteString, randomString)
                    // success!
                }
            } else {
                // failed
                completion(nil, nil)
            }
        }
        
    }
    func uploadPostMedia(completion: @escaping (_ url: String?, _ locationUID: String?) -> Void) {
        let userID : String = (Auth.auth().currentUser?.uid)!
        let randomString = randomString(length: 20)
        let storageRef = Storage.storage().reference().child("post_photos/\(userID)/\(randomString)")
//        guard let imageData = cameraPhotoResult!.image!.jpegData(compressionQuality: 0.75) else { return }
        print("* cropped image")
        guard let imageData = cameraPhotoResult!.image!.nx_croppedImage(to: 1.25).jpegData(compressionQuality: 0.75) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        // Add a progress observer to an upload task
        
        let uploadTask = storageRef.putData(imageData, metadata: metaData) { metaData, error in
            if error == nil, metaData != nil {
                
                storageRef.downloadURL { url, error in
                    completion(url?.absoluteString, randomString)
                    // success!
                }
            } else {
                // failed
                completion(nil, nil)
            }
        }
        let observer = uploadTask.observe(.progress) { snapshot in
          // A progress event occured
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                        / Double(snapshot.progress!.totalUnitCount)
            let floatComplete = Double(snapshot.progress!.completedUnitCount)
            / Double(snapshot.progress!.totalUnitCount)
            print("* uploading: \(percentComplete)")
            self.actualPostButton?.update(percent: percentComplete)
        }
        
    }
    @objc func backAddressTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        moveAddressStuffBack()
        self.AddLocationTextField?.text = ""
    }
    func moveAddressStuffBack() {
        if AddLocationView?.frame.minY == goBackButton?.frame.minY {
            
            
            UIView.animate(withDuration: 0.2, animations: {
                    self.view.layoutIfNeeded() // add this
                
                self.AddLocationView?.frame = CGRect(x: (self.cameraPhotoResult?.frame.minX)!, y: self.AddPeopleView!.frame.maxY + 10, width: UIScreen.main.bounds.width - (self.cameraPhotoResult!.frame.minX * 2), height: 50)
                self.addLocationIcon?.image = UIImage(systemName: "location")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .light, scale: .small))
                self.locationSearchResults!.alpha = 0
                }) { (success) in
                    self.view.layoutIfNeeded()
                    self.AddLocationTextField?.resignFirstResponder()
                    self.goBackButton?.fadeIn()
                    self.stepNameLabel?.fadeIn()
                    self.actualPostButton?.fadeIn()
                    self.cameraPhotoResult?.fadeIn()
                    self.captionView?.fadeIn()
                    self.AddPeopleView?.fadeIn()
                    self.AddTagsView?.fadeIn()
                    if self.numOfImageLabel?.text ?? "" != "" && self.numOfImageLabel?.text ?? "" != "1" && self.numOfImageLabel?.text ?? "" != "0" {
                        self.numOfImageLabel?.fadeIn()
                    }
                }
        }
    }
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        let searchString = textField.text
        searchCompleter.queryFragment = searchString ?? ""
        
    }
    @objc internal func handleGalaryTapped(_ view: UIView) {
//        imagePicker.sourceType = .photoLibrary
        
//            present(imagePicker, animated: true)
        let config = ZLPhotoConfiguration.default()
        if self.postType == "post" {
            config.maxSelectCount = 9
        } else {
            config.maxSelectCount = 1
        }
        config.columnCount = 3
        
        config.sortAscending = true
        config.allowSelectVideo = false
        config.showSelectedBorder = true
        config.cellCornerRadio = 8
        config.allowSelectOriginal = false
        config.saveNewImageAfterEdit = false
        config.editImageConfiguration.clipRatios = [ZLImageClipRatio(title: "Default", whRatio: 1.25)]
//        hideAllPhotoComponents()
        let ps = ZLPhotoPreviewSheet()
        ps.selectImageBlock = { [weak self] results, isOriginal in
            guard let `self` = self else { return }
            let selectedImages = results.map { $0.image.nx_croppedImage(to: 1.25) }
            self.postPhotos = selectedImages
//            self.selectedAssets = results.map { $0.asset }
//            self.isOriginal = isOriginal
//            self.collectionView.reloadData()
            debugPrint("# images: \(results.count)")
//            debugPrint("assets: \(self.selectedAssets)")
            debugPrint("isEdited: \(results.map { $0.isEdited })")
            debugPrint("isOriginal: \(isOriginal)")
            if results.count != 0 {
//                self.showPostDetailOptions()
                if self.postType == "post" {
//                    self.cameraPhotoResult = UIImageView(image: results[0].image)
                    print("* preview frame: \(self.previewView!.frame)")
//                    self.cameraPhotoResult?.frame = self.previewView!.frame
//                    self.cameraPhotoResult?.layer.cornerRadius = (self.previewView?.layer.cornerRadius)!
//                    self.cameraPhotoResult?.clipsToBounds = true
                    self.cameraPhotoResult = UIImageView(image: selectedImages[0])
                    self.OriginalPostImageForFiltering = selectedImages[0]
                    self.cameraPhotoResult?.frame = self.previewView!.frame
                    self.cameraPhotoResult?.layer.cornerRadius = (self.previewView?.layer.cornerRadius)!
                    self.cameraPhotoResult?.clipsToBounds = true
                    
                    self.cameraPhotoResult?.image = selectedImages[0]
                    self.cameraPhotoResult?.contentMode = .scaleAspectFill
                    
                    self.view.addSubview(self.cameraPhotoResult!)
                    self.view?.sendSubviewToBack(self.cameraPhotoResult!)
                    self.view.addSubview(self.goBackButton!)
                    self.view.addSubview(self.stepNameLabel!)
                    self.hideAllPhotoComponents()
                    self.showPostDetailOptions()
                    if results.count > 1 {
                        print("* more than one image selecting, adding number counter")
                        let tmpWid = 20
                        self.numOfImageLabel = UILabel(frame: CGRect(x: Int(self.cameraPhotoResult?.frame.maxX ?? 0) - tmpWid - 5, y: Int(self.cameraPhotoResult?.frame.minY ?? 0) + 5, width: tmpWid, height: tmpWid))
                        print("* numOfimageLabel frame \(self.numOfImageLabel?.frame)")
                        self.numOfImageLabel?.textColor = .white
                        self.numOfImageLabel?.textAlignment = .center
                        self.numOfImageLabel?.backgroundColor = Constants.primaryColor.hexToUiColor()
                        self.numOfImageLabel?.font = UIFont(name: Constants.globalFontMedium, size: 13)
                        self.numOfImageLabel?.text = "\(results.count)"
                        self.numOfImageLabel?.layer.cornerRadius = 4
                        self.numOfImageLabel?.clipsToBounds = true
//                        self.numOfImageLabel?.alpha = 0
                        if let numOfImageLabel = self.numOfImageLabel {
                            print("* adding subview: \(self.numOfImageLabel?.text)")
                            self.view.addSubview(numOfImageLabel)
//                            numOfImageLabel.fadeIn()
                        }
                    }
                } else {
                    print("* story post")
                    self.hideAllPhotoComponents()
                    self.doneEditing(image: results[0].image)
                }
            }
            
        }
        ps.showPhotoLibrary(sender: self)
    }
    func imagePickerController(didFinishPickingMediaWithInfo info: [String : Any]) {
        
        print("* finished picking photo")
//        let imageURL = info[UIImagePickerControllerImageURL] as? URL
//
//        storageRef.putFile(from: imageURL!, metadata: nil) { metadata, error in
//            if let error = error {
//                print(error)
//                self.spinner.stopAnimating()
//            } else {
//                print("uplaod success!")
//                // TODO: handle Vision API response
//            }
//        }
//
        dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            cameraPhotoResult = UIImageView(image: image)
            cameraPhotoResult?.frame = previewView!.frame
            cameraPhotoResult?.layer.cornerRadius = (self.previewView?.layer.cornerRadius)!
            cameraPhotoResult?.clipsToBounds = true
            self.imagePicker.dismiss(animated: true, completion: nil)
            uploadedFromCameraRoll = true
            hideAllPhotoComponents()
            if postType == "post" {
//                showPhotoPostComponents()
                // create controller for brightroom
                // Create an image provider
                let imageProvider = ImageProvider(image: image) // URL, Data are also supported.
                
                let stack = EditingStack.init(
                  imageProvider: imageProvider
                )
                print("* presenting editing stack")
                self._present(stack, square: false)
                
            } else if postType == "story" {
                let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))

                //PhotoEditorDelegate
                photoEditor.photoEditorDelegate = self

                //The image to be edited
                photoEditor.image = image

                //Optional: To hide controls - array of enum control
                photoEditor.hiddenControls = [.crop, .share, .sticker]

                //Optional: Colors for drawing and Text, If not set default values will be used
//                photoEditor.colors = [.red,.blue,.green]
                
                //Present the View Controller
                present(photoEditor, animated: false, completion: nil)
            }
//            self.imagePreview.image = image
        }

        
    }
    @objc internal func handleLocationViewTapped(_ view: UIView) {
        print("* location view tapped, moving stuff around")
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let dif = 15
        AddLocationTextField?.frame = CGRect(x: Int((addLocationIcon?.frame.maxX)! + CGFloat(dif)), y: dif, width: Int((AddLocationView?.frame.width)! - (addLocationIcon?.frame.maxY)!) - 10, height: 50-dif*2)
        self.distanceAway!.text = ""
        
        if AddLocationView?.frame.minY != goBackButton?.frame.minY {
            goBackButton?.fadeOut()
            stepNameLabel?.fadeOut()
            actualPostButton?.fadeOut()
            cameraPhotoResult?.fadeOut()
            captionView?.fadeOut()
            AddPeopleView?.fadeOut()
            AddTagsView?.fadeOut()
            numOfImageLabel?.fadeOut()
            UIView.animate(withDuration: 0.2, animations: {
                    self.view.layoutIfNeeded() // add this
                self.AddLocationView?.frame = CGRect(x: (self.AddLocationView?.frame.minX)!, y: self.goBackButton?.frame.minY ?? 0, width: self.AddLocationView!.frame.width, height: self.AddLocationView?.frame.height ?? 0)
                self.addLocationIcon?.image = UIImage(systemName: "chevron.left")?.applyingSymbolConfiguration(.init(pointSize: 10, weight: .light, scale: .small))
                self.locationSearchResults!.frame = CGRect(x: self.AddLocationView!.frame.minX, y: self.AddLocationView!.frame.maxY + 10, width: self.AddLocationView!.frame.width, height: UIScreen.main.bounds.height - self.AddLocationView!.frame.maxY - 10)
                }) { (success) in
                    self.view.layoutIfNeeded()
                    self.AddLocationTextField?.becomeFirstResponder()
                    self.locationSearchResults?.fadeIn()
                }
        }
    }
    @objc internal func handleFlashButton(_ button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
        print("* current flash mode: \(NextLevel.shared.flashMode)")
        if NextLevel.shared.flashMode == .auto {
            print("* setting flash mode to on")
            NextLevel.shared.flashMode = .on
            flashButton?.setImage(UIImage(systemName: "bolt.fill")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
        } else if NextLevel.shared.flashMode == .on {
            NextLevel.shared.flashMode = .off
            
            print("* setting flash mode to off")
            flashButton?.setImage(UIImage(systemName: "bolt.slash.fill")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
        } else {
            print("* setting flash mode to auto")
            NextLevel.shared.flashMode = .auto
            flashButton?.setImage(UIImage(systemName: "bolt.badge.a.fill")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
        }
        
    }
    @objc func takePhoto(sender: UIButton!) {
        print("* takephoto called")
        let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
        NextLevel.shared.capturePhoto()
    }
    func loadLastImageThumb(completion: @escaping (UIImage) -> ()) {
        let imgManager = PHImageManager.default()
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)

        if let last = fetchResult.lastObject {
            let scale = UIScreen.main.scale
            let size = CGSize(width: 100 * scale, height: 100 * scale)
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast

            imgManager.requestImage(for: last, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: { (image, _) in
                if let image = image {
                    completion(image)
                }
            })
        }

    }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completer.results
        locationSearchResults?.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCompleter.results.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row != 0 {
            
            let mapItem = searchCompleter.results[indexPath.row-1]
            print("* making text: \(mapItem.title)")
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            
            cell.textLabel?.attributedText = highlightedText(mapItem.title, inRanges: mapItem.titleHighlightRanges, size: 17.0)
            cell.detailTextLabel?.text = mapItem.subtitle
            cell.contentView.backgroundColor = UIColor.black
            cell.detailTextLabel?.textColor = .lightGray
            
            return cell
        } else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            print("* making default: \(AddLocationTextField?.text ?? "")")
            cell.textLabel?.text = AddLocationTextField?.text ?? ""
            cell.detailTextLabel?.text = ""
            cell.textLabel?.textColor = .white
            if let font = UIFont(name: "\(String(describing: cell.textLabel?.font))", size: 15) {
                cell.textLabel?.font = font
            }
            
            cell.contentView.backgroundColor = UIColor.black
            cell.detailTextLabel?.textColor = .lightGray
            
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row != 0 {
            print("* Selected at \(searchCompleter.results[indexPath.row-1].title)")
            print(searchCompleter.results[indexPath.row-1].subtitle)
    //        let currentLat = self.locationManager.location!.coordinate.latitude
    //        let currentLong = self.locationManager.location!.coordinate.longitude
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(searchCompleter.results[indexPath.row-1].subtitle) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                else {
                    // handle no location found
                    return
                }
                
                // Use your location
                if let loc = self.locationManager.location {
                    let distanceInMeters = location.distance(from: loc)
                    print("* got distance in meters from current location: \(distanceInMeters)")
                    if(distanceInMeters <= 1609)
                     {
                     // under 1 mile
                        self.AddLocationTextField?.text = "\(self.searchCompleter.results[indexPath.row-1].title)"
                        self.distanceAway?.text = "\(Int(distanceInMeters*3.28084)) feet away"
                     }
                     else
                    {
                     // out of 1 mile
                         self.AddLocationTextField?.text = "\(self.searchCompleter.results[indexPath.row-1].title)"
                         self.distanceAway?.text = "\(Int(distanceInMeters*0.000621371)) miles away"
                     }
                }
                
            }
        } else {
            
        }
        let dif = 15
        AddLocationTextField!.frame = CGRect(x: Int((addLocationIcon?.frame.maxX)! + CGFloat(dif)), y: dif-5, width: Int((AddLocationView?.frame.width)! - (addLocationIcon?.frame.maxY)!) - 10, height: 50-dif*2)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        moveAddressStuffBack()
    }
    func highlightedText(_ text: String, inRanges ranges: [NSValue], size: CGFloat) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        let regular = UIFont.systemFont(ofSize: size)
        attributedText.addAttribute(NSAttributedString.Key.font, value:regular, range:NSMakeRange(0, text.count))
        attributedText.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "\(Constants.globalFont)", size: 15)!, range:NSMakeRange(0, text.count))
        attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.darkGray, range: NSMakeRange(0, text.count))
        for value in ranges {
            //            attributedText.addAttribute(NSAttributedString.Key.font, value:bold, range:value.rangeValue)
//            attributedText.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "\(Constants.globalFont)-Bold", size: 16), range:value.rangeValue)
            attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.white, range: value.rangeValue)
        }
        return attributedText
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.white
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter a caption"
            textView.textColor = UIColor.lightGray
        }
    }
    @objc func menuButtonTapped(sender: UIButton!) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded() // add this
//            self.littleBottomBar?.frame = CGRect(x: sender.frame.minX + 5, y: CGFloat((Int(sender.frame.height) / 2) + 10), width: self.littleBottomBar!.frame.width, height: self.littleBottomBar!.frame.height)
            self.littleBottomBar?.center.x = sender.center.x

            }) { (success) in
                self.view.layoutIfNeeded()
            }
        if sender == menubarUIView?.subviews[0] {
            postType = "post"
            print("posts menu bar button tapped")
            (menubarUIView?.subviews[0] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(1), for: .normal)
            (menubarUIView?.subviews[1] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            (menubarUIView?.subviews[2] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded() // add this
                if UIDevice.current.hasNotch {
                    self.previewView?.frame = CGRect(x: (self.previewView?.frame.minX)!, y: (self.closeButton?.frame.maxY)! + 20, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.25)
                } else {
                    self.previewView?.frame = CGRect(x: (self.previewView?.frame.minX)!, y: (self.closeButton?.frame.minY)!, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.25)
                }
                
                NextLevel.shared.previewLayer.frame = self.previewView!.bounds
//                self.previewView?.frame = CGRect(x: (self.previewView?.frame.minX)!, y: (self.previewView?.frame.minY)!, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.4)
                let snapX = (Int(Float16(UIScreen.main.bounds.width)) / 2) - ((80) / 2)
                if UIDevice.current.hasNotch {
                    self.snapPicButton?.frame = CGRect(x: snapX, y: Int((self.previewView?.frame.maxY)!) + 30, width: 80, height: 80)
                } else {
                    self.snapPicButton?.frame = CGRect(x: snapX, y: Int((self.previewView?.frame.maxY)!) - 40, width: 80, height: 80)
                }
                
//                let distanceForButton = Int(UIScreen.main.bounds.height) - Int(self.menubarUIView?.frame.height ?? 0) - Int((self.previewView?.frame.maxY)!)
//                let snapPicWidthHeight = distanceForButton // used to be 80
//                let snapX = (Int(Float16(UIScreen.main.bounds.width)) / 2) - ((snapPicWidthHeight) / 2)
//                let snapPicY =  Int((self.previewView?.frame.maxY)!)
//                self.snapPicButton?.frame = CGRect(x: snapX, y: snapPicY, width: snapPicWidthHeight, height: snapPicWidthHeight)
//                self.snapPicButton?.layer.cornerRadius = CGFloat(snapPicWidthHeight / 2)
//
//                NextLevel.shared.videoConfiguration.aspectRatio = .instagram
                }) { (success) in
                    
                    self.view.layoutIfNeeded()
                }
        } else if sender == menubarUIView?.subviews[1] {
            print("stories menu bar button tapepd")
            postType = "story"
            (menubarUIView?.subviews[0] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            (menubarUIView?.subviews[1] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(1), for: .normal)
            (menubarUIView?.subviews[2] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            UIView.animate(withDuration: 0.3, animations: { [self] in
                    self.view.layoutIfNeeded() // add this
                self.previewView?.frame = CGRect(x: (self.previewView?.frame.minX)!, y: 40, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.77)
                let snapWidthHeight = 80
                let snapX = (Int(Float16(UIScreen.main.bounds.width)) / 2) - (snapWidthHeight / 2)
                snapPicButton!.frame = CGRect(x: snapX, y: Int((previewView?.frame.maxY)!) - snapWidthHeight - 40, width: snapWidthHeight, height: snapWidthHeight)
                NextLevel.shared.previewLayer.frame = self.previewView!.bounds
//                NextLevel.shared.videoConfiguration.aspectRatio = .instagramStories
                }) { (success) in
                    self.view.layoutIfNeeded()
                    
                }
        } else {
            print("glimpse menu bar button tapped")
            postType = "glimpse"
            (menubarUIView?.subviews[0] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            (menubarUIView?.subviews[1] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            (menubarUIView?.subviews[2] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(1), for: .normal)
            let config = ZLPhotoConfiguration.default()
            config.maxSelectCount = 30
            config.columnCount = 3
            
            config.sortAscending = true
            config.allowSelectVideo = false
            config.showSelectedBorder = true
            config.cellCornerRadio = 8
            config.allowSelectOriginal = false
            config.saveNewImageAfterEdit = false
            config.editImageConfiguration.clipRatios = [ZLImageClipRatio(title: "Default", whRatio: 1.25)]
    //        hideAllPhotoComponents()
            let ps = ZLPhotoPreviewSheet()
            ps.selectImageBlock = { [weak self] results, isOriginal in
                guard let `self` = self else { return }
                let selectedImages = results.map { $0.image }
                var tmp: [UIImage] = []
                for im in selectedImages {
//                    let tt = self.resizeImage(image: im.nx_croppedImage(to: 1.25), newWidth: UIScreen.main.bounds.width, newHeight: UIScreen.main.bounds.width*1.25)
                    let tt = self.ResizeImage(with: im, scaledToFill: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.25))
                    tmp.append(tt!)
                }
                
                self.postPhotos = tmp
    //            self.selectedAssets = results.map { $0.asset }
    //            self.isOriginal = isOriginal
    //            self.collectionView.reloadData()
                debugPrint("# images: \(results.count)")
    //            debugPrint("assets: \(self.selectedAssets)")
                debugPrint("isEdited: \(results.map { $0.isEdited })")
                debugPrint("isOriginal: \(isOriginal)")
                if results.count != 0 {
                    print("* got images for glimpse post")
                   
                    let defaultLengthPerPhoto = 1.5 // in seconds
                    print("* loading in initial gif stuff with default length (s) \(defaultLengthPerPhoto)")
                    self.updateGif(lengthPerImage: defaultLengthPerPhoto, shouldFadeInOut: false, transitionLength: 0)
                    do {
//                        let gif = try UIImage(gifName: "animated.gif")
                        let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                        let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
                        print("* loading via \(fileURL)")
//                        self.cameraPhotoResult = UIImageView(gifImage: gif, loopCount: -1)
                        if let fileURL = fileURL {
                            self.hideAllPhotoComponents()
                            let screenBounds = UIScreen.main.bounds
                            self.cameraPhotoResult = UIImageView(frame: CGRect(x: 0, y: 120, width: screenBounds.width, height: screenBounds.width*1.25))
                            if let cameraPhotoResult = self.cameraPhotoResult {
                                cameraPhotoResult.setGifFromURL(fileURL)
    //                            self.cameraPhotoResult?.image = UIImage(named: "appleIcon")
                                cameraPhotoResult.layer.cornerRadius = 12
                                cameraPhotoResult.clipsToBounds = true
                                cameraPhotoResult.contentMode = .scaleAspectFill
                                self.goBackButton?.alpha = 0
                                self.view.addSubview(self.goBackButton!)
                                self.goBackButton?.fadeIn()
                                cameraPhotoResult.fadeIn()
                                print("* valid gif, loading in")
                                self.view.addSubview((cameraPhotoResult))
                                (self.menubarUIView?.subviews[0] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
                                (self.menubarUIView?.subviews[1] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(1), for: .normal)
                                (self.menubarUIView?.subviews[2] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
                            }
                                
                        } else {
                            (self.menubarUIView?.subviews[1] as! UIButton).sendActions(for: .touchUpInside)
                        }
                        
                    } catch {
                        print("* some error in do: \(error)")
                        (self.menubarUIView?.subviews[1] as! UIButton).sendActions(for: .touchUpInside)
                    }
                } else {
                    (self.menubarUIView?.subviews[1] as! UIButton).sendActions(for: .touchUpInside)
                }
            }
            ps.cancelBlock = {
//                    guard let `self` = self else { return }
                (self.menubarUIView?.subviews[1] as! UIButton).sendActions(for: .touchUpInside)
            }
            ps.showPhotoLibrary(sender: self)
        }
    }
    func resizeImage(image: UIImage, newWidth: CGFloat, newHeight: CGFloat) -> UIImage {

       let scale = newWidth / image.size.width
//       let newHeight = image.size.height * scale
       UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.draw(in: CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
       UIGraphicsEndImageContext()

       return newImage
   }
    func ResizeImage(with image: UIImage?, scaledToFill size: CGSize) -> UIImage? {
        let scale: CGFloat = max(size.width / (image?.size.width ?? 0.0), size.height / (image?.size.height ?? 0.0))
        let width: CGFloat = (image?.size.width ?? 0.0) * scale
        let height: CGFloat = (image?.size.height ?? 0.0) * scale
        let imageRect = CGRect(x: (size.width - width) / 2.0, y: (size.height - height) / 2.0, width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image?.draw(in: imageRect)
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    func updateGif(lengthPerImage: Double, shouldFadeInOut: Bool, transitionLength: Double) {
        let images = postPhotos
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
                let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): lengthPerImage]] as CFDictionary
                
                let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileURL: URL? = documentsDirectoryURL?.appendingPathComponent("animated.gif")
                
                if let url = fileURL as CFURL? {
                    if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, images.count, nil) {
                        CGImageDestinationSetProperties(destination, fileProperties)
                        for image in images {
                            if let cgImage = image.cgImage {
                                CGImageDestinationAddImage(destination, cgImage, frameProperties)
                            }
                        }
                        if !CGImageDestinationFinalize(destination) {
                            print("Failed to finalize the image destination")
                        }
                        print("Updated gif @ Url = \(fileURL)")
                    }
                }
        
    }
    func deleteGif() {
        let fileNameToDelete = "animated.gif"
        var filePath = ""
        // Fine documents directory on device
         let dirs : [String] = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        if dirs.count > 0 {
            let dir = dirs[0] //documents directory
            filePath = dir.appendingFormat("/" + fileNameToDelete)
            print("Local path = \(filePath)")
         
        } else {
            print("Could not find local directory to store file")
            return
        }
        do {
             let fileManager = FileManager.default
            
            // Check if file exists
            if fileManager.fileExists(atPath: filePath) {
                // Delete file
                try fileManager.removeItem(atPath: filePath)
            } else {
                print("File does not exist")
            }
         
        }
        catch let error as NSError {
            print("An error took place: \(error)")
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CIFilterNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filterCell", for: indexPath) as! FilterCollectionViewCell
        if indexPath.row == 0{
            cell.populateCell(with: OriginalPostImageForFiltering!, at: indexPath)
        }else{
            let inputCIImage = CIImage(image: OriginalPostImageForFiltering!)!
            let filter = CIFilter(name: CIFilterNames[indexPath.row])
            filter!.setValue(inputCIImage, forKey: kCIInputImageKey)
            let cgImage = CIContext().createCGImage(filter!.outputImage!, from: (inputCIImage.extent))!
            if devicePosition == .front {
                cell.populateCell(with: UIImage(cgImage: cgImage).withHorizontallyFlippedOrientation(),at: indexPath)
            } else {
                cell.populateCell(with: UIImage(cgImage: cgImage),at: indexPath)
            }
            
        }
        if indexPath.row == index{
            cell.isFilterSelected()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
//        cameraService.updateFilter(filter: CIFilterNames[index])
        let inputCIImage = CIImage(image: OriginalPostImageForFiltering!)
        if CIFilterNames[indexPath.row] == "Default" {
            self.cameraPhotoResult!.image = OriginalPostImageForFiltering
        } else {
            let filter = CIFilter(name: CIFilterNames[indexPath.row])
            filter?.setValue(inputCIImage, forKey: kCIInputImageKey)
            let cgImage = CIContext().createCGImage(filter!.outputImage!, from: (inputCIImage!.extent))!
            if devicePosition == .front {
                self.cameraPhotoResult!.image =  UIImage(cgImage: cgImage).withHorizontallyFlippedOrientation()
            } else {
                self.cameraPhotoResult!.image =  UIImage(cgImage: cgImage)
            }
        }
        
        
        self.filterImageCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 60)
    }
    @objc func doubleTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
        // do something here
        NextLevel.shared.flipCaptureDevicePosition()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if NextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
           NextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
            do {
                try NextLevel.shared.start()
                NextLevel.shared.flashMode = .auto
                print("* next LEVEL flash avail: \(NextLevel.shared.isFlashAvailable)")
                print("* next LEVEL flash mode: \(NextLevel.shared.flashMode)")
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else {
            NextLevel.requestAuthorization(forMediaType: AVMediaType.video) { (mediaType, status) in
                print("NextLevel, authorization updated for media \(mediaType) status \(status)")
                if NextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
                    NextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                    do {
                        let nextLevel = NextLevel.shared
                        try nextLevel.start()
                    } catch {
                        print("NextLevel, failed to start camera session")
                    }
                } else if status == .notAuthorized {
                    // gracefully handle when audio/video is not authorized
                    print("NextLevel doesn't have authorization for audio or video")
                }
            }
            NextLevel.requestAuthorization(forMediaType: AVMediaType.audio) { (mediaType, status) in
                print("NextLevel, authorization updated for media \(mediaType) status \(status)")
                if NextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
                    NextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                    do {
                        let nextLevel = NextLevel.shared
                        try nextLevel.start()
                    } catch {
                        print("NextLevel, failed to start camera session")
                    }
                } else if status == .notAuthorized {
                    // gracefully handle when audio/video is not authorized
                    print("NextLevel doesn't have authorization for audio or video")
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NextLevel.shared.stop()
    }

}

// MARK: - library
extension CameraViewController {

    internal func albumAssetCollection(withTitle title: String) -> PHAssetCollection? {
        let predicate = NSPredicate(format: "localizedTitle = %@", title)
        let options = PHFetchOptions()
        options.predicate = predicate
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        if result.count > 0 {
            return result.firstObject
        }
        return nil
    }

}
extension CameraViewController : CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("location:: (location)")
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error:: (error)")
    }
}
// MARK: - capture
extension CameraViewController {

    internal func startCapture() {
        self.photoTapGestureRecognizer?.isEnabled = false
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.recordButton?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { (_: Bool) in
        }
        NextLevel.shared.record()
    }

    internal func pauseCapture() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.recordButton?.transform = .identity
        }) { (_: Bool) in
            NextLevel.shared.pause()
        }
    }

    internal func endCapture() {
        self.photoTapGestureRecognizer?.isEnabled = true

        if let session = NextLevel.shared.session {

            if session.clips.count > 1 {
//                AVAssetExportPresetHighestQuality
                session.mergeClips(usingPreset: AVAssetExportPresetMediumQuality, completionHandler: { (url: URL?, error: Error?) in
                    if let url = url {
                        self.saveVideo(withURL: url)
                    } else if let _ = error {
                        print("failed to merge clips at the end of capture \(String(describing: error))")
                    }
                })
            } else if let lastClipUrl = session.lastClipUrl {
                self.saveVideo(withURL: lastClipUrl)
            } else if session.currentClipHasStarted {
                session.endClip(completionHandler: { (clip, error) in
                    if error == nil, let url = clip?.url {
                        self.saveVideo(withURL: url)
                    } else {
                        print("Error saving video: \(error?.localizedDescription ?? "")")
                    }
                })
            } else {
                // prompt that the video has been saved
                let alertController = UIAlertController(title: "Video Capture", message: "Not enough video captured!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }

        }

    }

    internal func authorizePhotoLibaryIfNecessary() {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch authorizationStatus {
        case .restricted:
            fallthrough
        case .denied:
            let alertController = UIAlertController(title: "Error accessing Photo Library", message: "Access denied. Make sure you have given access to your photo library.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {

                } else {

                }
            })
            break
        case .authorized:
            break
        case .limited:
            break
        @unknown default:
            fatalError("unknown authorization type")
        }
    }

}

// MARK: - media utilities
extension CameraViewController {

    internal func saveVideo(withURL url: URL) {
        PHPhotoLibrary.shared().performChanges({
            let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle)
            if albumAssetCollection == nil {
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle)
                _ = changeRequest.placeholderForCreatedAssetCollection
            }}, completionHandler: { (_: Bool, _: Error?) in
                if let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle) {
                    PHPhotoLibrary.shared().performChanges({
                        if let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) {
                            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                            let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                            assetCollectionChangeRequest?.addAssets(enumeration)
                        }
                    }, completionHandler: { (success2: Bool, _: Error?) in
                    if success2 == true {
                        // prompt that the video has been saved
                        let alertController = UIAlertController(title: "Video Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        // prompt that the video has been saved
                        let alertController = UIAlertController(title: "Oops!", message: "Something failed!", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                })
            }
        })
    }

    internal func savePhoto(photoImage: UIImage) {

        PHPhotoLibrary.shared().performChanges({

            let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle)
            if albumAssetCollection == nil {
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle)
                _ = changeRequest.placeholderForCreatedAssetCollection
            }

        }, completionHandler: { (success1: Bool, error1: Error?) in

            if success1 == true {
                if let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle) {
                    PHPhotoLibrary.shared().performChanges({
                        let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photoImage)
                        let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                        let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                        assetCollectionChangeRequest?.addAssets(enumeration)
                    }, completionHandler: { (success2: Bool, _: Error?) in
                        if success2 == true {
                            let alertController = UIAlertController(title: "Photo Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                    })
                }
            } else if let _ = error1 {
                print("failure capturing photo from video frame \(String(describing: error1))")
            }

        })
    }
    func hideAllPhotoComponents() {
        DispatchQueue.main.async {
            NextLevel.shared.stop()
            self.previewView?.fadeOut()
            self.flashButton?.fadeOut()
            self.snapPicButton?.fadeOut()
            self.menubarUIView?.fadeOut()
            self.closeButton?.fadeOut()
            
//            self.cameraPhotoResult?.fadeIn()
        }
        
    }
    func showAllPhotoComponents() {
        DispatchQueue.main.async {
            try? NextLevel.shared.start()
            self.previewView?.fadeIn()
            self.snapPicButton?.fadeIn()
            self.menubarUIView?.fadeIn()
            self.closeButton?.fadeIn()
            self.flashButton?.fadeIn()
            
//            self.cameraPhotoResult?.fadeIn()
        }
    }
    func showStoryPostComponents() {
        let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))

        //PhotoEditorDelegate
        photoEditor.photoEditorDelegate = self

        //The image to be edited
        photoEditor.image = self.cameraPhotoResult!.image

        //Stickers that the user will choose from to add on the image
//            photoEditor.stickers.append(UIImage(named: "sticker" )!)

        //Optional: To hide controls - array of enum control
        photoEditor.hiddenControls = [.crop, .share]

        //Optional: Colors for drawing and Text, If not set default values will be used
        photoEditor.colors = [.red,.blue,.green]

        //Present the View Controller
        self.present(photoEditor, animated: false, completion: nil)
    }
    func showPhotoPostComponents() {
        DispatchQueue.main.async {
            self.cameraPhotoResult?.alpha = 1
            self.cameraPhotoResult?.contentMode = .scaleAspectFill
            self.view.addSubview(self.cameraPhotoResult!)
            self.view?.sendSubviewToBack(self.cameraPhotoResult!)
            self.goBackButton?.alpha = 0
            self.nextButton?.alpha = 0
            self.nextButton!.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 53 - 40, width: UIScreen.main.bounds.width - 80, height: 53)
            self.view.addSubview(self.goBackButton!)
            self.view.addSubview(self.nextButton!)
            self.goBackButton?.fadeIn()
            self.nextButton?.fadeIn()
            self.stepNameLabel?.alpha = 0
            self.view.addSubview(self.stepNameLabel!)
            self.stepNameLabel?.fadeIn()
            let filterHeight = UIScreen.main.bounds.height - self.cameraPhotoResult!.frame.maxY - self.nextButton!.frame.height - 80
            self.filterImageCollectionView.frame = CGRect(x: 0, y: self.cameraPhotoResult!.frame.maxY+10, width: UIScreen.main.bounds.width, height: filterHeight)
            self.filterImageCollectionView.reloadData()
            self.filterImageCollectionView.fadeIn()
//            let captionHeight = UIScreen.main.bounds.height - self.cameraPhotoResult!.frame.maxY - self.actualPostButton!.frame.height - 20
//            self.captionView?.frame = CGRect(x: 20, y: self.cameraPhotoResult!.frame.maxY+10, width: UIScreen.main.bounds.width - 40, height: captionHeight)
//            captionView!.font = UIFont(name: Constants.globalFont, size: 14)
//            self.captionView?.fadeIn()
            
            
            
            
//            UIView.animate(withDuration: 0.3, animations: { [self] in
//                    self.view.layoutIfNeeded() // add this
//                self.cameraPhotoResult?.frame = CGRect(x: (self.previewView?.frame.minX)!, y: 40, width: UIScreen.main.bounds.width, height: (self.previewView?.frame.height)!)
//
//
//                }) { (success) in
//                    self.view.layoutIfNeeded()
//                    self.goBackButton?.fadeIn()
//                    self.nextButton?.fadeIn()
//                }
        }
    }
}

// MARK: - UIButton
extension CameraViewController {

    @objc internal func handleFlipButton(_ button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
        NextLevel.shared.flipCaptureDevicePosition()
    }
    @objc internal func handleCloseButton(_ button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    @objc internal func handleBackbutton(_ button: UIButton) {
        let stepName = stepNameLabel?.text as! String
        let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
        let dif = 15
        
        AddLocationTextField?.frame = CGRect(x: Int((addLocationIcon?.frame.maxX)! + CGFloat(dif)), y: dif, width: Int((AddLocationView?.frame.width)! - (addLocationIcon?.frame.maxY)!) - 10, height: 50-dif*2)
        self.distanceAway!.text = ""
        
        if stepName == "Choose Filter" {
            deleteGif()
            UIView.animate(withDuration: 0.3, animations: { [self] in
                self.view.layoutIfNeeded()
                cameraPhotoResult?.alpha = 0
                goBackButton!.alpha = 0
                nextButton!.alpha = 0
                stepNameLabel!.alpha = 0
                AddPeopleView?.alpha = 0
                AddLocationView?.alpha = 0
                AddTagsView?.alpha = 0
                self.filterImageCollectionView.alpha = 0
            }) { (success) in
                self.view.layoutIfNeeded()
                self.cameraPhotoResult?.removeFromSuperview()
                self.goBackButton?.removeFromSuperview()
                self.nextButton?.removeFromSuperview()
                self.stepNameLabel?.removeFromSuperview()
                do {
                    try NextLevel.shared.start()
                } catch {
                    print("NextLevel, failed to start camera session")
                }
                DispatchQueue.main.async {
                    
                    self.previewView?.fadeIn()
                    self.snapPicButton?.fadeIn()
                    self.menubarUIView?.fadeIn()
                    self.closeButton?.fadeIn()
                    
        //            self.cameraPhotoResult?.fadeIn()
                }
            }
        } else if stepName == "New Post" {
//            hidePostDetailsOptions()
            UIView.animate(withDuration: 0.3, animations: { [self] in
                self.view.layoutIfNeeded()
                actualPostButton?.alpha = 0
                goBackButton?.alpha = 0
                cameraPhotoResult?.alpha = 0
                captionView?.alpha = 0
                stepNameLabel?.alpha = 0
                AddPeopleView?.alpha = 0
                AddLocationView?.alpha = 0
                AddTagsView?.alpha = 0
                numOfImageLabel?.alpha = 0
            }) { [self] (success) in
                self.view.layoutIfNeeded()
                self.numOfImageLabel?.removeFromSuperview()
                self.showAllPhotoComponents()
            }
           
            
        }
    }
    func getNearbyPlaces() {
        
    }
    @objc internal func handleSaveButton(_ button: UIButton) {
        self.endCapture()
    }
    func showPostDetailOptions() {
        
        
        //                self.stepNameLabel?.text = "Edit Photo"
        //                self.stepNameLabel?.fadeIn()
        //                self.nextButton?.fadeIn()
//        self.actualPostButton?.frame = self.nextButton!.frame
        self.actualPostButton?.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 53 - 40, width: UIScreen.main.bounds.width - 80, height: 53)
        self.actualPostButton?.fadeIn()
        let previewWidth = 100
        self.goBackButton?.fadeIn()
        self.cameraPhotoResult?.layer.cornerRadius = 4
        self.cameraPhotoResult?.frame = CGRect(x: self.goBackButton?.frame.minX ?? 0, y: (self.goBackButton?.frame.maxY)! + 40, width: CGFloat(previewWidth), height: CGFloat(previewWidth)*1.25)
        self.cameraPhotoResult?.fadeIn()
        self.captionView?.frame = CGRect(x: (self.cameraPhotoResult?.frame.maxX)! + 10, y: self.cameraPhotoResult?.frame.minY ?? 0, width: UIScreen.main.bounds.width - (self.cameraPhotoResult?.frame.width)! - 30 - 20, height: CGFloat(previewWidth)*1.25)
        self.captionView?.text = "Enter a caption"
        self.captionView?.layer.cornerRadius = 4
        self.stepNameLabel?.text = "New Post"
        self.captionView!.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.captionView!.textColor = UIColor.lightGray
        self.captionView?.font = UIFont(name: Constants.globalFont, size: 13)
        
        self.stepNameLabel?.fadeIn()
        self.hideKeyboardWhenTappedAround()
        self.captionView?.fadeIn()
        
        
        
        
        
        AddPeopleView?.frame = CGRect(x: (cameraPhotoResult?.frame.minX)!, y: cameraPhotoResult!.frame.maxY + 40, width: UIScreen.main.bounds.width - (cameraPhotoResult!.frame.minX * 2), height: 50)
        AddLocationView?.frame = CGRect(x: (cameraPhotoResult?.frame.minX)!, y: AddPeopleView!.frame.maxY + 10, width: UIScreen.main.bounds.width - (cameraPhotoResult!.frame.minX * 2), height: 50)
        AddTagsView?.frame = CGRect(x: (cameraPhotoResult?.frame.minX)!, y: AddLocationView!.frame.maxY + 10, width: UIScreen.main.bounds.width - (cameraPhotoResult!.frame.minX * 2), height: 50)
        
        let dif = 15
        
        addPeopleIcon?.frame = CGRect(x: dif, y: dif, width: 50 - dif*2, height: 50-dif*2)
        let tmpx = Int(Float16((Int((AddPeopleView?.frame.width)!) ) - (50-dif*2) - dif) )
        rightArrowPeople?.frame = CGRect(x: tmpx, y: dif, width: 50-dif*2, height: 50-dif*2)
        rightArrowPeople?.backgroundColor = .clear
        AddPeopleTextField?.frame = CGRect(x: Int((addPeopleIcon?.frame.maxX)! + CGFloat(dif)), y: dif, width: Int((AddPeopleView?.frame.width)! - (addPeopleIcon?.frame.maxY)!) - 10, height: 50-dif*2)
        AddPeopleView?.fadeIn()
        
        addTagsIcon?.frame = CGRect(x: dif, y: dif, width: 50 - dif*2, height: 50-dif*2)
        AddTagsTextField?.frame = CGRect(x: Int((addTagsIcon?.frame.maxX)! + CGFloat(dif)), y: dif, width: Int((AddTagsView?.frame.width)! - (addTagsIcon?.frame.maxY)!) - 10, height: 50-dif*2)
        AddTagsView?.fadeIn()
        
        addLocationIcon?.frame = CGRect(x: dif, y: dif, width: 50 - dif*2, height: 50-dif*2)
        AddLocationTextField?.frame = CGRect(x: Int((addLocationIcon?.frame.maxX)! + CGFloat(dif)), y: dif, width: Int((AddLocationView?.frame.width)! - (addLocationIcon?.frame.maxY)!) - 10, height: 50-dif*2)
        distanceAway?.frame = CGRect(x: AddLocationTextField?.frame.minX ?? 0, y: 30, width: CGFloat(Int((AddLocationView?.frame.width)! - (addLocationIcon?.frame.maxY)!)) - 10, height: 10)
        AddLocationView?.fadeIn()
    }
    func hidePostDetailsOptions() {
        UIView.animate(withDuration: 0.3, animations: { [self] in
            self.view.layoutIfNeeded()
            actualPostButton?.alpha = 0
            goBackButton?.alpha = 0
            cameraPhotoResult?.alpha = 0
            captionView?.alpha = 0
            stepNameLabel?.alpha = 0
            AddPeopleView?.alpha = 0
            AddLocationView?.alpha = 0
            AddTagsView?.alpha = 0
            
        }) { [self] (success) in
            self.view.layoutIfNeeded()
            stepNameLabel?.text = "Choose Filter"
            cameraPhotoResult?.frame = previewView!.frame
            filterImageCollectionView.fadeIn()
            nextButton?.fadeIn()
            goBackButton?.fadeIn()
            cameraPhotoResult?.fadeIn()
            stepNameLabel?.fadeIn()
            
            
        }
            
    }
    func checkForSFW(isAdult: String, isMedical: String, isRacy: String, isViolent: String) -> Bool {
        let checkForAdult = (isAdult == "LIKELY" || isAdult == "VERY_LIKELY") == false
        let checkForMedical = (isMedical == "LIKELY" || isMedical == "VERY_LIKELY") == false
        let checkForViolence = (isViolent == "LIKELY" || isViolent == "VERY_LIKELY") == false
        
        return checkForAdult && checkForMedical && checkForViolence
    }
    func disableInteraction() {
        captionView?.isUserInteractionEnabled = false
        AddTagsView?.isUserInteractionEnabled = false
        AddLocationView?.isUserInteractionEnabled = false
        goBackButton?.isUserInteractionEnabled = false
        AddPeopleView?.isUserInteractionEnabled = false
    }
    func uploadSinglePostPhoto() {
        let userID : String = (Auth.auth().currentUser?.uid)!
        uploadPostMedia() { url, locationUID in
            guard let url = url else { return }
            guard let locationUID = locationUID else {
                return
            }
//            actualPostButton?.update(percent: snapshot.progress)
            self.actualPostButton?.stopLoading()
            self.actualPostButton?.setTitle("One moment...", for: .normal)
            self.actualPostButton?.backgroundColor = self.hexStringToUIColor(hex: Constants.secondaryColor)
            self.actualPostButton?.titleLabel?.textColor = self.hexStringToUIColor(hex: Constants.primaryColor)
            self.actualPostButton?.tintColor = self.hexStringToUIColor(hex: Constants.primaryColor)
            
            let timestamp = NSDate().timeIntervalSince1970
            let ref = self.db.collection("posts").document(userID).collection("posts").document()
            let documentId = ref.documentID
            let imageHash = self.cameraPhotoResult?.image?.blurHash(numberOfComponents: (3, 2))
            
            
            
            self.actualPostButton?.setTitle("Finishing up...", for: .normal)
            print("* calculated image hash: \(imageHash)")
            ref.setData([
                "caption"      : (self.captionView?.text ?? "").replacingOccurrences(of: "Enter a caption", with: ""),
                "tags"    : [],
                "authorID"     : userID,
                "createdAt": Int(timestamp),
                "location"       : self.AddLocationTextField?.text ?? "",
                "imageHash": (imageHash ?? "") as! String,
                "postImageUrl" : url,
                "likes_count": 0,
                "comments_count": 0,
                "storage_ref": "post_photos/\(userID)/\(locationUID)",
                "likes": [],
                "ext_likes": [],
                "fromCameraRoll": self.uploadedFromCameraRoll
            ]) { err in
                print("* uploading post with image url: \(url)")
                Analytics.logEvent("uploaded_post", parameters: [
                    "postAuthor": userID, "image_count":1
                ])
                self.actualPostButton?.setTitle("Done!", for: .normal)
                
//                let userID = Auth.auth().currentUser?.uid
//                let followersRef = self.db.collection("followers")
                
//                if let navController = self.navigationController, navController.viewControllers.count >= 2 {
//                    let viewController = navController.viewControllers[navController.viewControllers.count - 2]
//                    print("* got parent viewcontroller: \(viewController)")
//                    viewController.tabBarController?.selectedIndex = 0
//                    let feed = viewController as? FeedViewController
//                    feed?.imagePosts?.removeAll()
//                    feed?.documents.removeAll()
//                    feed?.query = followersRef.whereField("followers", arrayContains: userID!).order(by: "last_post", descending: true).limit(to: 3)
//
//                    feed?.postsTableView.reloadData()
//                    feed?.getPosts()
//                }
                UIApplication.shared.refreshFeed()
                self.dismiss(animated: true)
            }
            
            
            
            
        }
    }
    @objc internal func handlePostButton(_ button: UIButton) {
        print("* posting photo")
        let userID : String = (Auth.auth().currentUser?.uid)!
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        actualPostButton?.isUserInteractionEnabled = false
        actualPostButton?.setAnimation(LoadyAnimationType.backgroundHighlighter())
        actualPostButton?.backgroundColor = hexStringToUIColor(hex: Constants.secondaryColor)
        actualPostButton?.backgroundFillColor = hexStringToUIColor(hex: Constants.primaryColor)
        // starts loading animation
        actualPostButton?.startLoading()
        var postimageUrls: [String] = []
        var refs: [String] = []
        var locationUIDz = ""
        var firstImageURL = ""
        self.actualPostButton?.setTitle("Uploading", for: .normal)
        if postPhotos.count == 0 {
            uploadSinglePostPhoto()
        } else {
            print("* multiple photos, uploading asynchronously")
            let mainDispatchGroup = DispatchGroup()
            var i = 0
            var completed = 0
            
            for post in postPhotos {
                let postz = post.nx_croppedImage(to: 1.25)
                mainDispatchGroup.enter()
                let tmp = i
                uploadPic(image: postz) { url, locationUID in
                    guard let url = url else { return }
                    guard let locationUID = locationUID else {
                        return
                    }
                    if tmp == 0 {
                        locationUIDz = locationUID
                        firstImageURL = url
                    }
                    if tmp > refs.count {
                        refs.append(locationUID)
                    } else {
                        refs.insert(locationUID, at: tmp)
                    }
                    
                    if tmp > postimageUrls.count {
                        postimageUrls.append(url)
                    } else {
                        postimageUrls.insert(url, at: tmp)
                    }
                    completed = completed + 1
                    let percentComplete = 100.0 * Double(completed) / Double(self.postPhotos.count)
                    print("* uploading: \(percentComplete)")
                    self.actualPostButton?.update(percent: percentComplete)
                    
                    mainDispatchGroup.leave()
                }
                i = i + 1
            }
            mainDispatchGroup.notify(queue: .main) {
                self.actualPostButton?.setTitle("Finishing up...", for: .normal)
                let timestamp = NSDate().timeIntervalSince1970
                let ref = self.db.collection("posts").document(userID).collection("posts").document()
                let documentId = ref.documentID
                let imageHash = self.postPhotos[0].blurHash(numberOfComponents: (3, 2))
                print("* calculated image hash: \(imageHash)")
                print("* posting with images \(postimageUrls)")
                ref.setData([
                    "caption"      : (self.captionView?.text ?? "").replacingOccurrences(of: "Enter a caption", with: ""),
                    "tags"    : [],
                    "authorID"     : userID,
                    "createdAt": Int(timestamp),
                    "location"       : self.AddLocationTextField?.text ?? "",
                    "imageHash": (imageHash ?? "") as! String,
                    "postImageUrl" : firstImageURL,
                    "likes_count": 0,
                    "comments_count": 0,
                    "storage_ref": "post_photos/\(userID)/\(locationUIDz)",
                    "likes": [],
                    "ext_likes": [],
                    "fromCameraRoll": self.uploadedFromCameraRoll,
                    "images": postimageUrls,
                    "storage_refs": refs
                ]) { err in
                    print("* done pushing post!")
                    Analytics.logEvent("uploaded_post", parameters: [
                        "postAuthor": userID, "image_count": self.postPhotos.count
                    ])
                    self.actualPostButton?.setTitle("Done!", for: .normal)
                    UIApplication.shared.refreshFeed()
                    self.dismiss(animated: true)
                }
                
            }
        }
    }
    @objc internal func handlePostButtonAndScanAI(_ button: UIButton)
    {
        print("* posting photo")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        actualPostButton?.isUserInteractionEnabled = false
        actualPostButton?.setAnimation(LoadyAnimationType.backgroundHighlighter())
        actualPostButton?.backgroundColor = hexStringToUIColor(hex: Constants.secondaryColor)
        actualPostButton?.backgroundFillColor = hexStringToUIColor(hex: Constants.primaryColor)
        // starts loading animation
        actualPostButton?.startLoading()
        self.actualPostButton?.setTitle("Uploading", for: .normal)
        let userID : String = (Auth.auth().currentUser?.uid)!
        uploadPostMedia() { url, locationUID in
            guard let url = url else { return }
            guard let locationUID = locationUID else {
                return
            }
//            actualPostButton?.update(percent: snapshot.progress)
            self.actualPostButton?.stopLoading()
            self.actualPostButton?.setTitle("One moment...", for: .normal)
            self.actualPostButton?.backgroundColor = self.hexStringToUIColor(hex: Constants.secondaryColor)
            self.actualPostButton?.titleLabel?.textColor = self.hexStringToUIColor(hex: Constants.primaryColor)
            self.actualPostButton?.tintColor = self.hexStringToUIColor(hex: Constants.primaryColor)
            self.db.collection("image-ai-results").document(locationUID).addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("* error occured in getting ai results")
                } else {
                    
                    if (documentSnapshot?.exists)! {
                        print("* detected vision data has been updated, parsing")
                        let data = documentSnapshot?.data()
                        print("* got data from vision: \(data)")
                        let isAdult = data?["adult"] as? String ?? ""
                        let isMedical = data?["medical"] as? String ?? ""
                        let isRacy = data?["racy"] as? String ?? ""
                        let isViolent = data?["violence"] as? String ?? ""
                        let sfwResult = self.checkForSFW(isAdult: isAdult, isMedical: isMedical, isRacy: isRacy, isViolent: isViolent)
                        print("* result from SFW search [true/false] for SAFE: \(sfwResult)")
                        if sfwResult == true {
                            let timestamp = NSDate().timeIntervalSince1970
                            let ref = self.db.collection("posts").document(userID).collection("posts").document()
                            let documentId = ref.documentID
                            let imageHash = self.cameraPhotoResult?.image?.blurHash(numberOfComponents: (3, 2))
                            
                            
                            
                            self.actualPostButton?.setTitle("Finishing up...", for: .normal)
                            print("* calculated image hash: \(imageHash)")
                            ref.setData([
                                "caption"      : (self.captionView?.text ?? "").replacingOccurrences(of: "Enter a caption", with: ""),
                                "tags"    : [],
                                "authorID"     : userID,
                                "createdAt": Int(timestamp),
                                "location"       : self.AddLocationTextField?.text ?? "",
                                "imageHash": (imageHash ?? "") as! String,
                                "postImageUrl" : url,
                                "likes_count": 0,
                                "fromCameraRoll": self.uploadedFromCameraRoll
                            ]) { err in
                                self.db.collection("followers").document(userID).updateData(["last_post":["id":documentId,"createdAt":timestamp]])
                                print("* uploading post with image url: \(url)")
                                self.actualPostButton?.setTitle("Done!", for: .normal)
                                
                                let userID = Auth.auth().currentUser?.uid
                                let followersRef = self.db.collection("followers")
                                
                                self.db.collection("image-ai-results").document(locationUID).delete()
                                if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                                     let viewController = navController.viewControllers[navController.viewControllers.count - 2]
                                    print("* got parent viewcontroller: \(viewController)")
                                    viewController.tabBarController?.selectedIndex = 0
                                    let feed = viewController as? FeedViewController
                                    feed?.imagePosts?.removeAll()
                                    feed?.documents.removeAll()
                                    feed?.query = followersRef.whereField("followers", arrayContains: userID!).order(by: "last_post", descending: true).limit(to: 3)
                                    
                                    feed?.postsTableView.reloadData()
                                    feed?.getPosts()
                                }
                                self.dismiss(animated: true)
                            }
                            
                        } else {
                            print("* USER UPLOADED NSFW IMAGE")
                        }
                    } else {
                        print("* waiting for VISION api data..")
                    }
                    
                }
            }
            
        }
    }
    @objc internal func handleNextButton(_ button: UIButton) {
        if stepNameLabel!.text == "Choose Filter" {
            UIView.animate(withDuration: 0.3, animations: { [self] in
                self.view.layoutIfNeeded()
                filterImageCollectionView.alpha = 0
                nextButton?.alpha = 0
                goBackButton?.alpha = 0
                cameraPhotoResult?.alpha = 0
                stepNameLabel?.alpha = 0
            }) { [self] (success) in
                self.view.layoutIfNeeded()
                showPostDetailOptions() //show caption field, location, tag people etc
            }
            
        } else if stepNameLabel!.text == "Edit Photo" {
            
        }
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension CameraViewController: UIGestureRecognizerDelegate {
    
    @objc internal func handleLongPressGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.startCapture()
            self._panStartPoint = gestureRecognizer.location(in: self.view)
            self._panStartZoom = CGFloat(NextLevel.shared.videoZoomFactor)
            break
        case .changed:
            let newPoint = gestureRecognizer.location(in: self.view)
            let scale = (self._panStartPoint.y / newPoint.y)
            let newZoom = (scale * self._panStartZoom)
            NextLevel.shared.videoZoomFactor = Float(newZoom)
            break
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            self.pauseCapture()
            fallthrough
        default:
            break
        }
    }
    @objc internal func handleDragDown(_ sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.3

                // convert y-position to downward pull progress (percentage)
                let translation = sender.translation(in: view)
                let verticalMovement = translation.y / view.bounds.height
                let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
                let downwardMovementPercent = fminf(downwardMovement, 1.0)
                let progress = CGFloat(downwardMovementPercent)
                
                guard let interactor = interactor else { return }
                
                switch sender.state {
                case .began:
                    interactor.hasStarted = true
                    dismiss(animated: true, completion: nil)
                case .changed:
                    interactor.shouldFinish = progress > percentThreshold
                    interactor.update(progress)
                case .cancelled:
                    interactor.hasStarted = false
                    interactor.cancel()
                case .ended:
                    interactor.hasStarted = false
                    interactor.shouldFinish
                        ? interactor.finish()
                        : interactor.cancel()
                default:
                    break
                }
    }
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {

                switch pinch.state {
                case .began:
                    initialScale = CGFloat(NextLevel.shared.videoZoomFactor)
                case .changed:
                    let minAvailableZoomScale = CGFloat(1)
                    let maxAvailableZoomScale = CGFloat(10)
                    let availableZoomScaleRange = minAvailableZoomScale...maxAvailableZoomScale
                    let resolvedZoomScaleRange = zoomScaleRange.clamped(to: availableZoomScaleRange)

                    let resolvedScale = max(resolvedZoomScaleRange.lowerBound, min(pinch.scale * initialScale, resolvedZoomScaleRange.upperBound))
                    NextLevel.shared.videoZoomFactor = Float(resolvedScale)
                default:
                    return
                }
    }
}

extension CameraViewController {

    @objc internal func handlePhotoTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // play system camera shutter sound
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil)
        NextLevel.shared.capturePhotoFromVideo()
    }

    @objc internal func handleFocusTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: self.previewView)

        if let focusView = self.focusView {
            var focusFrame = focusView.frame
            focusFrame.origin.x = CGFloat((tapPoint.x - (focusFrame.size.width * 0.5)).rounded())
            focusFrame.origin.y = CGFloat((tapPoint.y - (focusFrame.size.height * 0.5)).rounded())
            focusView.frame = focusFrame

            self.previewView?.addSubview(focusView)
            focusView.startAnimation()
        }

        let adjustedPoint = NextLevel.shared.previewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
        NextLevel.shared.focusExposeAndAdjustWhiteBalance(atAdjustedPoint: adjustedPoint)
    }

}

// MARK: - NextLevelDelegate
extension CameraViewController: NextLevelDelegate {
    // permission
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: AVMediaType) {
    }

    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
    }

    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
    }

    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionWillStart")
    }

    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStart")
    }

    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStop")
    }

    // interruption
    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
    }

    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
    }

    // mode
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }

    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }

}

extension CameraViewController: NextLevelPreviewDelegate {

    // preview
    func nextLevelWillStartPreview(_ nextLevel: NextLevel) {
    }

    func nextLevelDidStopPreview(_ nextLevel: NextLevel) {
    }

}

extension CameraViewController: NextLevelDeviceDelegate {

    // position, orientation
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel) {
    }

    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel) {
    }

    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation) {
    }

    // format
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceFormat deviceFormat: AVCaptureDevice.Format) {
    }

    // aperture
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect) {
    }

    // lens
    func nextLevel(_ nextLevel: NextLevel, didChangeLensPosition lensPosition: Float) {
    }

    // focus, exposure, white balance
    func nextLevelWillStartFocus(_ nextLevel: NextLevel) {
    }

    func nextLevelDidStopFocus(_  nextLevel: NextLevel) {
        if let focusView = self.focusView {
            if focusView.superview != nil {
                focusView.stopAnimation()
            }
        }
    }

    func nextLevelWillChangeExposure(_ nextLevel: NextLevel) {
    }

    func nextLevelDidChangeExposure(_ nextLevel: NextLevel) {
        if let focusView = self.focusView {
            if focusView.superview != nil {
                focusView.stopAnimation()
            }
        }
    }

    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel) {
    }

    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel) {
    }

}

// MARK: - NextLevelFlashDelegate
extension CameraViewController: NextLevelFlashAndTorchDelegate {

    func nextLevelDidChangeFlashMode(_ nextLevel: NextLevel) {
    }

    func nextLevelDidChangeTorchMode(_ nextLevel: NextLevel) {
    }

    func nextLevelFlashActiveChanged(_ nextLevel: NextLevel) {
    }

    func nextLevelTorchActiveChanged(_ nextLevel: NextLevel) {
    }

    func nextLevelFlashAndTorchAvailabilityChanged(_ nextLevel: NextLevel) {
    }

}

// MARK: - NextLevelVideoDelegate
extension CameraViewController: NextLevelVideoDelegate, PhotoEditorDelegate {

    // video zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }

    // video frame processing
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
    }

    func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, timestamp: TimeInterval, onQueue queue: DispatchQueue) {
    }

    // enabled by isCustomContextVideoRenderingEnabled
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
    }

    // video recording session
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }

    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        // called when a configuration time limit is specified
        self.endCapture()
    }
    // MARK: single post image captured from camera
    // video frame photo
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String: Any]?) {
        print("* DID COMPLETE PHOTO CAPTURE")
        if let dictionary = photoDict,
            let photoData = dictionary[NextLevelPhotoJPEGKey] as? Data,
            let photoImage = UIImage(data: photoData) {
//            self.savePhoto(photoImage: photoImage)
            if nextLevel.devicePosition == .front {
                cameraPhotoResult = UIImageView(image: photoImage.withHorizontallyFlippedOrientation())
                OriginalPostImageForFiltering = photoImage.withHorizontallyFlippedOrientation()
                devicePosition = .front
            } else {
                cameraPhotoResult = UIImageView(image: photoImage)
                devicePosition = .back
                OriginalPostImageForFiltering = photoImage
            }
            cameraPhotoResult?.frame = previewView!.frame
            cameraPhotoResult?.layer.cornerRadius = (self.previewView?.layer.cornerRadius)!
            cameraPhotoResult?.clipsToBounds = true
            uploadedFromCameraRoll = false
//            hideAllPhotoComponents()
            if postType == "post" {
//                showPhotoPostComponents()
                // create controller for brightroom
                // Create an image provider
//                let imageProvider = ImageProvider(image: OriginalPostImageForFiltering!) // URL, Data are also supported.
//
//                let stack = EditingStack.init(
//                  imageProvider: imageProvider
//                )
//
//                self._present(stack, square: false)
//                showEditImageVC
                OriginalPostImageForFiltering = OriginalPostImageForFiltering?.nx_croppedImage(to: 1.25).withHorizontallyFlippedOrientation()
                let vc = ZLEditImageViewController(image: OriginalPostImageForFiltering!)
                vc.editFinishBlock = { ei, editImageModel in
//                    completion?(ei, editImageModel)
                    print("* GOT image!")
                    
                    self.cameraPhotoResult?.image = ei
                    self.cameraPhotoResult?.contentMode = .scaleAspectFill
                    self.view.addSubview(self.cameraPhotoResult!)
                    self.view?.sendSubviewToBack(self.cameraPhotoResult!)
                    self.view.addSubview(self.goBackButton!)
                    self.view.addSubview(self.stepNameLabel!)
                    self.hideAllPhotoComponents()
                    self.showPostDetailOptions()
                }
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false, completion: nil)
            } else if postType == "story" {
//                let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))
//
//                //PhotoEditorDelegate
//                photoEditor.photoEditorDelegate = self
//
//                //The image to be edited
//                photoEditor.image = OriginalPostImageForFiltering
//
//                //Optional: To hide controls - array of enum control
//                photoEditor.hiddenControls = [.crop, .share, .sticker]
//
//                //Optional: Colors for drawing and Text, If not set default values will be used
////                photoEditor.colors = [.red,.blue,.green]
//
//                //Present the View Controller
//                present(photoEditor, animated: false, completion: nil)
                let vc = ZLEditImageViewController(image: OriginalPostImageForFiltering!)
                vc.editFinishBlock = { ei, editImageModel in
//                    completion?(ei, editImageModel)
                    print("* GOT image!")
                    self.hideAllPhotoComponents()
                    self.doneEditing(image: ei)
                }
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false, completion: nil)
            }
            
        }
    }
    func doneEditing(image: UIImage) {
        // the edited image
        print("* posting story")
        let userID : String = (Auth.auth().currentUser?.uid)!
        let randomString = randomString(length: 20)
        let storageRef = Storage.storage().reference().child("stories/\(userID)/\(randomString)")
        
        guard let imageData = image.nx_croppedImage(to: 1.7).jpegData(compressionQuality: 0.75) else { return }
        print("* cropped image")
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        let uploadTask = storageRef.putData(imageData, metadata: metaData) { metaData, error in
            if error == nil, metaData != nil {
                
                storageRef.downloadURL { url, error in
                    // success!
                    print("* success uploading image!")
                    let ref = self.db.collection("stories").document(userID).collection("stories").document()
                    let documentId = ref.documentID
                    print("* developed document id: \(documentId)")
//                    let imageHash = image.blurHash(numberOfComponents: (1, 2))
                    let imageHash = ""
                
                    print("* calculated image hash: \(imageHash)")
                    let timestamp = NSDate().timeIntervalSince1970
                    ref.setData([
                        "tags"    : [],
                        "authorID"     : userID,
                        "createdAt": Int(timestamp),
                        "imageHash": (imageHash ?? "") as! String,
                        "storyImageUrl" : url?.absoluteString as! String,
                        "fromCameraRoll": self.uploadedFromCameraRoll
                    ])
                    Analytics.logEvent("uploaded_story", parameters: [
                      "postAuthor": userID,
                    ])
                    self.dismiss(animated: true)
                }
            } else {
                // failed
                print("* error uploading photos")
            }
        }
    }
        
    func canceledEditing() {
        print("Canceled")
        showAllPhotoComponents()
    }
    private func _present(_ editingStack: EditingStack, square: Bool, faceDetection: Bool = false) {
      var options = ClassicImageEditOptions()

      options.isFaceDetectionEnabled = faceDetection
      if square {
        options.croppingAspectRatio = .square
      } else {
          options.croppingAspectRatio = .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.25)
      }
     
      let controller = ClassicImageEditViewController(editingStack: editingStack, options: options)
        
      controller.handlers.didEndEditing = { [weak self] controller, stack in
        guard let self = self else { return }
        controller.dismiss(animated: false, completion: nil)

//        self.resultCell.image = nil

        try! stack.makeRenderer().render { result in
          switch result {
          case let .success(rendered):
//            self.resultCell.image = rendered.uiImage
              print("* got returned image")
              self.cameraPhotoResult?.image = rendered.uiImage
              self.view.addSubview(self.cameraPhotoResult!)
              self.view?.sendSubviewToBack(self.cameraPhotoResult!)
              self.view.addSubview(self.goBackButton!)
//              self.view.addSubview(self.actualPostButton!)
              self.view.addSubview(self.stepNameLabel!)
              
              self.showPostDetailOptions()
          case let .failure(error):
              print("* error dismissed?")
            print(error)
          }
        }
      }

      controller.handlers.didCancelEditing = { controller in
        controller.dismiss(animated: false, completion: nil)
          print("* user dismissed?")
//          self.showPostDetailOptions()
          self.showAllPhotoComponents()
      }

      let navigationController = UINavigationController(rootViewController: controller)
      navigationController.modalPresentationStyle = .fullScreen

      present(navigationController, animated: false, completion: nil)
    }
}

// MARK: - NextLevelPhotoDelegate
extension CameraViewController: NextLevelPhotoDelegate {
    func nextLevel(_ nextLevel: NextLevel, output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, photoConfiguration: NextLevelPhotoConfiguration) {
    }

    func nextLevel(_ nextLevel: NextLevel, output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings, photoConfiguration: NextLevelPhotoConfiguration) {
    }

    func nextLevel(_ nextLevel: NextLevel, output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings, photoConfiguration: NextLevelPhotoConfiguration) {
    }

    func nextLevel(_ nextLevel: NextLevel, didFinishProcessingPhoto photo: AVCapturePhoto, photoDict: [String: Any], photoConfiguration: NextLevelPhotoConfiguration) {

            PHPhotoLibrary.shared().performChanges({

                let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle)
                if albumAssetCollection == nil {
                    let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle)
                    _ = changeRequest.placeholderForCreatedAssetCollection
                }

            }, completionHandler: { (success1: Bool, error1: Error?) in

                if success1 == true {
                    if let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewController.nextLevelAlbumTitle) {
                        PHPhotoLibrary.shared().performChanges({
                            if let data = photoDict[NextLevelPhotoFileDataKey] as? Data,
                               let photoImage = UIImage(data: data) {
                                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photoImage)
                                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                                let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                                assetCollectionChangeRequest?.addAssets(enumeration)
                            }
                        }, completionHandler: { (success2: Bool, _: Error?) in
                            if success2 == true {
                                let alertController = UIAlertController(title: "Photo Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alertController.addAction(okAction)
                                self.present(alertController, animated: true, completion: nil)
                            }
                        })
                    }
                } else if let _ = error1 {
                    print("failure capturing photo from video frame \(String(describing: error1))")
                }

            })
    }

    func nextLevelDidCompletePhotoCapture(_ nextLevel: NextLevel) {
    }

    func nextLevel(_ nextLevel: NextLevel, didFinishProcessingPhoto photo: AVCapturePhoto) {
    }

}

// MARK: - KVO
private var CameraViewControllerNextLevelCurrentDeviceObserverContext = "CameraViewControllerNextLevelCurrentDeviceObserverContext"

extension CameraViewController {

    internal func addKeyValueObservers() {
        self.addObserver(self, forKeyPath: "currentDevice", options: [.new], context: &CameraViewControllerNextLevelCurrentDeviceObserverContext)
    }

    internal func removeKeyValueObservers() {
        self.removeObserver(self, forKeyPath: "currentDevice")
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &CameraViewControllerNextLevelCurrentDeviceObserverContext {
            // self.captureDeviceDidChange()
        }
    }

}

extension CameraViewController: NextLevelMetadataOutputObjectsDelegate {

    func metadataOutputObjects(_ nextLevel: NextLevel, didOutput metadataObjects: [AVMetadataObject]) {
        guard let previewView = self.previewView else {
            return
        }

        if let metadataObjectViews = metadataObjectViews {
            for view in metadataObjectViews {
                view.removeFromSuperview()
            }
            self.metadataObjectViews = nil
        }

        self.metadataObjectViews = metadataObjects.map { metadataObject in
            let view = UIView(frame: metadataObject.bounds)
            view.backgroundColor = UIColor.clear
            view.layer.borderColor = UIColor.yellow.cgColor
            view.layer.borderWidth = 1
            return view
        }

        if let metadataObjectViews = self.metadataObjectViews {
            for view in metadataObjectViews {
                previewView.addSubview(view)
            }
        }
    }
}
class ImageHelper {
  static func removeExifData(data: NSData) -> NSData? {
    guard let source = CGImageSourceCreateWithData(data, nil) else {
        return nil
    }
    guard let type = CGImageSourceGetType(source) else {
        return nil
    }
    let count = CGImageSourceGetCount(source)
      let mutableData = NSMutableData(data: data as Data)
    guard let destination = CGImageDestinationCreateWithData(mutableData, type, count, nil) else {
        return nil
    }
    // Check the keys for what you need to remove
    // As per documentation, if you need a key removed, assign it kCFNull
      let removeExifProperties: CFDictionary = [String(kCGImagePropertyExifDictionary) : kCFNull, String(kCGImagePropertyOrientation): kCFNull] as CFDictionary

    for i in 0..<count {
        CGImageDestinationAddImageFromSource(destination, source, i, removeExifProperties)
    }

    guard CGImageDestinationFinalize(destination) else {
        return nil
    }

    return mutableData;
  }
}
extension UIImage {

    func getExifData() -> CFDictionary? {
        var exifData: CFDictionary? = nil
        if let data = self.jpegData(compressionQuality: 1.0) {
            data.withUnsafeBytes {
                let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                if let cfData = CFDataCreate(kCFAllocatorDefault, bytes, data.count),
                    let source = CGImageSourceCreateWithData(cfData, nil) {
                    exifData = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                }
            }
        }
        return exifData
    }
}
