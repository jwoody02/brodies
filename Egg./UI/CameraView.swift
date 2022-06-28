



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


class CameraViewController: UIViewController, PhotoEditorDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func doneEditing(image: UIImage) {
        
    }
    
    func canceledEditing() {
        
    }
    

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
    internal var actualPostButton: UIButton?
    
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
    
    internal var stepNameLabel: UILabel?
    internal var nextButton: UIButton?
    internal var captionView: UITextView?
    internal var goBackButton: UIButton?
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
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
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
        // preview (default is story
        self.previewView = UIView(frame: CGRect(x: 0, y: 40, width: screenBounds.width, height: screenBounds.width*1.77777777))
        if let previewView = self.previewView {
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            previewView.layer.cornerRadius = Constants.borderRadius
            previewView.clipsToBounds = true
            previewView.backgroundColor = UIColor.black
            NextLevel.shared.previewLayer.frame = previewView.bounds
            NextLevel.shared.flashMode = .auto
            previewView.layer.addSublayer(NextLevel.shared.previewLayer)
            
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
            longPressGestureRecognizer.delegate = self
            longPressGestureRecognizer.minimumPressDuration = 0.05
            longPressGestureRecognizer.allowableMovement = 10.0
            recordButton.addGestureRecognizer(longPressGestureRecognizer)
        }
        self.actualPostButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let actualPostButton = actualPostButton {
            actualPostButton.backgroundColor = hexStringToUIColor (hex:Constants.primaryColor)
            actualPostButton.layer.cornerRadius = 4
            actualPostButton.layer.shadowColor = hexStringToUIColor (hex:Constants.primaryColor).withAlphaComponent(0.3).cgColor
            actualPostButton.layer.shadowOffset = CGSize(width: 4, height: 10)
            actualPostButton.layer.shadowOpacity = 0.5
            actualPostButton.layer.shadowRadius = 4
            actualPostButton.titleLabel!.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
            actualPostButton.setTitle("Post", for: .normal)
            actualPostButton.alpha = 0
            actualPostButton.addTarget(self, action: #selector(handlePostButton(_:)), for: .touchUpInside)
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
            nextButton.titleLabel!.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
            nextButton.setTitle("Next", for: .normal)
            nextButton.addTarget(self, action: #selector(handleNextButton(_:)), for: .touchUpInside)
            nextButton.setTitleColor(.white, for: .normal)
        }
        self.stepNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let stepNameLabel = stepNameLabel {
            stepNameLabel.textAlignment = .center
            stepNameLabel.textColor = .white
            stepNameLabel.text = "Choose Filter"
            let stepNameWidth = 100
            stepNameLabel.frame = CGRect(x: CGFloat((Int(Float16(UIScreen.main.bounds.width)) / 2) - stepNameWidth/2), y: (previewView?.frame.minY)! + 20, width: CGFloat(stepNameWidth), height: 40)
            stepNameLabel.font = UIFont(name: Constants.globalFont, size: 16)
        }
        self.flipButton = UIButton(type: .custom)
        if let flipButton = self.flipButton {
            flipButton.setImage(UIImage(named: "flip_button"), for: .normal)
            flipButton.sizeToFit()
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
                AddLocationTextField.font = UIFont(name: Constants.globalFont, size: 14)
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
                distanceAway.font = UIFont(name: Constants.globalFont, size: 10)
                AddLocationView.addSubview(distanceAway)
            }
            AddLocationView.backgroundColor = .darkGray.withAlphaComponent(0.5)
            AddLocationView.layer.cornerRadius = 4
            AddLocationView.alpha = 0
            let locationTapped = UITapGestureRecognizer(target: self, action: #selector(handleLocationViewTapped(_:)))
            AddLocationView.addGestureRecognizer(locationTapped)
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
                AddPeopleTextField.font = UIFont(name: Constants.globalFont, size: 14)
                AddPeopleTextField.attributedPlaceholder = NSAttributedString(string: "Tag Other People",
                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
                AddPeopleTextField.textColor = .white
//                AddPeopleTextField.delegate = self
//                AddPeopleTextField.addTarget(self, action: #selector(handleLocationViewTapped(_:)), for: .touchDown)
//                AddPeopleTextField.addTarget(self, action: #selector(CameraViewController.textFieldDidChange(_:)), for: .editingChanged)
                AddPeopleView.addSubview(AddPeopleTextField)
            }
            AddPeopleView.backgroundColor = .darkGray.withAlphaComponent(0.5)
            AddPeopleView.layer.cornerRadius = 4
            AddPeopleView.alpha = 0
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
//                addPeopleIcon.isUserInteractionEnabled = true
//                addPeopleIcon.addGestureRecognizer(tapGestureRecognizer)
                AddTagsView.addSubview(addTagsIcon)
            }
            AddTagsTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let AddTagsTextField = AddTagsTextField {
                AddTagsTextField.backgroundColor = .clear
                AddTagsTextField.font = UIFont(name: Constants.globalFont, size: 14)
                AddTagsTextField.attributedPlaceholder = NSAttributedString(string: "Post Hashtags",
                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
                AddTagsTextField.textColor = .white
//                AddPeopleTextField.delegate = self
//                AddPeopleTextField.addTarget(self, action: #selector(handleLocationViewTapped(_:)), for: .touchDown)
//                AddPeopleTextField.addTarget(self, action: #selector(CameraViewController.textFieldDidChange(_:)), for: .editingChanged)
                AddTagsView.addSubview(AddTagsTextField)
            }
            AddTagsView.backgroundColor = .darkGray.withAlphaComponent(0.5)
            AddTagsView.layer.cornerRadius = 4
            AddTagsView.alpha = 0
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
            flashButton.setImage(UIImage(named: "flash_auto")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
            flashButton.addTarget(self, action: #selector(handleFlashButton(_:)), for: .touchUpInside)
            
//            flashButton.imageView?.contentMode = .scaleAspectFit
            flashButton.frame = CGRect(x: UIScreen.main.bounds.width - 20 - 30, y: (previewView?.frame.minY)! + 20, width: 30, height: 30)
            flashButton.setTitleColor(.white, for: .normal)
            flashButton.tintColor = .white
            flashButton.backgroundColor = .clear
//            flashButton.setTitle("Auto", for: .normal)
            currentFlashMode = .auto
            print("adding flash button")
            let flashToggle = UITapGestureRecognizer(target: self, action: #selector(handleFlashButton(_:)))
            flashButton.addGestureRecognizer(flashToggle)
//            self.view.addSubview(flashButton)
            
        }
        self.goBackButton = UIButton(type: .custom)
        if let goBackButton = self.goBackButton {
            goBackButton.setImage(UIImage(systemName: "chevron.left")?.applyingSymbolConfiguration(.init(pointSize: 20, weight: .bold, scale: .medium)), for: .normal)
            goBackButton.addTarget(self, action: #selector(handleBackbutton(_:)), for: .touchUpInside)
            goBackButton.frame = CGRect(x: 20, y: (previewView?.frame.minY)! + 20, width: 40, height: 40)
            goBackButton.setTitleColor(.white, for: .normal)
            goBackButton.tintColor = .white
            goBackButton.backgroundColor = .darkGray.withAlphaComponent(0.5)
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
            let LeftAndRightPaddingInView = 80
            let PaddingBetweenEachother = 10
            let buttonWidths = (Int(UIScreen.main.bounds.width) - (LeftAndRightPaddingInView*2) - (PaddingBetweenEachother * 2)) / 3
            let buttonY = 0
            let buttonHeights = menubarUIView.frame.height - 10
            
            let postButton = UIButton(frame: CGRect(x: LeftAndRightPaddingInView, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            postButton.tintColor = UIColor.white.withAlphaComponent(0.4)
            postButton.backgroundColor = UIColor.clear
            postButton.setTitle("POST", for: .normal)
            postButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
            postButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            
            let storyButton = UIButton(frame: CGRect(x: Int(postButton.frame.maxX) + PaddingBetweenEachother, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            storyButton.tintColor = UIColor.white
            storyButton.backgroundColor = UIColor.clear
            storyButton.setTitle("STORY", for: .normal)
            storyButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
            storyButton.setTitleColor(UIColor.white.withAlphaComponent(1), for: .normal)
            
            let textButton = UIButton(frame: CGRect(x: Int(storyButton.frame.maxX) + PaddingBetweenEachother, y: buttonY, width: buttonWidths, height: Int(buttonHeights)))
            textButton.tintColor = UIColor.white.withAlphaComponent(0.4)
            textButton.backgroundColor = UIColor.clear
            textButton.setTitle("STATUS", for: .normal)
            textButton.titleLabel?.font = UIFont(name: "\(Constants.globalFont)-Bold", size: 14)
            textButton.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            
            
            postButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
            storyButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
            textButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)

            self.menubarUIView?.addSubview(postButton)
            self.menubarUIView?.addSubview(storyButton)
            self.menubarUIView?.addSubview(textButton)
            
            
            
            let littleBarHeight = 2
            self.littleBottomBar = UIView(frame: CGRect(x: 0, y: (Int(buttonHeights) / 2) + 10, width: buttonWidths - 10, height: littleBarHeight))
            self.littleBottomBar?.center.x = storyButton.center.x
            self.littleBottomBar?.backgroundColor = .white
            self.littleBottomBar?.layer.cornerRadius = 4
            
            
            self.menubarUIView?.addSubview(littleBottomBar!)
            
            if let flipButton = self.flipButton, let recordButton = self.recordButton {
//                let flipButtonWidth = UIScreen.main.bounds.width - textButton.frame.maxX - PaddingBetweenEachother - (PaddingBetweenEachother*2)
                flipButton.frame = CGRect(x: Int(textButton.frame.maxX) + LeftAndRightPaddingInView / 4, y: 30, width: 40, height: 40)
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
            self.view.addSubview(snapPicButton)
        }
        // gestures
        self.gestureView = UIView(frame: screenBounds)
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
        nextLevel.metadataObjectTypes = [] //AVMetadataObject.ObjectType.face, AVMetadataObject.ObjectType.qr
        
        
        // double tap to reverse camera
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        self.previewView?.addGestureRecognizer(tap)
        
        NextLevel.shared.flipCaptureDevicePosition()
        searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.pointOfInterest])
    }
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    func uploadPostMedia(completion: @escaping (_ url: String?) -> Void) {
        let userID : String = (Auth.auth().currentUser?.uid)!
        let storageRef = Storage.storage().reference().child("post_photos/\(userID)/\(randomString(length: 20))")
        guard let imageData = cameraPhotoResult!.image!.jpegData(compressionQuality: 0.75) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        storageRef.putData(imageData, metadata: metaData) { metaData, error in
            if error == nil, metaData != nil {
                
                storageRef.downloadURL { url, error in
                    completion(url?.absoluteString)
                    // success!
                }
            } else {
                // failed
                completion(nil)
            }
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
                }
        }
    }
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        let searchString = textField.text
        searchCompleter.queryFragment = searchString ?? ""
        
    }
    @objc internal func handleGalaryTapped(_ view: UIView) {
        imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
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
        if self.currentFlashMode == .auto {
            NextLevel.shared.flashMode = .on
            flashButton?.setImage(UIImage(named: "flash_on"), for: .normal)
        } else if currentFlashMode == .on {
            NextLevel.shared.flashMode = .off
        } else {
            NextLevel.shared.flashMode = .auto
            flashButton?.setImage(UIImage(named: "flash_auto"), for: .normal)
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
        return searchCompleter.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mapItem = searchCompleter.results[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        cell.textLabel?.attributedText = highlightedText(mapItem.title, inRanges: mapItem.titleHighlightRanges, size: 17.0)
        cell.detailTextLabel?.text = mapItem.subtitle
        cell.contentView.backgroundColor = UIColor.black
        cell.detailTextLabel?.textColor = .lightGray
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        print("* Selected at \(searchCompleter.results[indexPath.row].title)")
        print(searchCompleter.results[indexPath.row].subtitle)
        let currentLat = self.locationManager.location!.coordinate.latitude
        let currentLong = self.locationManager.location!.coordinate.longitude
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(searchCompleter.results[indexPath.row].subtitle) { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
            else {
                // handle no location found
                return
            }
            
            // Use your location
            let distanceInMeters = location.distance(from: self.locationManager.location!)
            print("* got distance in meters from current location: \(distanceInMeters)")
            if(distanceInMeters <= 1609)
             {
             // under 1 mile
                self.AddLocationTextField?.text = "\(self.searchCompleter.results[indexPath.row].title)"
                self.distanceAway?.text = "\(Int(distanceInMeters*3.28084)) feet away"
             }
             else
            {
             // out of 1 mile
                 self.AddLocationTextField?.text = "\(self.searchCompleter.results[indexPath.row].title)"
                 self.distanceAway?.text = "\(Int(distanceInMeters*0.000621371)) miles away"
             }
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
        attributedText.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "\(Constants.globalFont)", size: 16)!, range:NSMakeRange(0, text.count))
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
            self.littleBottomBar?.frame = CGRect(x: sender.frame.minX + 5, y: CGFloat((Int(sender.frame.height) / 2) + 10), width: sender.frame.width - 10, height: self.littleBottomBar!.frame.height)

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
                self.previewView?.frame = CGRect(x: (self.previewView?.frame.minX)!, y: (self.closeButton?.frame.maxY)! + 20, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.25)
//                self.previewView?.frame = CGRect(x: (self.previewView?.frame.minX)!, y: (self.previewView?.frame.minY)!, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width*1.4)
                let snapX = (Int(Float16(UIScreen.main.bounds.width)) / 2) - ((80) / 2)
                self.snapPicButton?.frame = CGRect(x: snapX, y: Int((self.previewView?.frame.maxY)!) + 30, width: 80, height: 80)
//                let distanceForButton = Int(UIScreen.main.bounds.height) - Int(self.menubarUIView?.frame.height ?? 0) - Int((self.previewView?.frame.maxY)!)
//                let snapPicWidthHeight = distanceForButton // used to be 80
//                let snapX = (Int(Float16(UIScreen.main.bounds.width)) / 2) - ((snapPicWidthHeight) / 2)
//                let snapPicY =  Int((self.previewView?.frame.maxY)!)
//                self.snapPicButton?.frame = CGRect(x: snapX, y: snapPicY, width: snapPicWidthHeight, height: snapPicWidthHeight)
//                self.snapPicButton?.layer.cornerRadius = CGFloat(snapPicWidthHeight / 2)
//                NextLevel.shared.previewLayer.frame = self.previewView!.bounds
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
            print("text menu bar button tapped")
            postType = "status"
            (menubarUIView?.subviews[0] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            (menubarUIView?.subviews[1] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
            (menubarUIView?.subviews[2] as! UIButton).setTitleColor(UIColor.white.withAlphaComponent(1), for: .normal)
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
            self.snapPicButton?.fadeOut()
            self.menubarUIView?.fadeOut()
            self.closeButton?.fadeOut()
            
//            self.cameraPhotoResult?.fadeIn()
        }
        
    }
    func showAllPhotoComponents() {
        
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
            hidePostDetailsOptions()
//            getNearbyPlaces()
            
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
        self.actualPostButton?.frame = self.nextButton!.frame
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
        self.captionView?.font = UIFont(name: Constants.globalFont, size: 14)
        
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
    @objc internal func handlePostButton(_ button: UIButton)
    {
        print("* posting photo")
            let userID : String = (Auth.auth().currentUser?.uid)!
            uploadPostMedia() { url in
                  guard let url = url else { return }
                let timestamp = NSDate().timeIntervalSince1970
                let ref = self.db.collection("posts").document(userID).collection("posts").document()
                let documentId = ref.documentID
                let imageHash = self.cameraPhotoResult?.image?.blurHash(numberOfComponents: (7, 4))
                print("* calculated image hash: \(imageHash)")
                ref.setData([
                    "caption"      : (self.captionView?.text ?? "").replacingOccurrences(of: "Enter a caption", with: ""),
                    "tags"    : [],
                    "authorID"     : userID,
                    "createdAt": Int(timestamp),
                    "location"       : self.AddLocationTextField?.text ?? "",
                    "imageHash": (imageHash ?? "") as! String,
                    "postImageUrl" : url,
                    "likes_count": 0
                ])
                self.db.collection("followers").document(userID).updateData(["last_post":["id":documentId,"createdAt":timestamp]])
                print("* uploading post with image url: \(url)")
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
extension CameraViewController: NextLevelVideoDelegate {

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
            hideAllPhotoComponents()
            if postType == "post" {
                showPhotoPostComponents()
            }
            
        }
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
