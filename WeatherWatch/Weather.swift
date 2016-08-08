//
//  Weather.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import UIKit
import CoreLocation

class Weather : NSObject {

    let timestamp : NSDate
    
    let location : Location
    
    let creditText : String
    let creditUrl : String
    
    var reports = [WeatherReport]()
    
    init(location : Weather.Location, creditText: String, creditUrl: String, reports : [WeatherReport]) {
        self.timestamp = NSDate()
        self.location = location
        self.creditUrl = creditUrl
        self.creditText = creditText
        self.reports = reports
        super.init()
    }
    
    func hasExpired() -> Bool {
        return abs(timestamp.timeIntervalSinceNow) > 600
    }    
    
    func getWatchWeather() -> [String:String] {
        let report = reports[0]
        
        var weather = [String:String]()
        weather["placename"] = location.name
        weather["symbol"] = report.symbol.variable
        weather["temperature"] = String(format: "%.1f °", report.temperature)
        weather["precipitation"] = String(format: "%.1f mm", report.precipitation)
        return weather
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
