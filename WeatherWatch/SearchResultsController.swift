//
//  SearchResultsController.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//

import UIKit

class SearchResultsController: UITableViewController {

    var searchResults = [SearchLocation]()
    var selectedResult : SearchLocation?
    var delegate : SearchResultDelegate?
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SearchResultCell")
        let result = searchResults[indexPath.row]
        
        cell?.textLabel?.text = result.name
        cell?.detailTextLabel?.text = "\(result.type), \(result.county) (\(result.country))"
        return cell!
    }
    
    func updateSearchResults(results : [SearchLocation]) {
        searchResults = results
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.searchResultSelected(searchResults[indexPath.row])
        dismissViewControllerAnimated(true, completion: nil)
    }
}
