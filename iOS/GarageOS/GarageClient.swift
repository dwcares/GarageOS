//
//  GarageClient.swift
//  GarageOS
//
//  Created by Washington Family on 9/2/17.
//  Copyright © 2017 David Washington. All rights reserved.
//

import Foundation

protocol GarageClientDelegate: AnyObject {

    func doorStatusUpdated(_ doorStatus: Bool, isDoor1: Bool)
    func carDistanceInfoUpdated(_ carDistance: Int, isCar1: Bool)
    func statusInfoUpdated(_ signalStrength: Int, lastUpdate: String, uptime: Int)
    func doorDurationInfoUpdated(_ smallDoorDuration: Int, bigDoorDuration: Int)

}

class GarageClient: NSObject {

    static let sharedInstance = GarageClient()

    public static let CAR_STATUS_NOTPARKED = 0
    public static let CAR_STATUS_PARKED = 1
    public static let CAR_STATUS_PARKEDCLOSE = 2
    public static let CAR_STATUS_INVALID = -1

    public static let CAR1_MAXDISTANCE = 60
    public static let CAR2_MAXDISTANCE = 60

    public static let CAR1_MINDISTANCE = 40
    public static let CAR2_MINDISTANCE = 40

    weak var delegate: GarageClientDelegate?
    var myPhoton: ParticleDevice?
    var smallDoorOpen: Bool = false
    var bigDoorOpen: Bool = false

    // Callback for watch status updates
    var onDoorStatusChanged: (() -> Void)?

    override init() {
        super.init()

        doParticleLogin { _ in }

    }


    func doParticleLogin(_ completion: @escaping (_ result: Bool) -> Void) {
        ParticleCloud.sharedInstance().login(withUser: Secrets.particleUser, password: Secrets.particlePassword) { (error: Error?) -> Void in
            if let _ = error {
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

                    completion(true)

                }
            }
        }
    }

    func getDevice(_ id: String, completion: @escaping (_ result: ParticleDevice?) -> Void) {
        ParticleCloud.sharedInstance().getDevice(id, completion: { (device: ParticleDevice?, error: Error?) -> Void in
            if let _ = device {
                completion(device)
            } else {
                completion(nil)
            }
        })
    }



    func getInitialState() {
        guard let myPhoton = self.myPhoton else { return }

        myPhoton.getVariable("door1Status", completion: {
            (result: Any?, error: Error?) -> Void in
            if error != nil {
                print("Failed getting initial door 1 state")
            }
            else {
                if let status = result as? Bool {
                    self.smallDoorOpen = status
                    self.delegate?.doorStatusUpdated(status, isDoor1: true)
                    self.onDoorStatusChanged?()
                }
            }
        })

        myPhoton.getVariable("door2Status", completion: {
            (result: Any?, error: Error?) -> Void in
            if error != nil {
                print("Failed getting initial door 2 state")
            }
            else {
                if let status = result as? Bool {
                    self.bigDoorOpen = status
                    self.delegate?.doorStatusUpdated(status, isDoor1: false)
                    self.onDoorStatusChanged?()
                }
            }
        })

        myPhoton.getVariable("car1Distance", completion: {
            (result: Any?, error: Error?) -> Void in
            if error != nil {
                print("Failed getting car 1 distance")
            }
            else {
                if let distance = result as? Int {
                    self.delegate?.carDistanceInfoUpdated(distance, isCar1: true)
                }
            }
        })

        myPhoton.getVariable("wifiStrength", completion: {
            (result: Any?, error: Error?) -> Void in
            if error != nil {
                print("Failed getting wifi strength")
            }
            else {
                if let strength = result as? Int {
                    self.delegate?.statusInfoUpdated(strength,
                                          lastUpdate: self.getTimeStamp(),
                                          uptime: 0)
                }
            }
        })
    }

    func subscribeToEvents() {

        ParticleCloud.sharedInstance().subscribeToDeviceEvents(withPrefix: "heartbeat", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'heartbeat' event: \(error!)"); return }

            print("'heartbeat' event received: \(String(describing: event))")
            if let data = event?.data {
                self.onHeartbeat(data)
            }
        })

        ParticleCloud.sharedInstance().subscribeToDeviceEvents(withPrefix: "door-status-change", deviceID: Secrets.particleDeviceID, handler: { (event, error) in
            guard error == nil else { NSLog("Error subscribing to 'door-status-change' event: \(error!)"); return }

            print("'door-status-change' event received: \(String(describing: event))")

            if let data = event?.data, let eventName = event?.event {
                let isOpen = data.contains("1")
                let isDoor1 = eventName.contains("door2")
                // isDoor1=true means small door in the delegate/UI convention
                if isDoor1 {
                    self.smallDoorOpen = isOpen
                } else {
                    self.bigDoorOpen = isOpen
                }
                self.delegate?.doorStatusUpdated(isOpen, isDoor1: isDoor1)
                self.onDoorStatusChanged?()
            }
        })
    }

    func onHeartbeat(_ data: String) {

        do {
            guard let jsonData = data.data(using: .ascii) else { return }
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed) as? [String: Any] ?? [:]

            print(json)

            if let carDistance = json["car1Distance"] as? Int {
                self.delegate?.carDistanceInfoUpdated(carDistance, isCar1: true)
            }
            if let door1Status = json["door1Status"] as? Bool {
                self.smallDoorOpen = door1Status
                self.delegate?.doorStatusUpdated(door1Status, isDoor1: true)
                self.onDoorStatusChanged?()
            }
            if let door2Status = json["door2Status"] as? Bool {
                self.bigDoorOpen = door2Status
                self.delegate?.doorStatusUpdated(door2Status, isDoor1: false)
                self.onDoorStatusChanged?()
            }
            if let wifiStrength = json["wifiStrength"] as? Int {
                let uptime = (json["uptime"] as? String).flatMap { Int($0) } ?? 0
                self.delegate?.statusInfoUpdated(wifiStrength,
                                                lastUpdate: self.getTimeStamp(),
                                                uptime: uptime)
            }

            if let door1Duration = json["door1OpenDuration"] as? Int,
               let door2Duration = json["door2OpenDuration"] as? Int {
                self.delegate?.doorDurationInfoUpdated(door1Duration, bigDoorDuration: door2Duration)
            }


        } catch {
            print("error serializing JSON: \(error)")
        }
    }

    func doToggleDoor(_ isDoor1: Bool) {
        let doorNumber = isDoor1 ? "r2" : "r1"
        let funcArgs = [doorNumber]

        myPhoton?.callFunction("toggleDoor", withArguments: funcArgs) { (resultCode: NSNumber?, error: Error?) -> Void in
            if (error == nil) {
                print("The door is opening")

            }
        }
    }

    func getTimeStamp() -> String {
        return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    }


}
