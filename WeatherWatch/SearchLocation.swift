//
//  SearchLocation.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import Foundation
import SWXMLHash

class SearchLocation {
    
    let name: String
    let country: String
    let county: String
    let administrativeArea: String
    
    init(representation : XMLIndexer) {
        name = representation["stedsnavn"].element!.text!
        county = representation["fylkesnavn"].element!.text!
        administrativeArea = representation["kommunenavn"].element!.text!
        country = "Norway"
    }

}