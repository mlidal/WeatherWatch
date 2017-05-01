//
//  LocationsViewController.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 01/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class LocationsViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate, SearchResultDelegate {
    
    var geonamesUsername : String!
    
    var location : CLLocation!
    var myLocation : Location!
    var myLocationWeather : Weather!
    
    var locationManager : CLLocationManager!
    let locationService = LocationService.sharedService
    let weatherService = WeatherService.sharedService
    
    var searchController : UISearchController!
    var searchResultsController : SearchResultsController!
    var managedObjectContext: NSManagedObjectContext!
    var tempObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
    lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
        let fetchRequest = NSFetchRequest<Location>(entityName: "Location")
        
        let sortDescriptor = NSSortDescriptor(key: "county", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var searchBarContainer: UIView!
    @IBOutlet var attributionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedObjectContext = appDelegate.managedObjectContext
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.allowsMultipleSelectionDuringEditing = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80.0
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        searchResultsController = navigationController?.storyboard?.instantiateViewController(withIdentifier: "SearchResultsController") as! SearchResultsController
        searchResultsController.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchBarContainer.addSubview(searchController.searchBar)
        searchController.definesPresentationContext = true
        
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() != .denied && CLLocationManager.authorizationStatus() != .restricted {
                locationManager = CLLocationManager()
                locationManager.delegate = self
                if CLLocationManager.authorizationStatus() == .notDetermined {
                    locationManager.requestWhenInUseAuthorization()
                } else {
                    locationManager.startUpdatingLocation()
                }
            }
        } else {
            print("Location services disabled")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print(controller)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        locationService.locationSearch(text: searchController.searchBar.text!, onlyNorway: false, completion: {
            results in
            self.searchResultsController.updateSearchResults(results: results)
        })
    }
    
    func searchResultSelected(result: SearchLocation) {
        searchController.isActive = false
        let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into: managedObjectContext) as! Location
        location.setLocationFromSearch(search: result)
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Error saving location to core data \(error)")
        }
        tableView.reloadData()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return myLocation == nil ? 0 : 1
        } else {
            let sections = fetchedResultsController.sections
            if sections != nil && sections!.count > 0  {
                return fetchedResultsController.sections![0].numberOfObjects
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Current position", comment: "Current position")
        } else {
            return NSLocalizedString("Saved positions", comment: "Saved positions")
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
        cell.place.text = "  "
        cell.temperature.text = ""
        cell.weatherIcon.image = nil
        cell.precipitation.text = ""
        cell.windSpeed.text = ""
        cell.windDirection.image = nil
        let configureCell : (Weather?) -> Void = {
            weather in
            if weather != nil {
                let report = weather!.reports.first!
                cell.weather = weather
                cell.place.text = weather!.location.name + "/" + weather!.location.country
                cell.temperature.text = String(format: "%.1f °", report.temperature)
                cell.weatherIcon.image = UIImage(named: report.symbol.variable + ".png")
                cell.precipitation.text = String(format: "%.1f mm", report.precipitation)
                cell.windSpeed.text = String(format: "%.1f m/s", report.windSpeed)
                
                cell.windDirection.image = self.getWindIcon(windSpeed: report.windSpeed)
                cell.windDirection.transform = CGAffineTransform(rotationAngle: CGFloat((report.windDirection + 90).degreesToRadians))
            } else {
                cell.place.text = NSLocalizedString("Unable to find weather data", comment: "Unable to find weather data")
            }
        }
        if indexPath.section == 0 {
            configureCell(myLocationWeather)
        } else {
            let entity = fetchedResultsController.object(at: IndexPath(item: indexPath.row, section: 0)) 
            weatherService.getWeather(location: entity, completion: configureCell)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let path = IndexPath(item: indexPath.row, section: 0)
            let location = fetchedResultsController.object(at: path) 
            managedObjectContext.delete(location)
            do {
                try managedObjectContext.save()
            } catch {
                print("Error deleting row \(error)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let cell = tableView.cellForRow(at: indexPath) as! WeatherCell
            openYrNoUrl(yrUrl: cell.weather.creditUrl)
    }
    
    private func openYrNoUrl(yrUrl : String) {
        if let encodedString = yrUrl.addingPercentEncoding(
            withAllowedCharacters: .urlFragmentAllowed),
            let url = URL(string: encodedString) {
            UIApplication.shared.openURL(url)
        }

    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == .delete {
            let tableIndexPath = IndexPath(item: indexPath!.row, section: 1)
            tableView.deleteRows(at: [tableIndexPath], with: .right)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if location == nil && locations.count > 0 {
            location = locations[0]
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: {
                placemarks, error in
                if placemarks != nil && placemarks!.count > 0 {
                    self.locationService.geocodeSearch(location: self.location, completion: {
                        location in
                        let entitiyDesc = NSEntityDescription.entity(forEntityName: "Location", in: self.managedObjectContext)
                        
                        self.myLocation = NSManagedObject.init(entity: entitiyDesc!, insertInto: nil) as! Location
                        self.myLocation.setLocationFromSearch(search: location)
                        self.weatherService.getWeather(location: self.myLocation, completion: {
                            weather in
                            self.myLocationWeather = weather
                            self.tableView.reloadData()
                        })
                    })
                    
                    
                }
            })
            
        }
    }
    
    private func getWindIcon(windSpeed : Double) -> UIImage? {
        var icon : UIImage?
        if windSpeed < 1 {
            icon = UIImage(named: "Wind Speed Less 1.png")
        } else if windSpeed < 3 {
            icon = UIImage(named: "Wind Speed 1-2.png")
        } else if windSpeed < 8 {
            icon = UIImage(named: "Wind Speed 3-7.png")
        } else if windSpeed < 13 {
            icon = UIImage(named: "Wind Speed 8-12.png")
        } else if windSpeed < 18 {
            icon = UIImage(named: "Wind Speed 13-17.png")
        } else if windSpeed < 23 {
            icon = UIImage(named: "Wind Speed 18-22.png")
        } else if windSpeed < 28 {
            icon = UIImage(named: "Wind Speed 23-27.png")
        } else if windSpeed < 33 {
            icon = UIImage(named: "Wind Speed 28-32.png")
        } else if windSpeed < 38 {
            icon = UIImage(named: "Wind Speed 33-37.png")
        } else if windSpeed < 43 {
            icon = UIImage(named: "Wind Speed 38-42.png")
        } else if windSpeed < 48 {
            icon = UIImage(named: "Wind Speed 43-47.png")
        } else if windSpeed < 53 {
            icon = UIImage(named: "Wind Speed 48-52.png")
        } else if windSpeed < 58 {
            icon = UIImage(named: "Wind Speed 53-57.png")
        } else if windSpeed < 63 {
            icon = UIImage(named: "Wind Speed 58-62.png")
        } else if windSpeed < 68 {
            icon = UIImage(named: "Wind Speed 63-67.png")
        } else if windSpeed < 73 {
            icon = UIImage(named: "Wind Speed 68-72.png")
        } else if windSpeed < 78 {
            icon = UIImage(named: "Wind Speed 73-77.png")
        }
        return icon
        
    }
    
}

protocol SearchResultDelegate {
    func searchResultSelected(result : SearchLocation)
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
}
