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
import CoreLocation
import SwiftyJSON

class LocationService {
    
    let SSRIUrl = "https://ws.geonorge.no/SKWS3Index/ssr/sok?"
    let geocodeUrl = "http://api.geonames.org/findNearbyJSON?"
    
    
    func locationSearch(text : String, completion : [SearchLocation] -> Void) {
        let path = "navn=" + text + "*"
        Alamofire.request(.GET, SSRIUrl + path.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!).validate().response {
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
    
    func geocodeSearch(location : CLLocation, placename : CLPlacemark, completion : SearchLocation -> Void) {
        let url = geocodeUrl + "lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&username=mathiaslidal"
        Alamofire.request(.GET, url).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let value):
                let jsonString = JSON(value)
                let geoname = jsonString["geonames"].arrayValue.first!
                let name = geoname["name"].stringValue
                let country = geoname["countryName"].stringValue
                if country == "Norway" {
                    self.locationSearch(name, completion: {
                        locations in
                        completion(locations[0])
                    })
                } else {
                    let location = SearchLocation(name: name, country: country, county: placename.administrativeArea! , administrativeArea: placename.administrativeArea!)
                    completion(location)
                }
            case .Failure(let error):
                print(error)
            }
        }
    }
    
}
    
