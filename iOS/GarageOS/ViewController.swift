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
    
    func bigDoorDeepPressHandler(value: DeepPressGestureRecognizer)
    {
        print("deeppress big")
        toggleDoor(true)
        
    }
    
    func smallDoorDeepPressHandler(value: DeepPressGestureRecognizer)
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.getInitialState), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func initDeepPressButtons() {
        
        let is3DTouchAvailiable = self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available
 
        smallDoorButton.setDeepPressAction(self, action: #selector(self.smallDoorDeepPressHandler(_:)), use3DTouch:is3DTouchAvailiable)
        bigDoorButton.setDeepPressAction(self, action: #selector(self.bigDoorDeepPressHandler(_:)), use3DTouch:is3DTouchAvailiable)
    }
  
    func updateDoorStatus(doorStatus:Bool, isDoor1:Bool) {
        if (self.smallDoorStatus == nil) { return };
        
        if (isDoor1) {
            print("Door 1: \(doorStatus)")
            self.smallDoorStatus.alpha = doorStatus ? 1 : 0.3
        } else {
            print("Door 2: \(doorStatus)")
            self.bigDoorStatus.alpha = doorStatus ? 1 : 0.3
        }
    }
    
    
    func updateCarDistanceInfo(carDistance:Int, isCar1:Bool) {
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
    
    func updateStatusInfo(signalStrength:Int, lastUpdate:String, uptime: Int) {
        if (self.smallDoorStatus == nil) { return };

        self.labelSignal.text = String(signalStrength) + "db"
        self.labelLastUpdate.text = lastUpdate
        
        if (uptime > 0 ) {
            self.labelUptime.text = uptime.msToSeconds.minuteSecondMS
        }

    }
    
    func updateDoorDurationInfo(smallDoorDuration:Int, bigDoorDuration:Int) {
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
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval)
    {
        if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
        {
            
            labelSignal.hidden = false
            labelUptime.hidden = false
            labelLastUpdate.hidden = false
            labelUISignal.hidden = false
            labelUIUptime.hidden = false
            labelUILastUpdate.hidden = false
            labelSmallDoorDuration.hidden = false
            labelBigDoorDuration.hidden = false
        }
        else
        {
            
            labelSignal.hidden = true
            labelUptime.hidden = true
            labelLastUpdate.hidden = true
            labelUISignal.hidden = true
            labelUIUptime.hidden = true
            labelUILastUpdate.hidden = true
            labelSmallDoorDuration.hidden = true
            labelBigDoorDuration.hidden = true
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // Mark - Particle device communication
    
    
    func doParticleLogin(completion: (result: Bool) -> Void) {
        SparkCloud.sharedInstance().loginWithUser(Secrets.particleUser, password: Secrets.particlePassword) { (error:NSError!) -> Void in
            if let _=error {
                print("Wrong credentials or no internet connectivity, please try again")
                completion(result: false)
            }
            else {
                print("Logged in")
                
                self.getDevice(Secrets.particleDeviceID) {
                    (device: SparkDevice?) in
                    
                    self.myPhoton = device
                    self.subscribeToEvents()
                    
                    self.getInitialState()

                    completion(result: true);

                }
            }
        }
    }
    
    func getDevice(id: String, completion: (result: SparkDevice?) -> Void) {
        SparkCloud.sharedInstance().getDevice(id, completion: { (device:SparkDevice!, error:NSError!) -> Void in
            if let _ = device {
                completion(result: device)
            } else {
                completion(result: nil)
            }
        })
    }
    
    func getInitialState() {
        if (self.myPhoton == nil || self.smallDoorStatus == nil) { return; }
        
        self.myPhoton.getVariable("door1Status", completion: {
            (result: AnyObject?, error:NSError?) -> Void in
            if error != nil {
                print("Failed getting initial door 1 state")
            }
            else {
                self.updateDoorStatus(result as! Bool, isDoor1: true)
            }
        })
        
        self.myPhoton.getVariable("door2Status", completion: {
            (result: AnyObject?, error:NSError?) -> Void in
            if error != nil {
                print("Failed getting initial door 2 state")
            }
            else {
                self.updateDoorStatus(result as! Bool, isDoor1: false)
            }
        })
        
        self.myPhoton.getVariable("car1Distance", completion: {
            (result: AnyObject?, error:NSError?) -> Void in
            if error != nil {
                print("Failed getting car 1 distance")
            }
            else {
                self.updateCarDistanceInfo(result as! Int, isCar1: true)
            }
        })
        
        self.myPhoton.getVariable("wifiStrength", completion: {
            (result: AnyObject?, error:NSError?) -> Void in
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
        
        SparkCloud.sharedInstance().subscribeToDeviceEventsWithPrefix("heartbeat", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'heartbeat' event: \(error)"); return }
            
            print("'heartbeat' event received: \(event)")
            self.onHeartbeat(event.data)
        })
        
        SparkCloud.sharedInstance().subscribeToDeviceEventsWithPrefix("door-status-change", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'door-status-change' event: \(error)"); return }
            
            print("'door-status-change' event received: \(event)")
            
            self.updateDoorStatus((event.data.containsString("1")), isDoor1: event.event.containsString("door2"))
        })
    }
    
    func onHeartbeat(data: String) {
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data.dataUsingEncoding(NSASCIIStringEncoding)!, options: .AllowFragments)
            
            print(json);
            
            dispatch_async(dispatch_get_main_queue(), {
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
    
    func toggleDoor(isDoor1:Bool) {
        if myPhoton == nil {
            print("Particle not yet loaded")
            
            doParticleLogin(){(result) in // login first
                if (result) { self.doToggleDoor(isDoor1)}
            }

        } else {
            self.doToggleDoor(isDoor1)
        }
    }
    
    func doToggleDoor(isDoor1:Bool) {
        let doorNumber = isDoor1 ? "r2" : "r1"
        let funcArgs = [doorNumber]
        
        myPhoton.callFunction("toggleDoor", withArguments: funcArgs) { (resultCode : NSNumber!, error : NSError!) -> Void in
            if (error == nil) {
                print("The door is opening")
                if (self.msBand != nil) { self.msBand.vibrate() }
                
            }
        }
    }
    
    func getTimeStamp() -> String {
        return NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .NoStyle, timeStyle: .MediumStyle)
    }
    
    // MARK - MSBand Client Tile Delegate
    func client(client: MSBClient!, buttonDidPress event: MSBTileButtonEvent!) {
        
        if (event.pageId.UUIDString == BAND_PAGE1_ID) {
            print("open small from band")
            toggleDoor(false)
        } else {
            print("open big from band")
            toggleDoor(true)
        }
        
        print("\(event.description)")
    }
    
    func client(client: MSBClient!, tileDidClose event: MSBTileEvent!) {
        print("\(event.description)")
    }
    
    func client(client: MSBClient!, tileDidOpen event: MSBTileEvent!) {
        print("\(event.description)")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}


extension NSTimeInterval {
    var minuteSecondMS: String {
        return String(format:"%02d:%02d:%02d", hour, minute, second)
    }
    
    var hourMins: String {
        return String(format:"%02d:%02d", hour, minute)
    }

    var hour: Int {
        return Int(self/60.0/60.0 % 60)
    }
    
    var minute: Int {
        return Int(self/60.0 % 60)
    }
    var second: Int {
        return Int(self % 60)
    }
    var millisecond: Int {
        return Int(self*1000 % 1000 )
    }
}

extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}



