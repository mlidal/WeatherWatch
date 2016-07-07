//
//  WeatherService.swift
//  
//  HTTP service class for connection to yr.no API, to download weather data
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import Foundation
import Alamofire
import SWXMLHash

class WeatherService {
    
    let baseUrl = "https://www.yr.no/stad/"
    
    func getWeather(location : Location, completion : Weather? -> Void) {
        var path = location.country! + "/"
        path += location.county! + "/"
        if location.administrativeArea != nil {
            
            path += location.administrativeArea! + "/"
        }
        
        if location.country == "Norway" || (location.administrativeArea == nil || location.administrativeArea != location.name) {
            path += location.name! + "/"
        }
        
        path += "varsel.xml"
        
        Alamofire.request(.GET, baseUrl + path.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!).validate().response() {
            request, response, data, error in
            
            let xml = SWXMLHash.parse(data!)
            
            if xml["weatherdata"].element != nil {
                let weather = Weather(input: xml["weatherdata"])
                completion(weather)
            } else {
                completion(nil)
            }
        }
    }
}