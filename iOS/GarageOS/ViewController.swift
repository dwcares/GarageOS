//
//  ViewController.swift
//  GarageOS
//
//  Created by David Washington on 12/22/15.
//  Copyright © 2015 David Washington. All rights reserved.
//

import UIKit

class ViewController: UIViewController, GarageClientDelegate {
    
    @IBOutlet var labelCar1Distance : UILabel!
    @IBOutlet var progressCar1Distance: UIProgressView!
    
    @IBOutlet var labelSignal: UILabel!
    @IBOutlet var labelLastUpdate: UILabel!
    @IBOutlet var labelUptime: UILabel!
    @IBOutlet var labelUISignal: UILabel!
    @IBOutlet var labelUILastUpdate: UILabel!
    @IBOutlet var labelUIUptime: UILabel!
    
    @IBOutlet var smallDoorStatus: UIView!
    @IBOutlet var bigDoorStatus: UIView!
    
    @IBOutlet var labelSmallDoorDuration: UILabel!
    @IBOutlet var labelBigDoorDuration: UILabel!
    
    @objc var smallDoorButton: DeepPressableButton!
    @objc var bigDoorButton: DeepPressableButton!
    
    // Mark - Main UI Logic
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initDeepPressButtons()
        GarageClient.sharedInstance.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.updateBadgeNumber(0)
        
        GarageClient.sharedInstance.getInitialState()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateBadgeNumber(_ number: Int) {
        UIApplication.shared.applicationIconBadgeNumber = number
        
    }
    
    // MARK - GarageClientDelegate Methods
    
    func doorStatusUpdated(_ doorStatus:Bool, isDoor1:Bool) {
        
        DispatchQueue.main.async(execute: {
            if (self.smallDoorStatus == nil) { return };
            
            if (isDoor1) {
                print("Door 1: \(doorStatus)")
                self.smallDoorStatus.alpha = doorStatus ? 1 : 0.3
            } else {
                print("Door 2: \(doorStatus)")
                self.bigDoorStatus.alpha = doorStatus ? 1 : 0.3
            }
            
            self.updateBadgeNumber(Int(self.smallDoorStatus.alpha) + Int(self.smallDoorStatus.alpha))
        })
    }
    
    
    func carDistanceInfoUpdated(_ carDistance:Int, isCar1:Bool) {
        DispatchQueue.main.async(execute: {
            if (self.smallDoorStatus == nil) { return };
            
            if (carDistance > GarageClient.CAR1_MAXDISTANCE || carDistance <= 0) {
                self.labelCar1Distance.text = "Not parked"
                self.progressCar1Distance.progress = 0
                
            } else {
                
                self.labelCar1Distance.text = String(carDistance) + "\""
                
                let boundedProgress = min(max(carDistance,GarageClient.CAR1_MINDISTANCE), GarageClient.CAR1_MAXDISTANCE)
                self.progressCar1Distance.progress = 1 - Float(boundedProgress - GarageClient.CAR1_MINDISTANCE) /
                    Float(GarageClient.CAR1_MAXDISTANCE - GarageClient.CAR1_MINDISTANCE)
            }
            
            print("Car 1: \(carDistance) inches")
            
        })
    }
    
    func statusInfoUpdated(_ signalStrength:Int, lastUpdate:String, uptime: Int) {
        DispatchQueue.main.async(execute: {
            if (self.smallDoorStatus == nil) { return };
            
            self.labelSignal.text = String(signalStrength) + "db"
            self.labelLastUpdate.text = lastUpdate
            
            if (uptime > 0) {
                self.labelUIUptime.isHidden = false
                self.labelUptime.text = uptime.msToSeconds.minuteSecondMS
            } else {
                self.labelUIUptime.isHidden = true
            }
        })
        
    }
    
    func doorDurationInfoUpdated(_ smallDoorDuration:Int, bigDoorDuration:Int) {
        
        DispatchQueue.main.async(execute: {
            
            if (self.smallDoorStatus == nil) { return };
            
            if (smallDoorDuration > 0) {
                self.labelSmallDoorDuration.text = smallDoorDuration.msToSeconds.minuteSecondMS
            } else {
                self.labelSmallDoorDuration.text = ""
            }
            
            if (bigDoorDuration > 0 ) {
                self.labelBigDoorDuration.text = bigDoorDuration.msToSeconds.minuteSecondMS
            } else  {
                self.labelBigDoorDuration.text = ""
            }
            
        })
        
    }
    
    // MARK - Deep Press Action
    
    @objc func bigDoorDeepPressHandler(_ value: DeepPressGestureRecognizer)
    {
        print("Deep Press: Big Door")
        GarageClient.sharedInstance.doToggleDoor(true)
        
    }
    
    @objc func smallDoorDeepPressHandler(_ value: DeepPressGestureRecognizer)
    {
        print("Deep Press: Small Door")
        GarageClient.sharedInstance.doToggleDoor(false)
        
    }
    
    func initDeepPressButtons() {
        let is3DTouchAvailiable = self.traitCollection.forceTouchCapability == UIForceTouchCapability.available
        
        smallDoorButton.setDeepPressAction(self, action: #selector(self.smallDoorDeepPressHandler(_:)), use3DTouch:is3DTouchAvailiable)
        bigDoorButton.setDeepPressAction(self, action: #selector(self.bigDoorDeepPressHandler(_:)), use3DTouch:is3DTouchAvailiable)
    }

    
}


extension TimeInterval {
    var minuteSecondMS: String {
        return String(format:"%02d:%02d:%02d", hour, minute, second)
    }
    
    var hourMins: String {
        return String(format:"%02d:%02d", hour, minute)
    }
    
    var hour: Int {
        return Int((self/60.0/60.0).truncatingRemainder(dividingBy: 60))
    }
    
    var minute: Int {
        return Int((self/60.0).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        return Int(self.truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        return Int((self*1000).truncatingRemainder(dividingBy: 1000) )
    }
}

extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}



