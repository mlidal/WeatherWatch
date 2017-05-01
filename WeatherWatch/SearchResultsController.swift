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
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell")
        let result = searchResults[indexPath.row]
        
        cell?.textLabel?.text = result.name
        cell?.detailTextLabel?.text = "\(result.type), \(result.county) (\(result.country))"
        return cell!
    }
    
    func updateSearchResults(results : [SearchLocation]) {
        searchResults = results
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.searchResultSelected(result: searchResults[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
}
