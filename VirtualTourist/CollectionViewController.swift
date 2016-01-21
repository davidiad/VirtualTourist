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

//TODO: Collection view interaction scrolling disabled while New Collection is loading -- should b enabled
//TODO: clicking twice quickly allows double the #
//TODO: when a search term is entered, first tap finds 0 photos

class CollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    //TODO: Search object does not seem be being saved
    
    // Question: Before enabling the bottom button, so we need to check that all cells have downloaded? Or just the visible ones? Or just that the url's have been fetched? Can I check to see if the cell's photoImage property is not nil? Or might those be deleted from the cache by the system, so unreliable?
    /*
    "If you wish to hold state for an entry in your collection, you'll have to store it separately from the cell itself. For example, an NSArray of structs (or custom NSObjects) that map to the indexPath.row value."
    */
    
    
    let model = VirtualTouristModel.sharedInstance
    let flickr = FlickrClient.sharedInstance
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
    
    // Additional safeguard against rapidly repeated tapping of New Collection button
    var buttonTapAllowed: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        //print(currentPin)
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
            print("Error performing initial fetch: \(error)")        }
        
//        if let error = error {
//            print("Error performing initial fetch: \(error)")
//        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if  fetchedResultsController.fetchedObjects?.count == 0 {
            // automatically try to fetch photos with looser parameters if there are none from the initial fetch
            deleteAllPhotos(nil)
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
        numPhotos = currentPin?.photos.count
        photoCounter = numPhotos
        countDownloaded()
        sendInfoToCollectionEditor()
        enableNewCollectionButton()
        return numPhotos!
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
    
    // loop through the photos, and decrement photoCounter for each photo that's already been downloaded. Called once, when view first appears
    func countDownloaded() {
        let arrayOfPhotos = fetchedResultsController.fetchedObjects
        for photo in arrayOfPhotos as! [Photo] {
            if photo.downloaded == true {
                if photoCounter != nil {
                    photoCounter! -= 1
                }
            }
        }
    }
    
    //TODO: is this func duplicating countDownloaded? No. This func is to update the count for an individual Photo when it has finished downloading.
    func checkPhotoCount(photo: Photo) {
        // Why false? To make sure we don't count the photo as downloaded twice. Because photo.downloaded is about to be set to true
        dispatch_async(dispatch_get_main_queue()) {
            if photo.downloaded == false {
                self.photoCounter! -= 1
            }
            
            photo.downloaded = true
        }
        if photoCounter <= 0 {
            enableNewCollectionButton()
        }
    }
    
    // Configure cell for image cache etc
    func configureCell(cell: CollectionViewCell, indexPath: NSIndexPath) {
 
        var image: UIImage?
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        
        // Set the Photo Image
        if photo.url == nil || photo.url == "" {
            cell.cellView.image = UIImage(named: "puppy")
      
        } else if photo.photoImage != nil {
            
            // photoImage is from the cache
            image = photo.photoImage!
            
        } else { // "This is the interesting case."- Jason@Udacity. The Photo has an image name, but it is not downloaded yet.
            // set the default image
            cell.cellView.image = UIImage(named: "puppy")
            // Start the task that will eventually download the image
            let task = FlickrClient.sharedInstance.taskForImage(photo.url!) { data, error in
                
                if let error = error {
                    print("Photo download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Create the image
                    image = UIImage(data: data)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        // update the model, so that the information gets cached
                        photo.photoImage = image
                        self.checkPhotoCount(photo)
                        
                        // shorter syntax for saving core data
                        _ = try? self.sharedContext.save()
                    }
                    
                    //                    do {
                    //                         dispatch_async(dispatch_get_main_queue()) {
                    //                        try self.sharedContext.save()
//                        }
//                    } catch {
//                        print("error in saving the Photo to core data")
//                    }
                    self.sendInfoToCollectionEditor()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.cellView.image = image
                        cell.image = image // TODO: not sure if this line, or variable, is needed, but for now, it is what triggers didSet for image, stopping activity indicator and allow enableUserInteraction for the cell
                        // Make an array of NSIndexPaths with just the current cell's indexpath in it
                        let indexPaths: [NSIndexPath] = [indexPath]
                        //TODO: make sure we aren't calling reload too much (called in fetchController code as well)
                        if self.fetchedResultsController.fetchedObjects?.count > 0 { //safeguard against reloading an item that isn't there anymore
                            self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
                        }
                    }
                }
            }
            //TODO: New Collection button is grayed out until fetch is complete (or download is complete? check specs)

            // This is the custom property on this cell. See CollectionViewCell.swift for details.
            cell.taskToCancelifCellIsReused = task
        }
        
        // Configure the cell
        cell.cellView.contentMode = UIViewContentMode.ScaleToFill
        if image != nil {
            cell.cellView.image = image
            cell.image = image
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
        
        // Send the updated info to Collection Editor, so it knows what to say
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
//            if photoCounter! <= 0 || numPhotos == 0 {
//                parentVC.bottomButton.enabled = true
//                // allow cells to be selected
//                collectionView?.userInteractionEnabled = true
//            }
        }
    }
    
    //TODO: Still allowing a doubling of the photos when button tapped twice quickly
    func enableNewCollectionButton () {
        if let parentVC = self.parentViewController as? CollectionEditor {
            if photoCounter! <= 0 || numPhotos == 0 {
                parentVC.bottomButton.enabled = true
                // allow cells to be selected
                //collectionView?.userInteractionEnabled = true
            }
        }
    }
    
    func disableInteraction () {
        //TODO: don't disable scrolling
        //collectionView?.userInteractionEnabled = false
        if let parentVC = self.parentViewController as? CollectionEditor {
            parentVC.bottomButton.enabled = false
        }
    }

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
    
    // Whenever changes are made to Core Data the following three methods are invoked. This 1st method is used to create three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        // Disable button while changes are happening to avoid conflict by adding new photos while deletions etc are being processed
        disableInteraction()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the index paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case .Insert:
            // Here we are noting that a new Photo instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:

                // Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path
                // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
                // value that we want in this case.
                deletedIndexPaths.append(indexPath!)
          //  }
            break
        case .Update:
            //Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an image is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
//        case .Move:
//            print("Move an item. We don't expect to see this in this app.")
//            break
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
        
        //print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        //print("updated count: \(updatedIndexPaths.count)")
        
        collectionView!.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView!.insertItemsAtIndexPaths([indexPath])
            }
            
                for indexPath in self.deletedIndexPaths {
                    print("DELETE in performBatchUpdate")
                    self.collectionView!.deleteItemsAtIndexPaths([indexPath])
                }
            if self.buttonTapAllowed {
                for indexPath in self.updatedIndexPaths {
                    self.collectionView!.reloadItemsAtIndexPaths([indexPath])
                }
            }
            
            }, completion: nil)
    }
    
    func deleteAllPhotos(searchtext: String?) {
        buttonTapAllowed = false
        if fetchedResultsController.fetchedObjects?.count > 0 { // attempt to avoid crash when rapidly tapping
            dispatch_async(dispatch_get_main_queue()) {
                for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
                    if photo.managedObjectContext != nil {
                        self.sharedContext.deleteObject(photo)
                    }
                }
                self.saveContext()
            }
        }
        
        // Download a new collection of photos
        flickr.getFlickrImagesForCoordinates(self.coordinates!, getTotal: true, accuracyInt: flickr.currentAccuracy, searchtext: searchtext) { success, error in
            if success {
                if self.flickr.totalPhotos > 0 {
                    self.flickr.getFlickrImagesForCoordinates(self.coordinates!, getTotal: false, accuracyInt: self.flickr.currentAccuracy, searchtext: searchtext) { success, error in
                        if success {
                            self.buttonTapAllowed = true
                            for url in self.model.photoArray! {
                                dispatch_async(dispatch_get_main_queue(), {
                                    let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: self.sharedContext)!
                                    let photo = Photo(entity: entity, insertIntoManagedObjectContext: self.sharedContext)
                                    photo.pin = self.currentPin
                                    photo.url = url
                                    
                                    _ = self.flickr.taskForImage(photo.url!) { data, error in
                                        if let error = error {
                                            print("Photo download error: \(error.localizedDescription)")
                                        }
                                        if let data = data {
                                            // Create the image
                                            let image = UIImage(data: data)
                                            
                                            // update the model, so that the information gets cached
                                            photo.photoImage = image
                                        }
                                    }
                                })
                            }
                        } else {
                            print("Error in getting Flickr Images: \(error)")
                        }
                        self.saveContext()
                    }
                } else if self.flickr.totalPhotos == 0 {
                    // decrement accuracy and run again
                    self.flickr.getFlickrImagesForCoordinates(self.coordinates!, getTotal: true, accuracyInt: self.flickr.currentAccuracy, searchtext: searchtext) { success, error in
                        if success {
                        // recursive call. Accuracy is decremented in the getFlickrImages.. func
                            if self.flickr.noPhotosCanBeFound == false {
                                self.deleteAllPhotos(searchtext)
                            } else {
                                print(self.flickr.currentAccuracy)
                                print("NO PHOTOS CAN BE FOUND, TRY ANOTHER SEARCH")
                            }
                        }
                    }
                }
            }
        
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
    
    //MARK:- Save Managed Object Context
    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            _ = try? self.sharedContext.save()
        }
    }
    
    
    /* from the docs
Modifying the Fetch Request
You cannot simply change the fetch request to modify the results. If you want to change the fetch request, you must:
If you are using a cache, delete it (using deleteCacheWithName:).
Typically you should not use a cache if you are changing the fetch request.
Change the fetch request.
Invoke performFetch:.
Handling Object Invalidation
When a managed object context notifies the fetched results controller that individual objects are invalidated, the controller treats these as deleted objects and sends the proper delegate calls.
It’s possible for all the objects in a managed object context to be invalidated simultaneously. (For example, as a result of calling reset, or if a store is removed from the the persistent store coordinator.) When this happens, NSFetchedResultsController does not invalidate all objects, nor does it send individual notifications for object deletions. Instead, you must call performFetch: to reset the state of the controller then reload the data in the table view (reloadData).
iOS Version Issues
There are several known issues and behavior changes with NSFetchedResultsController on various releases of iOS.
*/
}

