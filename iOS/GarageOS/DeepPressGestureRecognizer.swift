//
//  DeepPressGestureRecognizer.swift
//  DeepPressGestureRecognizer
//
//  Created by SIMON_NON_ADMIN on 03/10/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
//  Thanks to Alaric Cole - bridging header replaced by proper import :)

import AudioToolbox
import UIKit.UIGestureRecognizerSubclass

// MARK: GestureRecognizer

class DeepPressGestureRecognizer: UIGestureRecognizer
{
    var vibrateOnDeepPress = true
    let threshold: CGFloat
    let use3DTouch: Bool
    
    private var deepPressed: Bool = false
    
    required init(target: AnyObject?, action: Selector, threshold: CGFloat, use3DTouch: Bool)
    {
        self.threshold = threshold
        self.use3DTouch = use3DTouch
        
        super.init(target: target, action: action)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent)
    {
        if let touch = touches.first
        {
            handleTouch(touch)
        }
        
        super.touchesBegan(touches, withEvent: event)

    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent)
    {
        if let touch = touches.first
        {
            handleTouch(touch)
        }
        
        super.touchesMoved(touches, withEvent: event)

    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent)
    {
        
        state = deepPressed || !use3DTouch ? UIGestureRecognizerState.Ended : UIGestureRecognizerState.Failed
        
        deepPressed = false
        
        super.touchesEnded(touches, withEvent: event)

    }
    
    private func handleTouch(touch: UITouch)
    {
        guard let _ = view where touch.force != 0 && touch.maximumPossibleForce != 0 else
        {
            return
        }

        if !deepPressed && (touch.force / touch.maximumPossibleForce) >= threshold
        {
            if vibrateOnDeepPress
            {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
            
            deepPressed = true
        }
        else if deepPressed && (touch.force / touch.maximumPossibleForce) < threshold
        {
            state = UIGestureRecognizerState.Ended
            
            deepPressed = false
        }
    }
    

}

// MARK: DeepPressable protocol extension

protocol DeepPressable
{
    var gestureRecognizers: [UIGestureRecognizer]? {get set}
    
    func addGestureRecognizer(gestureRecognizer: UIGestureRecognizer)
    func removeGestureRecognizer(gestureRecognizer: UIGestureRecognizer)
    
    func setDeepPressAction(target: AnyObject, action: Selector, use3DTouch: Bool)
    func removeDeepPressAction()
}

extension DeepPressable
{
    func setDeepPressAction(target: AnyObject, action: Selector, use3DTouch: Bool)
    {
        let deepPressGestureRecognizer = DeepPressGestureRecognizer(target: target, action: action, threshold: 1, use3DTouch: use3DTouch)
        
        self.addGestureRecognizer(deepPressGestureRecognizer)
    }
    
    func removeDeepPressAction()
    {
        guard let gestureRecognizers = gestureRecognizers else
        {
            return
        }
        
        for recogniser in gestureRecognizers where recogniser is DeepPressGestureRecognizer
        {
            removeGestureRecognizer(recogniser)
        }
    }
}
