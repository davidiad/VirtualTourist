//
//  Photo.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/10/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

    @NSManaged var url: String?
    @NSManaged var pin: NSManagedObject?
}
