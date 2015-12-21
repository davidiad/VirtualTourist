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
    
    @IBOutlet weak var cellView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        if self.cellView != nil {
//            cellView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))

    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    
    
    var color: UIColor {
        set {
            self.cellView.backgroundColor = newValue
        }
        
        get {
            return self.cellView.backgroundColor ?? UIColor.whiteColor()
        }
    }


}
