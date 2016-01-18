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

    @NSManaged var url: String? //TODO: not the best naming strategy to name a String a url. Better to name it something like filepath?
    @NSManaged var downloaded: Bool
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

    /* Worked for memory cache, but not storing on hard drive with Simulator
    var photoImage: UIImage? {
        
        get {
            return VirtualTouristModel.Caches.imageCache.imageWithIdentifier(url)
        }
        
        set {
            //TODO: After New Collection button disable/enable is implemented, I think this if let can be removed.
           // if let newUrl = url { // add this line to prevent errors when New Collection button is pressed before there is a URL
                VirtualTouristModel.Caches.imageCache.storeImage(newValue, withIdentifier: url!)
            //}
        }
    }
    */
    
    // To fix issue with files not being stored with the full url as identifier.
    // Probably slashes are causing the files to not be saved.
    // So, using just the last part of the url as the identifier
    var photoImage: UIImage? {
        get {
            let convertedUrl = NSURL(fileURLWithPath: url!)
            let fileName = convertedUrl.lastPathComponent
            
            return VirtualTouristModel.Caches.imageCache.imageWithIdentifier(fileName!)
        }
        set {
            //TODO: got a crash here when unwrapping optional while clicking a cell to mark for removal or clicking new collection button multiple times
            // It always pops up when concurrency debug is on,
            // Therefore, try putting on main thread to avoid that problem
            dispatch_async(dispatch_get_main_queue()) {
                if self.url != nil {
                    let convertedUrl = NSURL(fileURLWithPath: self.url!)
                    let fileName = convertedUrl.lastPathComponent
                    
                    VirtualTouristModel.Caches.imageCache.storeImage(newValue, withIdentifier: fileName!)
                    self.downloaded = true
                    
                } else {
                    print("No URL string")
                }
            }
        }
    }
    
    //TODO: remove debug argument before submitting app: -com.apple.CoreData.ConcurrencyDebug 1
    
    // TODO: delete the underlaying image file when Photo is deleted from Core Data
    override func prepareForDeletion() {
        // This func is called when an object is deleted
        // get the filepath from the object
        // check if the image exists at the filepath
        // delete the undelaying file in the Documents Directory
    }

}
