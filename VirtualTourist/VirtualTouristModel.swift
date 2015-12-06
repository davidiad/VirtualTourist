//
//  VirtualTouristModel.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/5/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import Foundation
//import UIKit

class VirtualTouristModel {
    static let sharedInstance = VirtualTouristModel()
    var photoArray: [String]?
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        photoArray = [String]()
    }

}



