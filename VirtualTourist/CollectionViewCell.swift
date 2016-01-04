//
//  CollectionViewCell.swift
//  VirtualTourist
//
//  Created by David Fierstein on 11/30/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    //TODO: consolidate cell.image and cell.cellView.image into 1 variable
    //var image: UIImage?  //TODO: check if this is being used
    
    @IBOutlet weak var cellView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //imageWasDownloaded = false
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
    
    // The property uses a property observer. Any time its
    // value is set it cancels the previous NSURLSessionTask
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    
    var image: UIImage? {
        didSet {
            if oldValue == nil {
                //print("An image was set and I'm a cell!")
            }
        }
    }
    
    func setPhoto(photo: Photo) {
        if let downloadedImage = cellView.image {
            print("cellView has an image!")
        } else {
            print("No photo yet!")
        }
    }
    
    
    
    //TODO: Can the cell detect when its own image has been downloaded, and send a notification?
//    var imageWasDownloaded: Bool {
//        didSet {
//            if !oldValue {
//                
//            }
//        }
//    }


}
