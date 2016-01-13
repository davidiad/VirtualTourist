//
//  Search.swift
//  VirtualTourist
//
//  Created by David Fierstein on 1/8/16.
//  Copyright © 2016 David Fierstein. All rights reserved.
//

import Foundation
import CoreData


class Search: NSManagedObject {

    @NSManaged var searchString: String?
    @NSManaged var accuracy: NSNumber?
    @NSManaged var pin: Pin?
    
    // standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Search", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        searchString = dictionary[searchString!] as? String
    }
}
