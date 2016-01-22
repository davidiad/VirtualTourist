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
    
    // To fix issue with files not being stored with the full url as identifier.
    // Slashes cause the files to not be saved.
    // So, using just the last part of the url as the identifier
    var photoImage: UIImage? {
        get {
            return VirtualTouristModel.Caches.imageCache.imageWithIdentifier(getFileID())
        }
        set {
            dispatch_async(dispatch_get_main_queue()) {
                if self.url != nil {
                    VirtualTouristModel.Caches.imageCache.storeImage(newValue, withIdentifier: self.getFileID())
                    self.downloaded = true
                    
                } else {
                    print("No URL string")
                }
            }
        }
    }
    
    // Delete the underlaying image file when Photo is deleted from Core Data
    override func prepareForDeletion() {

        let fileManager = NSFileManager.defaultManager()
        let documentsDirectoryPath: String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        let fullDocsUrl = documentsDirectoryPath + "/" + getFileID()

        if fileManager.fileExistsAtPath(fullDocsUrl) {
            
            do {
                try fileManager.removeItemAtPath(fullDocsUrl)
            } catch {
            }
        }
    }

    // helper func
    func getFileID() -> String {
        var fileID: String = ""
        if url != nil {
            let convertedUrl = NSURL(fileURLWithPath: url!)
            fileID = convertedUrl.lastPathComponent!
        }
        return fileID
    }
}
