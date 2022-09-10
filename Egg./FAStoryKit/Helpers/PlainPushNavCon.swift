//
//  PlainPushNavCon.swift
//  Mf_3
//
//  Created by Ferhat Abdullahoglu on 3.08.2019.
//  Copyright © 2019 Ferhat Abdullahoglu. All rights reserved.
//

import UIKit
//import FAStoryKit

/// Main target here is to replicate the same UINavigationController
/// push & pop transitions only skipping the fading part.
/// This is useful if one wants have his/her own transition overlay views
/// during the animations. That case, the fading of the push/pop animations
/// make the colors seem incomplete
class PlainPushNavCon: UINavigationController,
                       SwipeDismissInteractibleNavigationController,
                       SwipeDismissInteractible,
                       UIGestureRecognizerDelegate {
    /// interaction controller for the animations
    public var navigationControllerInteractor: SwipeInteractionController?
    
    /// view for the interactor
    var gestureView: UIView {
        return view
    }
    
    /// configure the interaction controller
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationControllerInteractor = SwipeInteractionController(viewController: self, direction: .horizontalLeftEdge)
    }
    
    func gestureToBeFailedByDismiss(gesture: UIGestureRecognizer) -> UIGestureRecognizer? {
        return nil
    }
    
    func gestureToUse() -> UIPanGestureRecognizer? {
        return nil
    }
    
}

extension PlainPushNavCon: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let animator = PlainPushPopAnimator(transition: operation, duration: 0.25, translationRatio: 0.3)
        animator.interactionController = navigationControllerInteractor
        return animator
        
        
        
    }
    
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let plainPush = animationController as? PlainPushPopAnimator else {return nil}
        
        if plainPush.isPop {
            guard let i = plainPush.interactionController, i.interactionInProgress else {return nil}
            return i
        }
        
        return nil
    }
    
}

