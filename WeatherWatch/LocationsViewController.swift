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
    
    var placemark : CLPlacemark!
    var location : CLLocation!
    var locationManager : CLLocationManager!
    let locationService = LocationService()
    var searchController : UISearchController!
    var searchResultsController : SearchResultsController!
    var managedObjectContext: NSManagedObjectContext!
    
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
            return placemark == nil ? 0 : 1
        } else {
            let sections = fetchedResultsController.sections
            if sections != nil && sections!.count > 0  {
                return fetchedResultsController.sections![0].numberOfObjects
            } else {
                return 0
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MyLocationCell", forIndexPath: indexPath) as! WeatherCell
        if indexPath.section == 0 {
            cell.label.text = self.placemark.name
        } else {
            let entity = fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: indexPath.row, inSection: 0)) as! Location
            cell.label.text = entity.name
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
                    for mark in placemarks! {
                        print(mark)
                    }
                    
                    self.placemark = placemarks![0]
                    self.tableView.reloadData()
                }
            })
            
        }
    }
}

protocol SearchResultDelegate {
    func searchResultSelected(result : SearchLocation)
}
