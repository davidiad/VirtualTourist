//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by David Fierstein on 11/29/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import CoreData
import UIKit
import MapKit

let reuseIdentifier = "Cell"
//let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
var csize: CGSize = CGSizeMake(100, 100)

class CollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {


    let model = VirtualTouristModel.sharedInstance
    var coordinates : CLLocationCoordinate2D?
    var currentPin: Pin?
    private let barSize : CGFloat = 0.0
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("current pin: \(currentPin)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        
        //self.collectionView!.registerClass(CollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
            print("fetch try")
        } catch {
            print("fetch catch")
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
        

    }
    
    override func viewWillLayoutSubviews() {
        let frame = self.view.frame
        self.collectionView!.frame = CGRectMake(frame.origin.x, frame.origin.y + barSize, frame.size.width, frame.size.height - barSize)
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let w = self.collectionView!.frame.size.width
        
        csize = CGSize(width: (w - 26)/3, height: (w - 26)/3)
        return csize // The size of one cell
    }
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSizeMake(self.view.frame.width, 90)  // Header size
//    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let frame : CGRect = self.view.frame
        let margin  = CGFloat(5)//(frame.width - 90 * 3) / 6.0
        return UIEdgeInsetsMake(2, margin, 2, margin) // margin between cells
    }
    
    // Layout the collection view
    
//    override func viewDidLayoutSubviews() {
//         super.viewDidLayoutSubviews()
//    print("layoutSubviews")
//         //Lay out the collection view so that cells take up 1/3 of the width,
//        // with no space in between.
//        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
//        layout.minimumLineSpacing = 0
//        layout.minimumInteritemSpacing = 0
//        
//        let width = floor(self.collectionView!.frame.size.width/4)
//        layout.itemSize = CGSize(width: width, height: width)
//        for sub in collectionView!.subviews {
//            print(sub.tag)
//        }
//        collectionView!.collectionViewLayout = layout
//    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       // let sectionInfo = self.fetchedResultsController.sections![section]
        
        //print("number Of Cells in Section: \(sectionInfo.numberOfObjects)")
        //TODO: currently getting the no of Pins, not of Photos for that Pin
        //print("currentPin pinID: \(currentPin?.pinID)")
//        let fetchRequest = NSFetchRequest(entityName: "Photo")
//        fetchRequest.predicate = NSPredicate(format: "pin == %@", currentPin!)
        
        //return sectionInfo.numberOfObjects
//        if model.photoArray?.count > 0 {
//            return (model.photoArray?.count)!
//        } else {
//            print("no photos here yet")
//            return 21 // if there are no photos ready, still, display the collection view with 21 empty cells
//        }
        return (currentPin?.photos.count)!
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
    
        // Configure the cell
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleToFill
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let url = photo.url
        imageView.imageFromUrl(url!)
        imageView.frame = CGRect(x: 2, y: 2, width: csize.width - 4, height: csize.height - 4)
        imageView.image = cell.image
        
//        if model.photoArray?.count > 0 {
//            if indexPath.row < model.photoArray?.count {
//                let url = model.photoArray![indexPath.row]
//                imageView.imageFromUrl(url)
//                //imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//                imageView.frame = CGRect(x: 2, y: 2, width: csize.width - 4, height: csize.height - 4)
//                imageView.image = cell.image
//            }
//            
//        }
        cell.addSubview(imageView)
        cell.backgroundColor = UIColor.redColor()
        return cell
    }
    
    

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        //if let index = find(selectedIndexes, indexPath) {
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Send the updated info to the button, so it knows what to say
        sendInfoToButton()
        
        
        if cell.alpha < 1.0 {
            cell.alpha = 1.0
        } else {
            cell.alpha = 0.3
        }
    }
    
    func sendInfoToButton () {
        if let parentVC = self.parentViewController as? CollectionEditor {
            if selectedIndexes.count > 0 {
                parentVC.bottomButton.title = "Remove Selected Photos"
            } else {
                parentVC.bottomButton.title = "New Collection"
            }
        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        //TODO: Sometimes segues to here when there is no currentPin property, which should not happen
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.currentPin!)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView!.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView!.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView!.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView!.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
    }

    
}

extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                if let imageData = data as NSData? {
                    self.image = UIImage(data: imageData)
                }
            }
        }
    }
}
