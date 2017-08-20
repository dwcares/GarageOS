//
//  ViewController.swift
//  GarageOS
//
//  Created by David Washington on 12/22/15.
//  Copyright © 2015 David Washington. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MSBClientTileDelegate {

    let CAR_STATUS_NOTPARKED = 0;
    let CAR_STATUS_PARKED = 1;
    let CAR_STATUS_PARKEDCLOSE = 2;
    let CAR_STATUS_INVALID = -1;
    
    let CAR1_MAXDISTANCE = 60
    let CAR2_MAXDISTANCE = 60
    
    let CAR1_MINDISTANCE = 40
    let CAR2_MINDISTANCE = 40
    
    var myPhoton : SparkDevice!
    var msBand : MSBand!
    
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
    
    
    var smallDoorButton: DeepPressableButton!
    var bigDoorButton: DeepPressableButton!
    
    func bigDoorDeepPressHandler(_ value: DeepPressGestureRecognizer)
    {
        print("deeppress big")
        toggleDoor(true)
        
    }
    
    func smallDoorDeepPressHandler(_ value: DeepPressGestureRecognizer)
    {
        print("deeppress small")
        
        toggleDoor(false)
        
    }
    
    // Mark - Main UI Logic
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initDeepPressButtons()
        msBand = MSBand(bandTileDelegate: self)
        
        doParticleLogin(){_ in }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.getInitialState), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }

    func initDeepPressButtons() {
        
        let is3DTouchAvailiable = self.traitCollection.forceTouchCapability == UIForceTouchCapability.available
 
        smallDoorButton.setDeepPressAction(self, action: #selector(self.smallDoorDeepPressHandler(_:)), use3DTouch:is3DTouchAvailiable)
        bigDoorButton.setDeepPressAction(self, action: #selector(self.bigDoorDeepPressHandler(_:)), use3DTouch:is3DTouchAvailiable)
    }
  
    func updateDoorStatus(_ doorStatus:Bool, isDoor1:Bool) {
        if (self.smallDoorStatus == nil) { return };
        

        
        if (isDoor1) {
            print("Door 1: \(doorStatus)")
            self.smallDoorStatus.alpha = doorStatus ? 1 : 0.3
        } else {
            print("Door 2: \(doorStatus)")
            self.bigDoorStatus.alpha = doorStatus ? 1 : 0.3
        }
        
        updateBadgeNumber(Int(self.smallDoorStatus.alpha) + Int(self.smallDoorStatus.alpha))
    }
    
    
    func updateCarDistanceInfo(_ carDistance:Int, isCar1:Bool) {
        if (self.smallDoorStatus == nil) { return };

        if (carDistance > CAR1_MAXDISTANCE || carDistance <= 0) {
            self.labelCar1Distance.text = "Not parked"
            self.progressCar1Distance.progress = 0
            
        } else {
            self.labelCar1Distance.text = String(carDistance) + "\""
            
            let boundedProgress = min(max(carDistance,CAR1_MINDISTANCE), CAR1_MAXDISTANCE)
            self.progressCar1Distance.progress = 1 - Float(boundedProgress - CAR1_MINDISTANCE) /
                Float(CAR1_MAXDISTANCE - CAR1_MINDISTANCE)
        }
        
        print("Car 1: \(carDistance) inches")
    }
    
    func updateStatusInfo(_ signalStrength:Int, lastUpdate:String, uptime: Int) {
        if (self.smallDoorStatus == nil) { return };

        self.labelSignal.text = String(signalStrength) + "db"
        self.labelLastUpdate.text = lastUpdate
        
        if (uptime > 0 ) {
            self.labelUptime.text = uptime.msToSeconds.minuteSecondMS
        }

    }
    
    func updateDoorDurationInfo(_ smallDoorDuration:Int, bigDoorDuration:Int) {
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
   
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval)
    {
        if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
        {
            
            labelSignal.isHidden = false
            labelUptime.isHidden = false
            labelLastUpdate.isHidden = false
            labelUISignal.isHidden = false
            labelUIUptime.isHidden = false
            labelUILastUpdate.isHidden = false
            labelSmallDoorDuration.isHidden = false
            labelBigDoorDuration.isHidden = false
        }
        else
        {
            
            labelSignal.isHidden = true
            labelUptime.isHidden = true
            labelLastUpdate.isHidden = true
            labelUISignal.isHidden = true
            labelUIUptime.isHidden = true
            labelUILastUpdate.isHidden = true
            labelSmallDoorDuration.isHidden = true
            labelBigDoorDuration.isHidden = true
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // Mark - Particle device communication
    
    
    func doParticleLogin(_ completion: @escaping (_ result: Bool) -> Void) {
        SparkCloud.sharedInstance().login(withUser: Secrets.particleUser, password: Secrets.particlePassword) { (error:Error?) -> Void in
            if let _=error {
                print("Wrong credentials or no internet connectivity, please try again")
                completion(false)
            }
            else {
                print("Logged in")
                
                self.getDevice(Secrets.particleDeviceID) {
                    (device: SparkDevice?) in
                    
                    self.myPhoton = device
                    self.subscribeToEvents()
                    
                    self.getInitialState()

                    completion(true);

                }
            }
        }
    }
    
    func getDevice(_ id: String, completion: @escaping (_ result: SparkDevice?) -> Void) {
        SparkCloud.sharedInstance().getDevice(id, completion: { (device:SparkDevice?, error:Error?) -> Void in
            if let _ = device {
                completion(device)
            } else {
                completion(nil)
            }
        })
    }
    
    func updateBadgeNumber(_ number: Int) {
        UIApplication.shared.applicationIconBadgeNumber = number

    }
    
    func getInitialState() {
        updateBadgeNumber(0)

        if (self.myPhoton == nil || self.smallDoorStatus == nil) { return; }
        
        self.myPhoton.getVariable("door1Status", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting initial door 1 state")
            }
            else {
                self.updateDoorStatus(result as! Bool, isDoor1: true)
            }
        })
        
        self.myPhoton.getVariable("door2Status", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting initial door 2 state")
            }
            else {
                self.updateDoorStatus(result as! Bool, isDoor1: false)
            }
        })
        
        self.myPhoton.getVariable("car1Distance", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting car 1 distance")
            }
            else {
                self.updateCarDistanceInfo(result as! Int, isCar1: true)
            }
        })
        
        self.myPhoton.getVariable("wifiStrength", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting car 1 distance")
            }
            else {
                self.updateStatusInfo(result as! Int,
                    lastUpdate: self.getTimeStamp(),
                    uptime: 0)
            }
        })
    }
    
    func subscribeToEvents() {
        
        SparkCloud.sharedInstance().subscribeToDeviceEvents(withPrefix: "heartbeat", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'heartbeat' event: \(error)"); return }
            
            print("'heartbeat' event received: \(event)")
            self.onHeartbeat((event?.data)!)
        })
        
        SparkCloud.sharedInstance().subscribeToDeviceEvents(withPrefix: "door-status-change", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'door-status-change' event: \(error)"); return }
            
            print("'door-status-change' event received: \(event)")
            
            self.updateDoorStatus((event?.data.contains("1"))!, isDoor1: (event?.event.contains("door2"))!)
        })
    }
    
    func onHeartbeat(_ data: String) {
        
        do {
            let json = try JSONSerialization.jsonObject(with: data.data(using: String.Encoding.ascii)!, options: .allowFragments) as! [String:AnyObject]
            
            print(json);
            
            DispatchQueue.main.async(execute: {
                if (self.smallDoorStatus != nil) {

                    self.updateCarDistanceInfo(json["car1Distance"] as! Int, isCar1: true)
                    self.updateDoorStatus(json["door1Status"] as! Bool, isDoor1: true)
                    self.updateDoorStatus(json["door2Status"] as! Bool, isDoor1: false)
                    self.updateStatusInfo(json["wifiStrength"] as! Int,
                        lastUpdate: self.getTimeStamp(),
                        uptime: Int(json["uptime"] as! String)!)
                
                    self.updateDoorDurationInfo(json["door1OpenDuration"] as! Int, bigDoorDuration: json["door2OpenDuration"] as! Int)
                }
                
            })
            
        } catch {
            print("error serializing JSON: \(error)")
        }
    }
    
    func toggleDoor(_ isDoor1:Bool) {
        if myPhoton == nil {
            print("Particle not yet loaded")
            
            doParticleLogin(){(result) in // login first
                if (result) { self.doToggleDoor(isDoor1)}
            }

        } else {
            self.doToggleDoor(isDoor1)
        }
    }
    
    func doToggleDoor(_ isDoor1:Bool) {
        let doorNumber = isDoor1 ? "r2" : "r1"
        let funcArgs = [doorNumber]
        
        myPhoton.callFunction("toggleDoor", withArguments: funcArgs) { (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) {
                print("The door is opening")
                if (self.msBand != nil) { self.msBand.vibrate() }
                
            }
        }
    }
    
    func getTimeStamp() -> String {
        return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    }
    
    // MARK - MSBand Client Tile Delegate
    func client(_ client: MSBClient!, buttonDidPress event: MSBTileButtonEvent!) {
        
        if (event.pageId.uuidString == BAND_PAGE1_ID) {
            print("open small from band")
            toggleDoor(false)
        } else {
            print("open big from band")
            toggleDoor(true)
        }
        
        print("\(event.description)")
    }
    
    func client(_ client: MSBClient!, tileDidClose event: MSBTileEvent!) {
        print("\(event.description)")
    }
    
    func client(_ client: MSBClient!, tileDidOpen event: MSBTileEvent!) {
        print("\(event.description)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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



