//
//  GarageClient.swift
//  GarageOS
//
//  Created by Washington Family on 9/2/17.
//  Copyright © 2017 David Washington. All rights reserved.
//

import Foundation

protocol GarageClientDelegate: class {
    
    func doorStatusUpdated(_ doorStatus:Bool, isDoor1: Bool)
    func carDistanceInfoUpdated(_ carDistance:Int, isCar1:Bool)
    func statusInfoUpdated(_ signalStrength:Int, lastUpdate:String, uptime: Int)
    func doorDurationInfoUpdated(_ smallDoorDuration:Int, bigDoorDuration:Int)

}

class GarageClient: NSObject {
    
    static let sharedInstance = GarageClient()
    
    public static let CAR_STATUS_NOTPARKED = 0;
    public static let CAR_STATUS_PARKED = 1;
    public static let CAR_STATUS_PARKEDCLOSE = 2;
    public static let CAR_STATUS_INVALID = -1;
    
    public static let CAR1_MAXDISTANCE = 60
    public static let CAR2_MAXDISTANCE = 60
    
    public static let CAR1_MINDISTANCE = 40
    public static let CAR2_MINDISTANCE = 40
    
    var delegate : GarageClientDelegate!
    var myPhoton : ParticleDevice!
    
    override init() {
        super.init()
        
        doParticleLogin(){_ in }

    }
    
    
    func doParticleLogin(_ completion: @escaping (_ result: Bool) -> Void) {
        ParticleCloud.sharedInstance().login(withUser: Secrets.particleUser, password: Secrets.particlePassword) { (error:Error?) -> Void in
            if let _=error {
                print("Wrong credentials or no internet connectivity, please try again")
                completion(false)
            }
            else {
                print("Logged in")
                
                self.getDevice(Secrets.particleDeviceID) {
                    (device: ParticleDevice?) in
                    
                    self.myPhoton = device
                    self.subscribeToEvents()
                    
                    self.getInitialState()
                    
                    completion(true);
                    
                }
            }
        }
    }
    
    func getDevice(_ id: String, completion: @escaping (_ result: ParticleDevice?) -> Void) {
        ParticleCloud.sharedInstance().getDevice(id, completion: { (device:ParticleDevice?, error:Error?) -> Void in
            if let _ = device {
                completion(device)
            } else {
                completion(nil)
            }
        })
    }
    

    
    func getInitialState() {        
        if (self.myPhoton == nil) { return; }
        
        self.myPhoton.getVariable("door1Status", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting initial door 1 state")
            }
            else {
                self.delegate.doorStatusUpdated(result as! Bool, isDoor1: true)
            }
        })
        
        self.myPhoton.getVariable("door2Status", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting initial door 2 state")
            }
            else {
                self.delegate.doorStatusUpdated(result as! Bool, isDoor1: false)
            }
        })
        
        self.myPhoton.getVariable("car1Distance", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting car 1 distance")
            }
            else {
                self.delegate.carDistanceInfoUpdated(result as! Int, isCar1: true)
            }
        })
        
        self.myPhoton.getVariable("wifiStrength", completion: {
            (result: Any?, error:Error?) -> Void in
            if error != nil {
                print("Failed getting car 1 distance")
            }
            else {
                self.delegate.statusInfoUpdated(result as! Int,
                                      lastUpdate: self.getTimeStamp(),
                                      uptime: 0)
            }
        })
    }
    
    func subscribeToEvents() {
        
        ParticleCloud.sharedInstance().subscribeToDeviceEvents(withPrefix: "heartbeat", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'heartbeat' event: \(error!)"); return }
            
            print("'heartbeat' event received: \(event!)")
            self.onHeartbeat((event?.data)!)
        })
        
        ParticleCloud.sharedInstance().subscribeToDeviceEvents(withPrefix: "door-status-change", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'door-status-change' event: \(error!)"); return }
            
            print("'door-status-change' event received: \(event!)")
            
            self.delegate.doorStatusUpdated((event?.data?.contains("1"))!, isDoor1: (event?.event.contains("door2"))!)
        })
    }
    
    func onHeartbeat(_ data: String) {
        
        do {
            let json = try JSONSerialization.jsonObject(with: data.data(using: String.Encoding.ascii)!, options: .allowFragments) as! [String:AnyObject]
            
            print(json);
            
            
            self.delegate.carDistanceInfoUpdated(json["car1Distance"] as! Int, isCar1: true)
            self.delegate.doorStatusUpdated(json["door1Status"] as! Bool, isDoor1: true)
            self.delegate.doorStatusUpdated(json["door2Status"] as! Bool, isDoor1: false)
            self.delegate.statusInfoUpdated(json["wifiStrength"] as! Int,
                                            lastUpdate: self.getTimeStamp(),
                                            uptime: Int(json["uptime"] as! String)!)
            
            self.delegate.doorDurationInfoUpdated(json["door1OpenDuration"] as! Int, bigDoorDuration: json["door2OpenDuration"] as! Int)
            
            
        } catch {
            print("error serializing JSON: \(error)")
        }
    }
    
    func doToggleDoor(_ isDoor1:Bool) {
        let doorNumber = isDoor1 ? "r2" : "r1"
        let funcArgs = [doorNumber]
        
        myPhoton.callFunction("toggleDoor", withArguments: funcArgs) { (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) {
                print("The door is opening")
                
            }
        }
    }
    
    func getTimeStamp() -> String {
        return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    }
    
    
}
    
