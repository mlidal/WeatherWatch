//
//  SearchLocation.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import Foundation
import SWXMLHash
import CoreLocation
import SwiftyJSON

class SearchLocation : Hashable {
    
    let name: String
    let country: String
    let county: String
    let administrativeArea: String
    let type : String
    
    init(representation : XMLIndexer) {
        name = representation["stedsnavn"].element!.text!
        county = representation["fylkesnavn"].element!.text!
        administrativeArea = SearchLocation.trimCountyName(representation["kommunenavn"].element!.text!)
        country = "Norway"
        type = representation["navnetype"].element!.text!
    }
 
    init(name : String, country : String, county : String, administrativeArea : String = "", type: String) {
        self.name = name
        self.county = county
        self.country = country
        self.administrativeArea = administrativeArea
        self.type = type
    }
    
    private static func trimCountyName(name : String) -> String {
        let regex =  try! NSRegularExpression(pattern: " \\(\\w*\\)", options: .CaseInsensitive)
        return regex.stringByReplacingMatchesInString(name, options: [], range: NSMakeRange(0, name.characters.count), withTemplate: "")
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

