//
//  CollectionViewCell.swift
//  VirtualTourist
//
//  Created by David Fierstein on 11/30/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    //MARK:- Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    //MARK:- Cell properties
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
                activityView.stopAnimating()
                userInteractionEnabled = true
            }
        }
    }
    
    //MARK:- Cell delegate
    override func prepareForReuse() {
        super.prepareForReuse()
        cellView.image = UIImage(named: "puppy")
        activityView.startAnimating()
        userInteractionEnabled = false
        image = nil
    }
}
