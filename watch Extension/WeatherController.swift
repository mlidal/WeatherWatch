//
//  WeatherController.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 13/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import WatchKit
import Foundation


class WeatherController: WKInterfaceController {
    @IBOutlet var placename: WKInterfaceLabel!

    @IBOutlet var weatherSymbol: WKInterfaceImage!
    @IBOutlet var temperature: WKInterfaceLabel!
    @IBOutlet var precipitation: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
