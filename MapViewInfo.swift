//
//  MapViewInfo.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/10/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import Foundation
import CoreData


class MapViewInfo: NSManagedObject {
    
    struct Keys {
        static let Lat = "lat"
        static let Lon = "lon"
        static let LatDelta = "latDelta"
        static let LonDelta = "lonDelta"
    }

    @NSManaged var lat: NSNumber?
    @NSManaged var lon: NSNumber?
    @NSManaged var latDelta: NSNumber?
    @NSManaged var lonDelta: NSNumber?
    
    // standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("MapViewInfo", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        lat = dictionary[Keys.Lat] as? NSNumber
        lon = dictionary[Keys.Lon] as? NSNumber
        latDelta = dictionary[Keys.LatDelta] as? NSNumber
        lonDelta = dictionary[Keys.LonDelta] as? NSNumber
    }
}
