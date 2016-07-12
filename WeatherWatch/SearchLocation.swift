//
//  SearchLocation.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import Foundation

class SearchLocation : Hashable {

    let name: String
    let country: String
    let county: String
    let administrativeArea: String
    let type : String
 
    init(name : String, country : String, county : String, administrativeArea : String = "", type: String) {
        self.name = name
        self.county = county
        self.country = country
        self.administrativeArea = administrativeArea
        self.type = type
    }
    
    
    
    var hashValue: Int {
        get {
            return (name + country + county + administrativeArea).hashValue
        }
    }
    
    func priorityType() -> Bool {
        return type == "city, village,..." || type == "Tettsted" || type == "By"
    }
}

func ==(lhs: SearchLocation, rhs: SearchLocation) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

