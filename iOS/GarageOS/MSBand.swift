//
//  MSBand.swift
//  GarageOS
//
//  Created by David Washington on 4/15/16.
//  Copyright © 2016 David Washington. All rights reserved.
//

import Foundation

var BAND_TILE_ID =  "38B98C06-ACF0-42EB-8479-EC249E6BF62F"
var BAND_PAGE1_ID =  "035F408A-B15B-4802-9DBB-686E711D35F8"
var BAND_PAGE2_ID =  "495F101B-3368-4501-A7DD-CCE8569F9A9A"

class MSBand: NSObject, MSBClientManagerDelegate {
    
    var bandClient: MSBClient!
    
    required init(bandTileDelegate: MSBClientTileDelegate) {
        super.init()
        
        MSBClientManager.shared().delegate = self
        if let client = MSBClientManager.shared().attachedClients().first as? MSBClient {
            self.bandClient = client
            client.tileDelegate = bandTileDelegate
            MSBClientManager.shared().connect(self.bandClient)
        } else {
            print("Can't connect to MSBand")
        }
    
    }
    
    // Mark - MSBand Client Manager Delegates
    func clientManager(_ clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        print("MSBand Connected")
        
        client.personalizationManager.theme(completionHandler: { (theme, error: Error?) in
            
            let tileName = "GarageOS"
            let tileIcon = try? MSBIcon(uiImage: UIImage(named: "tileIcon.png"))
            let smallIcon = try? MSBIcon(uiImage: UIImage(named: "smallIcon.png"))


            let tileID = NSUUID(uuidString: BAND_TILE_ID)
            let tile = try! MSBTile(id: tileID as UUID!, name: tileName, tileIcon: tileIcon, smallIcon: smallIcon)
            
            let textBlock = MSBPageTextBlock(rect: MSBPageRect(x: 0, y: 0, width: 200, height: 40), font: MSBPageTextBlockFont.small)
            textBlock?.elementId = 10
            textBlock?.color = theme?.highlightColor
            textBlock?.margins = MSBPageMargins(left: 15, top: 5, right: 0, bottom: 0)
            
            let button = MSBPageTextButton(rect: MSBPageRect(x:0, y:0, width:220, height:60))
            button?.elementId = 11
            button?.horizontalAlignment = MSBPageHorizontalAlignment.center
            button?.pressedColor = theme?.highlightColor
            button?.margins = MSBPageMargins(left: 15, top: 5, right: 0, bottom: 0)
            
            
            let flowList = MSBPageFlowPanel(rect: MSBPageRect(x: 15, y: 0, width: 248, height: 128))
            flowList?.addElement(textBlock)
            flowList?.addElement(button)
            
            let page = MSBPageLayout()
            page.root = flowList
            tile.pageLayouts.add(page)
//            
//            client.tileManager.removeTile(tile, completionHandler: { (error: NSError!) in
//                print("deleted that tile")
//            })
            
            client.tileManager.add(tile, completionHandler: { (error: Error?) in
                if error == nil || MSBErrorType(rawValue: error as! Int) == MSBErrorType.tileAlreadyExist {
                    print("Creating page...")
                
                    let a = try! MSBPageTextButtonData(elementId: 11, text: "Small Door")
                    let b = try! MSBPageTextBlockData(elementId: 10, text: "GarageOS")
                    let page1 = MSBPageData(id: NSUUID(uuidString: BAND_PAGE1_ID) as UUID!,         layoutIndex: 0, value: [a,b])
                    
                    let c = try! MSBPageTextButtonData(elementId: 11, text: "Big Door")
                    let d = try! MSBPageTextBlockData(elementId: 10, text: "GarageOS")
                    let page2 = MSBPageData(id: NSUUID(uuidString: BAND_PAGE2_ID) as UUID!,         layoutIndex: 0, value: [c,d])
                    
                    client.tileManager.setPages([page2!, page1!], tileId: tile.tileId, completionHandler: { (error: Error?) in
                        if error != nil {
                            print("Error setting page: \(error!.localizedDescription)")
                        } else {
                            print("Successfully Finished!!!")
                        }
                    })
                } else {
                    print(error?.localizedDescription ?? "")
                }
            })
        })
        
    }
    
    func vibrate() {
        if (self.bandClient == nil) { return }
        
        self.bandClient.notificationManager.vibrate(with: MSBNotificationVibrationType.oneTone) { (err:Error?) in
            if (err == nil) {
                print("vibrated")
            }
        }

    }
    
    func clientManager(_ clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        print("MSBand Disconnected")
        
    }
    
    func clientManager(_ clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: Error!) {
        print("MSBand Can't Connect")
    }
    
    
}



