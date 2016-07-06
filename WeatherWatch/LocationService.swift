//
//  LocationService.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import Foundation
import Alamofire
import SWXMLHash

class LocationService {
    
    let SSRIUrl = "https://ws.geonorge.no/SKWS3Index/ssr/sok?"
    
    func locationSearch(text : String, completion : [SearchLocation] -> Void) {
        Alamofire.request(.GET, SSRIUrl + "navn=" + text + "*").validate().response {
            request, response, data, error in
            
            let xml = SWXMLHash.parse(data!)

            var locations = [SearchLocation]()
            let res = xml["sokRes"]
            if res["sokStatus"]["ok"].element?.text == "true" {
                for locXML in res["stedsnavn"].all {
                    let location = SearchLocation(representation: locXML)
                    locations.append(location)
                }
                
                completion(locations)
                
            }

        }
        
    }
    
}
    
