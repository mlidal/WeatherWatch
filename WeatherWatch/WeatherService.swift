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
    
    func getWeather(location : Location, completion : @escaping (Weather?) -> Void) {
        
        let savedWeather = weatherCache[location]
        if (savedWeather != nil && !savedWeather!.hasExpired()) {
            completion(savedWeather)
        } else {
            weatherCache.removeValue(forKey: location)
            
            var path = location.country! + "/"
            path += location.county! + "/"
            if location.administrativeArea != nil {
                
                path += location.administrativeArea! + "/"
            }
            
            if location.country == "Norway" || (location.administrativeArea == nil || location.administrativeArea != location.name) {
                path += location.name! + "/"
            }
            
            path += "varsel.xml"
            
            let url = baseUrl + path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            Alamofire.request(url).response() {
                response in
                
                let xml = SWXMLHash.parse(response.data!)
                
                if xml["weatherdata"].element != nil {
                    
                    let weather = self.createWeather(input: xml["weatherdata"])
                    self.weatherCache[location] = weather
                    completion(weather)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    private func createWeather(input : XMLIndexer) -> Weather {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let locationXML = input["location"]
        let location = Weather.Location(name: locationXML["name"].element!.text!, type: locationXML["type"].element!.text!, country: locationXML["country"].element!.text!, lat: Double(locationXML["location"].element!.allAttributes["latitude"]!.text)!, lon: Double(locationXML["location"].element!.allAttributes["longitude"]!.text)!)
        let creditXML = input["credit"]["link"].element!
        let creditText = creditXML.allAttributes["text"]!.text
        let creditUrl = creditXML.allAttributes["url"]!.text

        var reports = Array<Weather.WeatherReport>()
        
        let forecastXML = input["forecast"]["tabular"]
        for forecast in forecastXML["time"].all {
            let startTime = dateFormatter.date(from: forecast.element!.allAttributes["from"]!.text)!
            let endTime  = dateFormatter.date(from: forecast.element!.allAttributes["to"]!.text)!
            let symbolXML = forecast["symbol"].element!
            let symbolNumber = Int(symbolXML.allAttributes["number"]!.text)!
            let symbolNumberEx = Int(symbolXML.allAttributes["numberEx"]!.text)!
            let symbol = Weather.WeatherSymbol(number: symbolNumber, numberEx: symbolNumberEx, name: symbolXML.allAttributes["name"]!.text, variable: symbolXML.allAttributes["var"]!.text)
            
            let report = Weather.WeatherReport(startTime: startTime, endTime: endTime, symbol: symbol, precipitation: Double(forecast["precipitation"].element!.allAttributes["value"]!.text)!, windSpeed: Double(forecast["windSpeed"].element!.allAttributes["mps"]!.text)!, windDirection: Double(forecast["windDirection"].element!.allAttributes["deg"]!.text)!, temperature: Double(forecast["temperature"].element!.allAttributes["value"]!.text)!)
            reports.append(report)
        }
        
        return Weather(location: location, creditText: creditText, creditUrl: creditUrl, reports: reports)
    }}
