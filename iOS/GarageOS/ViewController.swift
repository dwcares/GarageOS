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
    
    @IBOutlet var smallDoorButton: UIButton!
    @IBOutlet var bigDoorButton: UIButton!

    private let haptic = UINotificationFeedbackGenerator()

    // Mark - Main UI Logic
    override func viewDidLoad() {
        super.viewDidLoad()

        initDoorButtons()
        haptic.prepare()
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
                self.smallDoorStatus.alpha = doorStatus ? 1 : 0.3
            } else {
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

        })
    }

    func statusInfoUpdated(_ signalStrength:Int, lastUpdate:String, uptime: Int) {
        DispatchQueue.main.async(execute: {
            if (self.smallDoorStatus == nil) { return };

            self.updateSignalDisplay(signalStrength)
            self.labelLastUpdate.text = lastUpdate

            if (uptime > 0) {
                self.labelUIUptime.isHidden = false
                self.labelUptime.text = uptime.msToSeconds.minuteSecondMS
            } else {
                self.labelUIUptime.isHidden = true
            }
        })

    }

    func updateSignalDisplay(_ rssi: Int) {
        // RSSI ranges: > -50 excellent, -50 to -60 good, -60 to -70 fair, < -70 weak
        let symbolName: String
        if rssi > -50 {
            symbolName = "wifi"                    // Full
        } else if rssi > -60 {
            symbolName = "wifi"                    // Good (full icon, we'll tint)
        } else if rssi > -70 {
            symbolName = "wifi.exclamationmark"    // Fair
        } else {
            symbolName = "wifi.slash"              // Weak/bad
        }

        let tintColor: UIColor
        if rssi > -50 {
            tintColor = .systemBlue
        } else if rssi > -60 {
            tintColor = .systemBlue
        } else if rssi > -70 {
            tintColor = .systemOrange
        } else {
            tintColor = .systemRed
        }

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let image = UIImage(systemName: symbolName, withConfiguration: config) {
            let attachment = NSTextAttachment()
            attachment.image = image.withTintColor(tintColor, renderingMode: .alwaysOriginal)

            let attributedString = NSMutableAttributedString(attachment: attachment)
            attributedString.append(NSAttributedString(string: " \(rssi)db", attributes: [
                .foregroundColor: tintColor,
                .font: self.labelSignal.font ?? UIFont.systemFont(ofSize: 14)
            ]))

            self.labelSignal.attributedText = attributedString
        }
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
    
    // MARK - Door Actions

    @objc func bigDoorLongPressHandler(_ gesture: UILongPressGestureRecognizer)
    {
        if gesture.state == .began {
            haptic.notificationOccurred(.success)
            haptic.prepare()
            GarageClient.sharedInstance.doToggleDoor(true)
        }
    }

    @objc func smallDoorLongPressHandler(_ gesture: UILongPressGestureRecognizer)
    {
        if gesture.state == .began {
            haptic.notificationOccurred(.success)
            haptic.prepare()
            GarageClient.sharedInstance.doToggleDoor(false)
        }
    }

    func initDoorButtons() {
        let smallPress = UILongPressGestureRecognizer(target: self, action: #selector(smallDoorLongPressHandler(_:)))
        smallPress.minimumPressDuration = 0.5
        smallDoorButton.addGestureRecognizer(smallPress)

        let bigPress = UILongPressGestureRecognizer(target: self, action: #selector(bigDoorLongPressHandler(_:)))
        bigPress.minimumPressDuration = 0.5
        bigDoorButton.addGestureRecognizer(bigPress)
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



