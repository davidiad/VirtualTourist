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
    
    
    // Question: Before enabling the bottom button, so we need to check that all cells have downloaded? Or just the visible ones? Or just that the url's have been fetched? Can I check to see if the cell's photoImage property is not nil? Or might those be deleted from the cache by the system, so unreliable?
    /*
    "If you wish to hold state for an entry in your collection, you'll have to store it separately from the cell itself. For example, an NSArray of structs (or custom NSObjects) that map to the indexPath.row value."
    */
    
    
    let model = VirtualTouristModel.sharedInstance
    var coordinates : CLLocationCoordinate2D?
    var currentPin: Pin?
    var numPhotos: Int?
    var photoCounter: Int?
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
    
//    override func viewDidAppear(animated: Bool) {
//        countDownloaded()
//    }
    
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
        //let frame : CGRect = self.view.frame
        let margin  = CGFloat(5)//(frame.width - 90 * 3) / 6.0
        return UIEdgeInsetsMake(2, margin, 2, margin) // margin between cells
    }

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
        numPhotos = currentPin?.photos.count
        photoCounter = numPhotos
        countDownloaded()
        sendInfoToCollectionEditor()
        //return (currentPin?.photos.count)!
        return numPhotos!
    }
    
    // loop through the photos, and decrement photoCounter for each photo that's already been downloaded
    func countDownloaded() {
        let arrayOfPhotos = fetchedResultsController.fetchedObjects
        for photo in arrayOfPhotos as! [Photo] {
            if photo.downloaded == true {
                if photoCounter != nil {
                    photoCounter! -= 1
                    print(photoCounter!)
                }
            }
        }
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
        //cell.image = nil // reset the image to nil when cell is reused. In the cell class, we use didSet to check whether the image is not nil, and therefore we have a 'new' (if recycled) cell.
        configureCell(cell, indexPath: indexPath)
    
//        // Configure the cell
//        let imageView = UIImageView()
//        imageView.contentMode = UIViewContentMode.ScaleToFill
//        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
//        let url = photo.url
//        imageView.imageFromUrl(url!)
//        imageView.frame = CGRect(x: 2, y: 2, width: csize.width - 4, height: csize.height - 4)
//        imageView.image = cell.image
//        cell.addSubview(imageView)
//        cell.backgroundColor = UIColor.redColor()
        return cell
    }
    
    //TODO: count cells to discover whether resetting the image is keeping the activity indicator from showing when it should
//    func resetCell(cell: CollectionViewCell) {
//        if cell.cellView.image != nil {
//            cell.cellView.image = nil
//        }
//    }
    
    func checkPhotoCount(photo: Photo) {
        if photo.downloaded == false {
            photoCounter! -= 1
            print("photoCount: \(photoCounter)")
        }
        photo.downloaded = true
        if photoCounter <= 0 {
            // enable the New Collection button
            sendInfoToCollectionEditor()
        }
    }
    
    // Configure cell for image cache etc
//    func configureCell(cell: TaskCancelingTableViewCell, movie: Movie) {
    func configureCell(cell: CollectionViewCell, indexPath: NSIndexPath) {
        //resetCell(cell)

        //var photoImage = UIImage(named: "puppy")
        var photoImage: UIImage?
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        //cell.setPhoto(photo)
        
        // Set the Photo Image
        if photo.url == nil || photo.url == "" {
            //photoImage = UIImage(named: "puppy")
      
        } else if photo.photoImage != nil {
            
            // photoImage is from the cache
            photoImage = photo.photoImage!
            //checkPhotoCount(photo)
            //photo.downloaded = true
            
        } else { // "This is the interesting case."- Jason@Udacity. The Photo has an image name, but it is not downloaded yet.
            
            // Start the task that will eventually download the image
            let task = FlickrClient.sharedInstance.taskForImage(photo.url!) { data, error in
                
                if let error = error {
                    print("Photo download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Create the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the information gets cached
                    photo.photoImage = image
                    //TODO: should photo.downloaded already be true? and should be set within the cell where it downloads
                    self.checkPhotoCount(photo)
                    //photo.downloaded = true
                    
                    do {
                        try self.sharedContext.save()
                    } catch {
                        print("error in saving the Photo to core data")
                    }
                    
                    // Will this be handled by FetchedResultsController?
//                    // update the cell later, on the main thread
//                    
                    //FlickrClient.sharedInstance.photoDownloadCounter -= 1
                    self.sendInfoToCollectionEditor()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.cellView.image = image
                        cell.image = image // TODO: not sure if this line, or variable, is needed, but for now, it is what triggers didSet for image, stopping activity indicator and allow enableUserInteraction for the cell
                        // Make an array of NSIndexPaths with just the current cell's indexpath in it
                        let indexPaths: [NSIndexPath] = [indexPath]
                        //TODO: make sure we aren't calling reload too much (called in fetchController code as well)
                        self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
                    }
                }
            }
            //TODO: Stop activity indicator when downloads are complete
            //TODO: New Collection button is grayed out until fetch is complete (or download is complete? check specs)

            // This is the custom property on this cell. See CollectionViewCell.swift for details.
            cell.taskToCancelifCellIsReused = task
        }
        
        // Configure the cell
        cell.cellView.contentMode = UIViewContentMode.ScaleToFill
        if photoImage != nil {
            cell.image = photoImage
            cell.cellView.image = cell.image
        }
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewCell
        
        // Whenever a cell is tapped, toggle its presence in the selectedIndexes array
        //if let index = find(selectedIndexes, indexPath) {
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Send the updated info to the button, so it knows what to say
        sendInfoToCollectionEditor()
        
        if cell.alpha < 1.0 {
            cell.alpha = 1.0
        } else {
            cell.alpha = 0.25
        }
    }
    
    func sendInfoToCollectionEditor () {
        if let parentVC = self.parentViewController as? CollectionEditor {
            if selectedIndexes.count > 0 {
                parentVC.bottomButton.title = "Remove Selected Photos"
            } else {
                parentVC.bottomButton.title = "New Collection"
            }
            if numPhotos != nil {
                parentVC.numPhotosLabel.text = "\(numPhotos!) photos were found"
            } else {
                parentVC.numPhotosLabel.text = "No photos were found."
            }
            if photoCounter! <= 0 {
                parentVC.bottomButton.enabled = true
                // allow cells to be selected
                collectionView?.userInteractionEnabled = true
            }
        }
    }
    
    //TODO: Need this func?
    // Uncomment this method to specify if the specified item should be highlighted during tracking
//    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
//        return true
//    }


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
    // We store the index paths into the three arrays.
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
            // that come about after data is downloaded. For example, when an image is downloaded from
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
        print("updated count: \(updatedIndexPaths.count)")
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
        // TODO: Can crash when hitting New Collection butt over and over
        // therefore, disable the button first
        if let parentVC = self.parentViewController as? CollectionEditor {
                parentVC.bottomButton.enabled = false
                // disallow cells to be selected while deletions are happening
                collectionView?.userInteractionEnabled = false
        }
        //TODO: seems to not finish deletions before button is enabled. Why?
        // need to prevent enabling of butt
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

//extension UIImageView {
//    public func imageFromUrl(urlString: String) {
//        if let url = NSURL(string: urlString) {
//            let request = NSURLRequest(URL: url)
//            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
//                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
//                if let imageData = data as NSData? {
//                    self.image = UIImage(data: imageData)
//                }
//            }
//        }
//    }
//}
