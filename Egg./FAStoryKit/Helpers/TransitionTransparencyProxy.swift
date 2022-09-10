
import UIKit
//import FAStoryKit
 
public protocol TransitionTransparencyProxy where Self: UIViewController  {
    ///
    var transparentTopView: UIView! {get set}
    
    func start()
    
    func config()
}

public extension TransitionTransparencyProxy {
    func config() {
        
        // check that the trasnparentTopView is nil or has not yet been added to a parentView
        guard transparentTopView?.superview == nil else {return}
        
        transparentTopView = UIView()
        transparentTopView.translatesAutoresizingMaskIntoConstraints = false
        transparentTopView.backgroundColor = UIColor.black.withAlphaComponent(0)
        transparentTopView.isUserInteractionEnabled = false 
        view.addSubview(transparentTopView)
        
        transparentTopView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        transparentTopView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        transparentTopView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        transparentTopView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.layoutIfNeeded()
    }
    
}
