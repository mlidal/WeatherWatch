//
//  LocationService.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import UIKit
import Alamofire
import SWXMLHash
import CoreLocation
import SwiftyJSON
import CoreData

class LocationService {
    
    static let sharedService = LocationService()
    
    private init() {}
    
    var currentLocation : Location?
    lazy var geonamesUsername : String = {
        let bundle = NSBundle.mainBundle()
        let geonamesUsername = bundle.infoDictionary!["geonames username"] as! String
        return geonamesUsername
    }()
    
    
    let SSRIUrl = "https://ws.geonorge.no/SKWS3Index/ssr/sok?"
    let geonamesSearchUrl = "http://api.geonames.org/searchJSON?"
    let geocodeUrl = "http://api.geonames.org/findNearbyJSON?"
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    let group = dispatch_group_create()
    
    func locationSearch(text : String, onlyNorway : Bool = true, completion : [SearchLocation] -> Void) {
        var path = "navn=" + text + "*&maxAnt=10"
        var locations = Set<SearchLocation>()
        
        dispatch_group_enter(self.group)
        
        Alamofire.request(.GET, SSRIUrl + path.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!).validate().response(queue: queue) {
            request, response, data, error in
            
            let xml = SWXMLHash.parse(data!)
            let res = xml["sokRes"]
            if res["sokStatus"]["ok"].element?.text == "true" {
                for locXML in res["stedsnavn"].all {
                    
                    let location = self.createSearchLocation(locXML)
                    locations.insert(location)
                }
            }
            dispatch_group_leave(self.group)
        }
        
        if !onlyNorway {
            dispatch_group_enter(self.group)
            path = "name_startsWith=\(text)&maxRows=10&username=\(geonamesUsername)"
            Alamofire.request(.GET, geonamesSearchUrl + path.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!).validate().responseJSON(queue: queue) {
                response in
                switch response.result {
                case .Success(let value):
                    let jsonString = JSON(value)
                    for geoname in jsonString["geonames"].arrayValue {
                        let name = geoname["name"].stringValue
                        let country = geoname["countryName"].stringValue
                        let county = geoname["adminName1"].stringValue
                        let type = geoname["fclName"].stringValue
                        let result = SearchLocation(name: name, country: country, county: county, type: type)
                        locations.insert(result)
                    }
                case .Failure(let error):
                    print(error)
                }
                dispatch_group_leave(self.group)
            }
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        let array = locations.sort() { lhs, rhs in
            if lhs.priorityType() && !rhs.priorityType() {
                return true
            } else if !lhs.priorityType() && rhs.priorityType() {
                return false
            } else {
                return lhs.name < rhs.name
            }
        }
        completion(Array(array.prefix(10)))
    }
    
    func geocodeSearch(location : CLLocation, completion : SearchLocation -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: {
            placemarks, errors in
            let placename = placemarks![0]
            
            let url = self.geocodeUrl + "lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&username=\(self.geonamesUsername)"
            Alamofire.request(.GET, url).validate().responseJSON() {
                response in
                switch response.result {
                case .Success(let value):
                    let jsonString = JSON(value)
                    let geoname = jsonString["geonames"].arrayValue.first!
                    let name = geoname["name"].stringValue
                    let country = geoname["countryName"].stringValue
                    let type = geoname["fclName"].stringValue
                    if country == "Norway" {
                        self.locationSearch(name, completion: {
                            locations in
                            completion(locations[0])
                        })
                    } else {
                        let location = SearchLocation(name: name, country: country, county: placename.administrativeArea! , administrativeArea: placename.administrativeArea!, type: type)
                        completion(location)
                    }
                case .Failure(let error):
                    print(error)
                }
            }
            
        })
    }
    
    private func createSearchLocation(representation : XMLIndexer) -> SearchLocation {
        let name = representation["stedsnavn"].element!.text!
        let county = representation["fylkesnavn"].element!.text!
        let administrativeArea = trimCountyName(representation["kommunenavn"].element!.text!)
        let country = "Norway"
        let type = representation["navnetype"].element!.text!
        return SearchLocation(name: name, country: country, county: county, administrativeArea: administrativeArea, type: type)
    }
    
    private func trimCountyName(name : String) -> String {
        let regex =  try! NSRegularExpression(pattern: " \\(\\w*\\)", options: .CaseInsensitive)
        return regex.stringByReplacingMatchesInString(name, options: [], range: NSMakeRange(0, name.characters.count), withTemplate: "")
    }
    
    func getSavedLocations() -> [Location] {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let moc = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return try! moc.executeFetchRequest(fetchRequest) as! [Location]
    }
}

