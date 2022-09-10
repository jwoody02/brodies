//
//  MainSettingsDismissAnimator.swift
//  Mf_3
//
//  Created by Ferhat Abdullahoglu on 22.05.2019.
//  Copyright © 2019 Ferhat Abdullahoglu. All rights reserved.
//

import UIKit
//import FAStoryKit

class MainTransitionAnimator: NSObject {
    
    
    // ==================================================== //
    // MARK: Properties
    // ==================================================== //
    
    // -----------------------------------
    // Public properties
    // -----------------------------------
    
    /// Interaction controller for the dismissal
    public var dismissInteractionController: SwipeInteractionController?
    
    /// Top distance to clear
    public var topClearance: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    // -----------------------------------
    
    
    // -----------------------------------
    // Private properties
    // -----------------------------------
    
    /// Transition duration
    var _duration: Double
    
    /// Should handle the dismissals
    var _isDimissal: Bool
    
    /// Rasterized -> if true will work with snapshot
    private var _isRasterized: Bool
    
    /// Orginal view to transition back into in case of a dismissal animation
    private weak var _originView: UIView?
    // -----------------------------------
    
    
    // ==================================================== //
    // MARK: Init
    // ==================================================== //
    init(duration: Double, dismiss: Bool, rasterizing: Bool = true, withOrginView view: UIView?=nil) {
        _duration = duration
        _isDimissal = dismiss
        _isRasterized = rasterizing
        _originView = view?.mutableCopy() as? UIView
    }
    
    // ==================================================== //
    // MARK: VC lifecycle
    // ==================================================== //
    
    
    // ==================================================== //
    // MARK: Methods
    // ==================================================== //
    
    // -----------------------------------
    // Public methods
    // -----------------------------------
    
    // -----------------------------------
    
    
    // -----------------------------------
    // Private methods
    // -----------------------------------
    /// animations for presentating the viewController
    private func _presentationAnimations(with transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        
        //
        // check for the transition transparency
        //
        if let _from = fromVC as? TransitionTransparencyProxy {
            _from.config()
            _from.start()
        }
        
        let containerView = transitionContext.containerView
        
        //
        // Clear the status bar color
        //
        fromVC.view.clipsToBounds = true
        
        //
        // add the toVC to the container
        //
        containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        
        (fromVC as? TransitionTransparencyProxy)?.transparentTopView.isHidden = false
        
        let _orginalFrame = transitionContext.finalFrame(for: toVC)
        
        let _topBarToClear = topClearance
        
        let _destFrame = CGRect(x: _orginalFrame.origin.x,
                                y: _orginalFrame.origin.y + _topBarToClear,
                                width: _orginalFrame.width,
                                height: _orginalFrame.height - _topBarToClear)
        
        //
        // Set the new frame for the toVC and send it below
        // later to be able to animate it
        //
        toVC.view.frame = _destFrame
        toVC.view.transform = CGAffineTransform(translationX: 0, y: toVC.view.frame.height)
        
        //
        // Animations
        //
        UIView.animate(withDuration: transitionContext.isAnimated ? _duration : 0,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseOut,
                       animations: {
                        toVC.view.transform = .identity
                        if let _vc = fromVC as? TransitionTransparencyProxy {
                            _vc.transparentTopView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                        }
        }) { (_) in
            toVC.view.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    
    
    /// animations fot dismissing the viewController
    private func _dismissAnimations(with transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        
        guard let snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else {
            return
        }
        
        snapshot.frame = fromVC.view.frame
        
        fromVC.view.isHidden = _isRasterized
        
        // add the toVC to the container
        let containerView = transitionContext.containerView
        toVC.view.isHidden = false
        
        if _isRasterized {
            containerView.addSubview(snapshot)
        }
        
        //
        // Check if there is an orgin view
        //
        let _finalFrame: CGRect?
        let _cornerRadius: CGFloat?
        
        if let view = _originView {
            _finalFrame = view.frame
            _cornerRadius = view.layer.cornerRadius
        } else {
            _finalFrame = nil
            _cornerRadius = nil
        }
        
        let relativeInitialAnimation: Double
        
        if transitionContext.isInteractive {
             relativeInitialAnimation = _finalFrame == nil ? 1 : 0.9
        } else {
            relativeInitialAnimation = _finalFrame == nil ? 1 : 0
        }
        
        //
        // Animations
        //
        UIView.animateKeyframes(withDuration: transitionContext.isAnimated ? _duration : 0,
                                delay: 0,
                                options: [.calculationModeLinear, .beginFromCurrentState],
                                animations: {
                                    
                                    UIView.addKeyframe(withRelativeStartTime: 0,
                                                       relativeDuration: relativeInitialAnimation) {
                                                        
                                                        if self._isRasterized {
                                                            snapshot.transform = CGAffineTransform(translationX: 0, y: snapshot.bounds.height)
                                                        } else  {
                                                            fromVC.view.transform = CGAffineTransform(translationX: 0, y: toVC.view.bounds.height)
                                                        }
                                                        (toVC as? TransitionTransparencyProxy)?.transparentTopView?.backgroundColor = UIColor.black.withAlphaComponent(0)
                                    }
                                    
                                    if let _frame = _finalFrame, let _radius = _cornerRadius {
                                        UIView.addKeyframe(withRelativeStartTime: relativeInitialAnimation,
                                                           relativeDuration: 1-relativeInitialAnimation) {
                                                            fromVC.view.transform = .identity
                                                            fromVC.view.frame = _frame
                                                            fromVC.view.clipsToBounds = true
                                                            fromVC.view.layer.masksToBounds = true
                                                            fromVC.view.layer.cornerRadius = _radius
                                        }
                                    }
                                    
                                    
                                    
        }) { (_) in
            //
            // check if the transition was cancelled
            //
            if !transitionContext.transitionWasCancelled {
                toVC.view.isHidden = false
                (toVC as? TransitionTransparencyProxy)?.transparentTopView?.isHidden = true
                fromVC.view.removeFromSuperview()
            } else { // transition is cancelled
                fromVC.view.isHidden = false
            }
            
            snapshot.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    // -----------------------------------
}

/* ==================================================== */
/* MARK: UIViewControllerAnimatedTransitioning          */
/* ==================================================== */
extension MainTransitionAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return _duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if _isDimissal {
            _dismissAnimations(with: transitionContext)
        } else {
            _presentationAnimations(with: transitionContext)
        }
    }
}
