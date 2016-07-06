//
//  Location.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import Foundation
import CoreData

class Location : NSManagedObject {
    
    func setLocationFromSearch(search : SearchLocation) {
        name = search.name
        county = search.county
        country = search.country
        administrativeArea = search.administrativeArea
    }
}