//
//  InterfaceController.swift
//  garageoswatch Extension
//
//  Created by Washington Family on 6/14/18.
//  Copyright © 2018 David Washington. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBAction func bigDoorAction() {
        print("Big Door!")
        // TODO: Re-implement with updated Particle SDK or WatchConnectivity
    }

    @IBAction func smallDoorAction() {
        print("Small Door!")
        // TODO: Re-implement with updated Particle SDK or WatchConnectivity
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        // Configure interface objects here.
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

}
