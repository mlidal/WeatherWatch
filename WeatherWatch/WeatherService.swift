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
    
    static let sharedService = WeatherService()
    
    let baseUrl = "https://www.yr.no/stad/"
    var weatherCache = [Location:Weather]()
    
    private init() {}
    
    func getWeather(location : Location, completion : Weather? -> Void) {
        
        let savedWeather = weatherCache[location]
        if (savedWeather != nil && !savedWeather!.hasExpired()) {
            completion(savedWeather)
        } else {
            weatherCache.removeValueForKey(location)
            
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
                    
                    let weather = self.createWeather(xml["weatherdata"])
                    self.weatherCache[location] = weather
                    completion(weather)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    private func createWeather(input : XMLIndexer) -> Weather {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let locationXML = input["location"]
        let location = Weather.Location(name: locationXML["name"].element!.text!, type: locationXML["type"].element!.text!, country: locationXML["country"].element!.text!, lat: Double(locationXML["location"].element!.attributes["latitude"]!)!, lon: Double(locationXML["location"].element!.attributes["longitude"]!)!)
        let creditXML = input["credit"]["link"].element!
        let creditText = creditXML.attributes["text"]!
        let creditUrl = creditXML.attributes["url"]!

        var reports = Array<Weather.WeatherReport>()
        
        let forecastXML = input["forecast"]["tabular"]
        for forecast in forecastXML["time"].all {
            let startTime = dateFormatter.dateFromString(forecast.element!.attributes["from"]!)!
            let endTime  = dateFormatter.dateFromString(forecast.element!.attributes["to"]!)!
            let symbolXML = forecast["symbol"].element!
            let symbolNumber = Int(symbolXML.attributes["number"]!)
            let symbolNumberEx = Int(symbolXML.attributes["numberEx"]!)
            let symbol = Weather.WeatherSymbol(number: symbolNumber!, numberEx: symbolNumberEx!, name: symbolXML.attributes["name"]!, variable: symbolXML.attributes["var"]!)
            
            let report = Weather.WeatherReport(startTime: startTime, endTime: endTime, symbol: symbol, precipitation: Double(forecast["precipitation"].element!.attributes["value"]!)!, windSpeed: Double(forecast["windSpeed"].element!.attributes["mps"]!)!, windDirection: Double(forecast["windDirection"].element!.attributes["deg"]!)!, temperature: Double(forecast["temperature"].element!.attributes["value"]!)!)
            reports.append(report)
        }
        
        return Weather(location: location, creditText: creditText, creditUrl: creditUrl, reports: reports)
    }}