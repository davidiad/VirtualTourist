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
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
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
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        cellView.image = nil
//    }
    
    var image: UIImage? {
        didSet {
            if oldValue == nil {
                activityView.stopAnimating()
                //TODO: only allow cell userInteraction after *all* cells are downloaded (may be causing possibilty of crash if cells are selected before downloading is done)
                //self.userInteractionEnabled = true
            }
        }
    }
    
//    //TODO: is this func needed at all, aside from activityView.startAnimating()?
//    func setPhoto(photo: Photo) {
//        //if let downloadedImage = cellView.image {
//        if cellView.image != nil {
//            print("cellView has an image!")
//            photo.downloaded = true //TODO: needed?
//            self.userInteractionEnabled = true //TODO: needed?
//            activityView.stopAnimating() //TODO: needed?
//        } else {
//            self.userInteractionEnabled = false
//            activityView.startAnimating()
//            print("No photo yet!")
//        }
//    }
    
    
    
    //TODO: Can the cell detect when its own image has been downloaded, and send a notification?
//    var imageWasDownloaded: Bool {
//        didSet {
//            if !oldValue {
//                
//            }
//        }
//    }


}
