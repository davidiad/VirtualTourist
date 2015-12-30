//
//  Photo.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/10/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class Photo: NSManagedObject {

    @NSManaged var url: String?
    @NSManaged var pin: NSManagedObject?
    
    // standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        url = dictionary[url!] as? String
    }
    
    var photoImage: UIImage? {
        
        get {
            return VirtualTouristModel.Caches.imageCache.imageWithIdentifier(url)
        }
        
        set {
            //TODO: After New Collection button disable/enable is implemented, I think this if let can be removed.
            if let newUrl = url { // add this line to prevent errors when New Collection button is pressed before there is a URL
                VirtualTouristModel.Caches.imageCache.storeImage(newValue, withIdentifier: newUrl)
            }
        }
    }

}
