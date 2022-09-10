//
//  ModalPresentationAnimator.swift
//  Mf_3
//
//  Created by Ferhat Abdullahoglu on 29.05.2019.
//  Copyright © 2019 Ferhat Abdullahoglu. All rights reserved.
//

import UIKit

protocol ModalPresentationAnimatorProtocol: class {
    func didComplete(_ completed: Bool, isDismissal: Bool)
}

class ModalPresentationAnimator: MainTransitionAnimator {
    // ==================================================== //
    // MARK: IBOutlets
    // ==================================================== //
    
    
    // ==================================================== //
    // MARK: IBActions
    // ==================================================== //
    
    
    // ==================================================== //
    // MARK: Properties
    // ==================================================== //
    
    // -----------------------------------
    // Public properties
    // -----------------------------------
    override var topClearance: CGFloat {
        return _topClearance
    }
    
    public weak var delegate: ModalPresentationAnimatorProtocol?
    // -----------------------------------
    
    
    // -----------------------------------
    // Private properties
    // -----------------------------------
    /// internal top clearance distance
    private let _topClearance: CGFloat
    
    /// transparent background view
    private let _transparentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        return view
    }()
    
    /// shouldRasterize
    private let _rasterize: Bool
    // -----------------------------------
    
    
    // ==================================================== //
    // MARK: Init
    // ==================================================== //
    init(duration: Double, dismiss: Bool, topDistance: CGFloat, rasterizing: Bool = true) {
        _topClearance = topDistance
        _rasterize = rasterizing
        super.init(duration: duration, dismiss: dismiss, rasterizing: rasterizing)
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
        
        
        let containerView = transitionContext.containerView
        
        //
        // Clear the status bar color
        //
        fromVC.view.clipsToBounds = true
        
        //
        // add the toVC to the container
        //
        containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        
        let _orginalFrame = transitionContext.finalFrame(for: toVC)
        
        let _topBarToClear = _topClearance
        
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
        // Configure the transparentView
        //
        if _transparentView.superview == nil {
            _transparentView.tag = 9393
            
            containerView.insertSubview(_transparentView, belowSubview: toVC.view)
            
            _transparentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
            _transparentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
            _transparentView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            _transparentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        }

        
        //
        // Animations
        //
        UIView.animate(withDuration: transitionContext.isAnimated ? _duration : 0,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0,
                       options: .curveEaseOut,
                       animations: {
                        toVC.view.transform = .identity
                        self._transparentView.backgroundColor = UIColor.black.withAlphaComponent(1)
        }) { [weak self](_) in
            toVC.view.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            if let self = self {
                self.delegate?.didComplete(!transitionContext.transitionWasCancelled, isDismissal: false)
            }
//            self._transparentView.removeFromSuperview()
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
        
        if _rasterize {
            fromVC.view.isHidden = true
        }
        
        // add the toVC to the container
        let containerView = transitionContext.containerView
        toVC.view.isHidden = false
        if _rasterize {
            containerView.addSubview(snapshot)
        }
        
        //
        // Configure the transparentView
        //
        let transparentView = containerView.viewWithTag(9393)
        
        
        //
        // Animations
        //
        UIView.animateKeyframes(withDuration: transitionContext.isAnimated ? _duration : 0,
                                delay: 0, options: [.calculationModeLinear, .beginFromCurrentState],
                                animations: {
                                    if self._rasterize {
                                        snapshot.transform = CGAffineTransform(translationX: 0, y: snapshot.bounds.height)
                                    } else {
                                        fromVC.view.transform = CGAffineTransform(translationX: 0, y: fromVC.view.bounds.height)
                                    }
                                   
                                    transparentView?.backgroundColor = UIColor.black.withAlphaComponent(0)
                                    
        }) {[weak self] (_) in
            //
            // check if the transition was cancelled
            //
            if !transitionContext.transitionWasCancelled {
                toVC.view.isHidden = false
                if let tabCont = (toVC as? UITabBarController),
                    let navCon = tabCont.viewControllers?[tabCont.selectedIndex] as? UINavigationController,
                    let vc = navCon.topViewController as? StatusBarColorProxy    {
                    vc.setBarColor(nil, animated: false)
                }
                
                fromVC.view.removeFromSuperview()
            } else { // transition is cancelled
                fromVC.view.isHidden = false
            }
            
            
            if let self = self {
                self.delegate?.didComplete(!transitionContext.transitionWasCancelled, isDismissal: true)
            }
            
            
            snapshot.removeFromSuperview()
            self?._transparentView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    // -----------------------------------
}

extension ModalPresentationAnimator {
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if _isDimissal {
            _dismissAnimations(with: transitionContext)
        } else {
            _presentationAnimations(with: transitionContext)
        }
    }
}
