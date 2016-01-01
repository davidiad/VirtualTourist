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
    
//    private var _coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
//    
//    var coordinate: CLLocationCoordinate2D {
//        get {
//            return _coordinate
//        }
//    }
    
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
        
        // Get the entity associated with the "Person" type.  This is an object that contains
        // the information from the Model.xcdatamodeld file. We will talk about this file in
        // Lesson 4.
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        lat = dictionary[Keys.Lat] as? NSNumber
        lon = dictionary[Keys.Lon] as? NSNumber
    }
    
//    func setCoordinate(newCoordinate: CLLocationCoordinate2D) {
//        willChangeValueForKey("coordinate")
//        self._coordinate = newCoordinate
//        didChangeValueForKey("coordinate")
//    }

}
