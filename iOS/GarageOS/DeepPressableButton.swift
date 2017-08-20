//
//  DeepPressableButton.swift
//  GarageOS
//
//  Created by David Washington on 4/15/16.
//  Copyright © 2016 David Washington. All rights reserved.
//

import Foundation

class DeepPressableButton: UIButton, DeepPressable
{
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            print("% Touch pressure: \(touch.force/touch.maximumPossibleForce)")
            print("% shadow: \(3 - 3*(touch.force/touch.maximumPossibleForce))")
            self.layer.shadowOffset = CGSize(width: 0, height: 3 - 3*(touch.force/touch.maximumPossibleForce))
            self.layer.shadowOpacity = 1 - 0.8*Float(touch.force/touch.maximumPossibleForce)
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touches End")
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.shadowOpacity = 0.8
        super.touchesEnded(touches, with: event)
        
        
    }
    
    
    override internal func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 2.0
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
    }
    
    
    
    
    
}
