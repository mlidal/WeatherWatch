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
        let bundle = Bundle.main
        let geonamesUsername = bundle.infoDictionary!["geonames username"] as! String
        return geonamesUsername
    }()
    
    
    let SSRIUrl = "https://ws.geonorge.no/SKWS3Index/ssr/sok?"
    let geonamesSearchUrl = "http://api.geonames.org/searchJSON?"
    let geocodeUrl = "http://api.geonames.org/findNearbyJSON?"
    let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    let group = DispatchGroup()
    
    func locationSearch(text : String, onlyNorway : Bool = true, completion : ([SearchLocation]) -> Void) {
        var path = "navn=" + text + "*&maxAnt=10"
        var locations = Set<SearchLocation>()
        
        self.group.enter()
        
        let url = SSRIUrl + path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        Alamofire.request(url).validate().response(queue: queue) { response in // method defaults to `.get`
            
            let xml = SWXMLHash.parse(response.data!)
            let res = xml["sokRes"] 
            if res["sokStatus"]["ok"].element?.text == "true" {
                for locXML in res["stedsnavn"].all {
                    
                    let location = self.createSearchLocation(representation: locXML)
                    locations.insert(location)
                }
            }
            self.group.leave()
        }
        
        if !onlyNorway {
            self.group.enter()
            path = "name_startsWith=\(text)&maxRows=10&username=\(geonamesUsername)"
            Alamofire.request(geonamesSearchUrl + path.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!).validate().responseJSON(queue: queue) {
                response in
                
                if let value = response.value {
                    let jsonString = JSON(value)
                    for geoname in jsonString["geonames"].arrayValue {
                        let name = geoname["name"].stringValue
                        let country = geoname["countryName"].stringValue
                        let county = geoname["adminName1"].stringValue
                        let type = geoname["fclName"].stringValue
                        let result = SearchLocation(name: name, country: country, county: county, type: type)
                        locations.insert(result)
                    }
                } else {
                    print(response.error!)
                }
                self.group.leave()
            }
        }
        let _ = group.wait(timeout: .distantFuture)
        
        let array = locations.sorted() { lhs, rhs in
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
    
    func geocodeSearch(location : CLLocation, completion : @escaping (SearchLocation) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: {
            placemarks, errors in
            let placename = placemarks![0]
            
            let url = self.geocodeUrl + "lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&username=\(self.geonamesUsername)"
            Alamofire.request(url).validate().responseJSON() {
                response in
                if let value = response.result.value {
                    let jsonString = JSON(value)
                    
                    if let geoname = jsonString["geonames"].arrayValue.first {
                    let name = geoname["name"].stringValue
                    let country = geoname["countryName"].stringValue
                    let type = geoname["fclName"].stringValue
                    if country == "Norway" {
                        self.locationSearch(text: name, completion: {
                            locations in
                            if !locations.isEmpty {
                                completion(locations[0])
                            }
                        })
                    } else {
                        let location = SearchLocation(name: name, country: country, county: placename.administrativeArea! , administrativeArea: placename.administrativeArea!, type: type)
                        completion(location)
                    }
                    }
                } else {
                    print(response.error!)
                }
            }
            
        })
    }
    
    private func createSearchLocation(representation : XMLIndexer) -> SearchLocation {
        let name = representation["stedsnavn"].element!.text!
        let county = representation["fylkesnavn"].element!.text!
        let administrativeArea = trimCountyName(name: representation["kommunenavn"].element!.text!)
        let country = "Norway"
        let type = representation["navnetype"].element!.text!
        return SearchLocation(name: name, country: country, county: county, administrativeArea: administrativeArea, type: type)
    }
    
    private func trimCountyName(name : String) -> String {
        let regex =  try! NSRegularExpression(pattern: " \\(\\w*\\)", options: .caseInsensitive)
        return regex.stringByReplacingMatches(in: name, options: [], range: NSMakeRange(0, name.characters.count), withTemplate: "")
    }
    
    func getSavedLocations() -> [Location] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return try! moc.fetch(fetchRequest) as! [Location]
    }
}

