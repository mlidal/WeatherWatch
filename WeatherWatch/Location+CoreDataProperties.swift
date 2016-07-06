//
//  Location+CoreDataProperties.swift
//  WeatherWatch
//
//  Created by Mathias Lidal on 06/07/16.
//  Copyright © 2016 Mathias Lidal. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Location {

    @NSManaged var name: String?
    @NSManaged var country: String?
    @NSManaged var county: String?
    @NSManaged var administrativeArea: String?

}
