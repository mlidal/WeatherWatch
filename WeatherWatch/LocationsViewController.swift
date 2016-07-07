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
    
    var location : CLLocation!
    var myLocation : Location!
    var locationManager : CLLocationManager!
    let locationService = LocationService()
    let weatherService = WeatherService()
    
    var searchController : UISearchController!
    var searchResultsController : SearchResultsController!
    var managedObjectContext: NSManagedObjectContext!
    var tempObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
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
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedObjectContext = appDelegate.managedObjectContext
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80.0
        
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeSearch)))
        
        searchResultsController = navigationController?.storyboard?.instantiateViewControllerWithIdentifier("SearchResultsController") as! SearchResultsController
        searchResultsController.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchBarContainer.addSubview(searchController.searchBar)
        searchController.definesPresentationContext = true
        
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() != .Denied && CLLocationManager.authorizationStatus() != .Restricted {
                locationManager = CLLocationManager()
                locationManager.delegate = self
                if CLLocationManager.authorizationStatus() == .NotDetermined {
                    locationManager.requestWhenInUseAuthorization()
                } else {
                    locationManager.startUpdatingLocation()
                }
            }
        } else {
            print("Location services disabled")
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print(controller)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        locationService.locationSearch(searchController.searchBar.text!, completion: {
            results in
            self.searchResultsController.updateSearchResults(results)
        })
    }
    
    func searchResultSelected(result: SearchLocation) {
        searchController.active = false
        let location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
        location.setLocationFromSearch(result)
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Error saving location to core data \(error)")
        }
        tableView.reloadData()
    }
    
    func closeSearch(event : UIEvent) {
        searchController.searchBar.endEditing(true)
        searchController.searchBar.resignFirstResponder()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Nåværende posisjon"
        } else {
            return "Mine lagrede posisjoner"
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("WeatherCell", forIndexPath: indexPath) as! WeatherCell
        let completion : Weather -> Void = {
            weather in
            let report = weather.reports.first!
            cell.place.text = weather.location.name
            cell.temperature.text = String(format: "%.1f °", report.temperature)
            cell.weatherIcon.image = UIImage(named: report.symbol.variable + ".png")
            cell.precipitation.text = String(format: "%.1f mm", report.precipitation)
            cell.windSpeed.text = String(format: "%.1f m/s", report.windSpeed)
            
            cell.windDirection.image = self.getWindIcon(report.windSpeed)
            cell.windDirection.transform = CGAffineTransformMakeRotation(CGFloat(report.windDirection.degreesToRadians))
            
        }
        if indexPath.section == 0 {
            weatherService.getWeather(myLocation, completion: completion)
        } else {
            let entity = fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: indexPath.row, inSection: 0)) as! Location
            weatherService.getWeather(entity, completion: completion)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let path = NSIndexPath(forItem: indexPath.row, inSection: 0)
            let location = fetchedResultsController.objectAtIndexPath(path) as! Location
            managedObjectContext.deleteObject(location)
            do {
                try managedObjectContext.save()
            } catch {
                print("Error deleting row \(error)")
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if type == .Delete {
            let tableIndexPath = NSIndexPath(forItem: indexPath!.row, inSection: 1)
            tableView.deleteRowsAtIndexPaths([tableIndexPath], withRowAnimation: .Right)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if location == nil && locations.count > 0 {
            location = locations[0]
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: {
                placemarks, error in
                if placemarks != nil && placemarks!.count > 0 {
                    let placemark = placemarks![0]
                    let entitiyDesc = NSEntityDescription.entityForName("Location", inManagedObjectContext: self.managedObjectContext)

                    self.myLocation = NSManagedObject.init(entity: entitiyDesc!, insertIntoManagedObjectContext: nil) as! Location
                    self.myLocation.name = placemark.locality
                    self.myLocation.country = placemark.country
                    self.myLocation.county = placemark.administrativeArea
                    self.myLocation.administrativeArea = placemark.locality
                    
                    self.tableView.reloadData()
                }
            })
            
        }
    }
    
    private func getWindIcon(windSpeed : Double) -> UIImage? {
        var icon : UIImage?
        if windSpeed < 1 {
            icon = UIImage(named: "Wind Speed less 1.png")
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
    var degreesToRadians: Double { return self * M_PI / 180 }
}
