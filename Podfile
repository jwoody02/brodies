# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Egg.' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'SwiftKeychainWrapper'
  pod 'DWAnimatedLabel', '~> 1.1'
  pod 'SwipeableTabBarController'
  pod 'FirebaseCore'
  pod 'FirebaseFirestore'
  pod 'FirebaseAuth'
  pod 'FirebaseAnalytics'
  pod 'FirebaseMessaging'
  pod 'GoogleSignIn'
  pod 'Presentr'
  pod 'SkeletonView', '~> 1.21.0'
  pod 'Google-Mobile-Ads-SDK'
  pod "NextLevel", "~> 0.16.3"
  pod 'FMPhotoPicker', '~> 1.3.0'
  pod 'iOSPhotoEditor'
  pod 'FirebaseStorage'
  pod 'Kingfisher'
  pod 'loady'
  pod 'SPAlert'
  pod 'Alamofire', '~> 4.0'
  pod 'AlamofireImage', '~> 3.0'
  pod "ViewAnimator"
  pod 'DGElasticPullToRefresh'
  pod 'Zoomy'
  pod 'PanModal'
  pod 'IQKeyboardManager'
  pod 'FirebaseAppCheck'
  pod 'ImageSlideshow', '~> 1.9.0'
  pod "ImageSlideshow/Kingfisher"
  pod "PageControls"
  pod 'ISPageControl', '~> 0.1.0'
  pod 'MDFInternationalization'
  pod 'MaterialComponents'
  pod 'SwiftyGif'
  pod 'ActiveLabel'
  pod 'DPTagTextView'
  pod 'TransitionButton'
  pod 'FirebaseDynamicLinks'
  # pod 'InteractiveZoomDriver'
#  pod 'SnapSDK'
  # Pods for Egg.

end
post_install do |installer|
installer.pods_project.targets.each do |target|
target.build_configurations.each do |config|
config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
end
end
end
