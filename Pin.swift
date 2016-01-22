//
//  Pin.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/10/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let Lat = "lat"
        static let Lon = "lon"
    }

    @NSManaged var lat: NSNumber?
    @NSManaged var lon: NSNumber?
    @NSManaged var pinID: NSNumber?
    @NSManaged var photos: [Photo]
    @NSManaged var search: Search?
    
    var coordinate: CLLocationCoordinate2D {
        set (newValue) {
            lat = newValue.latitude
            lon = newValue.longitude
        }
        get {
            return CLLocationCoordinate2D(latitude: Double(lat!), longitude: Double(lon!))
        }
    }
    
    var title: String?
    
    // standard Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Pin class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the dictionary.
        lat = dictionary[Keys.Lat] as? NSNumber
        lon = dictionary[Keys.Lon] as? NSNumber
    }
}
