//
//  PlainPushAnimator.swift
//  Mf_3
//
//  Created by Ferhat Abdullahoglu on 2.08.2019.
//  Copyright © 2019 Ferhat Abdullahoglu. All rights reserved.
//

import UIKit
//import FAStoryKit


enum PlainTransitionType: Int {
    case push = 0
    case pop = 1
}


/// Push & Pop custom animator object for __UINavigationController__
/// main idea is to give the same affect with the navigation controllers
/// but without the fading effect the native transition has.
///
/// This animator could be used in case there is a custom transition already existing
/// within the involved ViewController's and their navigation bars.
/// In such a case the custom black fading of the __UINavigationController__ makes
/// transition among different colors seem incomplete

class PlainPushPopAnimator: NSObject {
    
    
    // ==================================================== //
    // MARK: Properties
    // ==================================================== //
    
    // -----------------------------------
    // Public properties
    // -----------------------------------
    /// interacotr object
    public weak var interactionController: SwipeInteractionController?
    
    /// flag for pop operations
    public var isPop: Bool {
        return _transitionType == .pop
    }
    // -----------------------------------
    
    
    // -----------------------------------
    // Private properties
    // -----------------------------------
    /// current object's animation type
    private let _transitionType: PlainTransitionType
    
    /// animation duration
    private let _duration: Double
    
    /// translation ratio
    private let _translationRatio: CGFloat
    // -----------------------------------
    
    
    // ==================================================== //
    // MARK: Init
    // ==================================================== //
    /// Initializes an animator with the given parameters
    ///
    /// - Parameters:
    ///   - type: Type of the transition - either Pop or Push
    ///   - duration: Duration of the transition
    ///   - translationRatio: Ratio for the translation between presented & dismissed
    init(transition type: UINavigationController.Operation, duration: Double, translationRatio: CGFloat) {
        _transitionType = type == UINavigationController.Operation.push ? .push : .pop
        _duration = duration
        _translationRatio = translationRatio
        //
        super.init()
    }
    
    
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
    /// Dismissal animations
    ///
    /// - Parameter context: Transitioning context passed to the animator
    private func _popAnimations(with transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        
        guard let snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else {
            return
        }
        
        snapshot.frame = fromVC.view.frame
        
        
        // add the toVC to the container
        let containerView = transitionContext.containerView
        
        containerView.addSubview(toVC.view)
        toVC.view.isHidden = false
        containerView.addSubview(fromVC.view)
        containerView.bringSubviewToFront(fromVC.view)
        
        
        let fromVcTranslation = fromVC.view.bounds.width
        let toVcTranslation = floor(toVC.view.bounds.width * (1 - _translationRatio))
        
        toVC.view.frame = toVC.view.frame.offsetBy(dx: -toVcTranslation, dy: 0)
        UIView.animate(withDuration: transitionContext.isAnimated ? _duration : 0,
                       delay: 0,
                       options: [.curveLinear, .layoutSubviews],
                       animations: {
                        toVC.view.frame = toVC.view.frame.offsetBy(dx: toVcTranslation, dy: 0)
                        fromVC.view.transform = CGAffineTransform(translationX: fromVcTranslation, y: 0)
        }) { (_) in
            if transitionContext.transitionWasCancelled {
            } else {
                fromVC.view.removeFromSuperview()
            }
            snapshot.removeFromSuperview()
            snapshot.isHidden = true
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    
    /// Presentation animations
    ///
    /// - Parameter context: Transitioning context passed to the animator
    private func _pushAnimations(with transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to)
            else {
                return
        }
        
        guard let snapshotFrom = fromVC.view.snapshotView(afterScreenUpdates: true) else {
            return
        }
        
        snapshotFrom.tag = 9876
        snapshotFrom.frame = transitionContext.initialFrame(for: fromVC)
        snapshotFrom.window?.backgroundColor = .white
        
        let containerView = transitionContext.containerView
        
        //
        // add the toVC to the container
        //
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        
        
        //
        // prepare the transform matrices for the viewControllers
        // depending on the presentation direction
        //
        let fromVcTranslation = -floor(fromVC.view.bounds.width * _translationRatio)
        let toVcTranslation = toVC.view.bounds.width
        
        containerView.addSubview(toView)
        containerView.insertSubview(fromView, belowSubview: toView)
        toView.transform = CGAffineTransform(translationX: toVcTranslation, y: 0)
        toView.isHidden = false
        
        //
        // Animations
        //
        UIView.animate(withDuration: transitionContext.isAnimated ? _duration : 0,
                       delay: 0,
                       options: [.curveLinear, .layoutSubviews],
                       animations: {
                        toView.transform = .identity
                        fromView.frame = fromView.frame.offsetBy(dx: fromVcTranslation, dy: 0)
        }) { (_) in
            if transitionContext.transitionWasCancelled {
                toView.removeFromSuperview()
                fromView.isHidden = false
            }
            snapshotFrom.removeFromSuperview()
            snapshotFrom.isHidden = true
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    // -----------------------------------
    
}

//
// MARK: - UIViewControllerAnimatedTransitioning
//
extension PlainPushPopAnimator: UIViewControllerAnimatedTransitioning {
    /// Duration of the transition
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return _duration
    }
    
    /// Transitions
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch _transitionType {
        case .pop:
            _popAnimations(with: transitionContext)
        case .push:
            _pushAnimations(with: transitionContext)
        }
    }
    
}
