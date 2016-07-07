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

class SearchLocation {
    
    let name: String
    let country: String
    let county: String
    let administrativeArea: String
    
    init(representation : XMLIndexer) {
        name = representation["stedsnavn"].element!.text!
        county = representation["fylkesnavn"].element!.text!
        administrativeArea = SearchLocation.trimCountyName(representation["kommunenavn"].element!.text!)
        country = "Norway"
    }
 
    
    private static func trimCountyName(name : String) -> String {
        let regex =  try! NSRegularExpression(pattern: " \\(\\w*\\)", options: .CaseInsensitive)
        return regex.stringByReplacingMatchesInString(name, options: [], range: NSMakeRange(0, name.characters.count), withTemplate: "")
    }
}