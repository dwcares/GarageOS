//
//  InterfaceController.swift
//  garageoswatch Extension
//
//  Created by Washington Family on 6/14/18.
//  Copyright © 2018 David Washington. All rights reserved.
//

import WatchKit
import Foundation
import ParticleSwift

var particleCloud : ParticleCloud?

class InterfaceController: WKInterfaceController {
    
    @IBAction func bigDoorAction() {
        print("Big Door!")
        doToggleDoor(true)
    }
    
    @IBAction func smallDoorAction() {
        print("Small Door!")
        doToggleDoor(false)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        
        if (particleCloud == nil) {
            particleCloud = ParticleCloud(secureStorage: self)
        }
        getDoorState(true)

        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func doToggleDoor(_ isDoor1:Bool) {
        let doorNumber = isDoor1 ? "r2" : "r1"
        
        particleCloud?.callFunction("toggleDoor", deviceID: Secrets.particleDeviceID, argument: doorNumber) { (result) in
            switch result {
            case .success:
                print("success")
                break
            case .failure(_):
                print("fail")
                break
            }
        }
    }
    
    func getDoorState(_ isDoor1:Bool) {
        
        let doorVariableName = isDoor1 ? "door1Status" : "door2Status"
        
        particleCloud?.variableValue(doorVariableName, deviceID: Secrets.particleDeviceID, completion: { (result) in
            switch result {
            case .success(let doorState):
                print(doorState["result"] as! Bool)
                break
            case .failure(_):
                print("fail")
                break
            }
        })
    }

}
/// MARK: - SecureStorage
///
/// This is for illustrative purposes only.  Use security coding techniques for real applications
extension InterfaceController: SecureStorage {
    
    /// Callback to obtain the user name
    func username(_ realm: String) -> String? {
        return Secrets.particleUser
    }
    
    /// Callback to obtain the user's pasword
    func password(_ realm: String) -> String? {
        return Secrets.particlePassword
    }
    
    /// The oauth client identifier to use.  Use "particle" for regular particle cloud accounts
    func oauthClientId(_ realm: String) -> String? {
        return "particle"
    }
    
    /// The oauth client secret to use.  Use "particle" for regular particle cloud accounts
    func oauthClientSecret(_ realm: String) -> String? {
        return "particle"
    }
    
    /// Called to obtain a persisted token.  Persisted tokens are strongly preferred to minimize the
    /// number of authentication calls.
    func oauthToken(_ realm: String) -> OAuthToken? {
        
        if let data = UserDefaults.standard.data(forKey: "ParticleToken") {
            do {
                return try JSONDecoder().decode(OAuthToken.self, from: data)
            } catch {
                /// Some sort of decoding error.  Remove the invalid value
                UserDefaults.standard.removeObject(forKey: "ParticleToken")
                return nil
            }
        }
        /// No known or valid token.  Return nil
        return nil
    }
    
    /// Method is called back to obtain an existing token.  The realm from ParticleSwift will be
    /// "ParticleSwift".  Realm is only relevant for applications that re-use the SecureStorage
    /// protocol for multiple OAuth endpoints.  This would be extremely rare.
    ///
    /// Tokens should be persisted and reused across application launches.  Expired or invalid tokens will be
    /// destroyed and new tokens created automatically
    func updateOAuthToken(_ token: OAuthToken?, forRealm realm: String) {
        
        guard let token = token else {
            /// An invalid or expired will be purged by calling this method with nil as the token.
            /// Remove any previously stored token
            UserDefaults.standard.removeObject(forKey: "ParticleToken")
            return
        }
        
        /// OAuthToken is Codable, so we can persist it to Data for storage in UserDefaults.
        /// Real applications should store in the keychain rather than UserDefaults
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(token) {
            UserDefaults.standard.set(data, forKey: "ParticleToken")
        }
    }
    
    
}

