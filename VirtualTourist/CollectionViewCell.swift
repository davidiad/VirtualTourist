//
//  CollectionViewCell.swift
//  VirtualTourist
//
//  Created by David Fierstein on 11/30/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    var image: UIImage?
    
    @IBOutlet weak var cellView: UIView!
    
    var color: UIColor {
        set {
            self.cellView.backgroundColor = newValue
        }
        
        get {
            return self.cellView.backgroundColor ?? UIColor.whiteColor()
        }
    }
}
