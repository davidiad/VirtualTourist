//
//  VirtualTouristModel.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/5/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import Foundation

class VirtualTouristModel {
    static let sharedInstance = VirtualTouristModel() // singleton
    var photoArray: [String]?
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        photoArray = [String]()
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}



