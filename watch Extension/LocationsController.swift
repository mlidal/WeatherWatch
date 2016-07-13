//
//  LocationsController.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 13/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import WatchKit
import Foundation


class LocationsController: WKInterfaceController {

    let locations = ["Bergen", "Oslo", "London", "Tokyo"]
    
    @IBOutlet var locationsTable: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        locationsTable.setNumberOfRows(locations.count, withRowType: "LocationRow")
        for (index, location) in locations.enumerate() {
            let controller = locationsTable.rowControllerAtIndex(index) as! LocationRow
            controller.name.setText(location)
        }
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