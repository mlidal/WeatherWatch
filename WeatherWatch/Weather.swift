//
//  Weather.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import UIKit
import CoreLocation
import SWXMLHash

class Weather {

    let location : Location
    
    let creditText : String
    let creditUrl : String
    
    var reports = [WeatherReport]()
    
    init(input : XMLIndexer) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let locationXML = input["location"]
        location = Location(name: locationXML["name"].element!.text!, type: locationXML["type"].element!.text!, country: locationXML["country"].element!.text!, lat: Double(locationXML["location"].element!.attributes["latitude"]!)!, lon: Double(locationXML["location"].element!.attributes["longitude"]!)!)
        let creditXML = input["credit"]["link"].element!
        creditText = creditXML.attributes["text"]!
        creditUrl = creditXML.attributes["url"]!
        
        let forecastXML = input["forecast"]["tabular"]
        for forecast in forecastXML["time"].all {
            let startTime = dateFormatter.dateFromString(forecast.element!.attributes["from"]!)!
            let endTime  = dateFormatter.dateFromString(forecast.element!.attributes["to"]!)!
            let symbolXML = forecast["symbol"].element!
            let symbolNumber = Int(symbolXML.attributes["number"]!)
            let symbolNumberEx = Int(symbolXML.attributes["numberEx"]!)
            let symbol = WeatherSymbol(number: symbolNumber!, numberEx: symbolNumberEx!, name: symbolXML.attributes["name"]!, variable: symbolXML.attributes["var"]!)

            let report = WeatherReport(startTime: startTime, endTime: endTime, symbol: symbol, precipitation: Double(forecast["precipitation"].element!.attributes["value"]!)!, windSpeed: Double(forecast["windSpeed"].element!.attributes["mps"]!)!, windDirection: Double(forecast["windDirection"].element!.attributes["deg"]!)!, temperature: Double(forecast["temperature"].element!.attributes["value"]!)!)
            reports.append(report)
        }
    }
    
    
    class WeatherReport {
        let startTime : NSDate
        let endTime : NSDate
        
        let symbol : WeatherSymbol
        let precipitation : Double
        let windDirection : Double
        let windSpeed : Double
        let temperature : Double

        init(startTime : NSDate, endTime: NSDate, symbol : WeatherSymbol, precipitation : Double, windSpeed : Double, windDirection : Double, temperature: Double) {
            self.startTime = startTime
            self.endTime = endTime
            self.symbol = symbol
            self.precipitation = precipitation
            self.windSpeed = windSpeed
            self.windDirection = windDirection
            self.temperature = temperature
        }
        
    }
    

    class WeatherSymbol {
        let number : Int
        let numberEx : Int
        let name : String
        let variable : String
        
        init(number  : Int, numberEx : Int, name : String, variable : String) {
            self.number = number
            self.numberEx = numberEx
            self.name = name
            self.variable = variable
        }
    }
    
    class Location {
        
        let name : String
        let type : String
        let country : String
        let location : CLLocation
        
        init(name : String, type : String, country : String, lat : Double, lon : Double) {
            self.name = name
            self.type = type
            self.country = country
            self.location = CLLocation(latitude: lat, longitude: lon)
        }
    }
}
