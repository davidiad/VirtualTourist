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
var csize: CGSize = CGSizeMake(100, 100)

class CollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    
    let model = VirtualTouristModel.sharedInstance
    let flickr = FlickrClient.sharedInstance
    var coordinates : CLLocationCoordinate2D?
    var currentPin: Pin?
    var numPhotos: Int?
    var photoCounter: Int?
    private let barSize : CGFloat = 0.0
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.
    var selectedIndexes = [NSIndexPath]()
    // Keep the changes. We keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    // Additional safeguard against rapidly repeated tapping of New Collection button
    var buttonTapAllowed: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the fetched results controller
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error performing initial fetch")
        }
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
        let margin  = CGFloat(5)
        return UIEdgeInsetsMake(2, margin, 2, margin) // margin between cells
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //numPhotos = currentPin?.photos.count
        numPhotos = fetchedResultsController.fetchedObjects?.count
        photoCounter = numPhotos
        // count how many of the photos have already been downloaded
        countDownloaded()
        // update the UI elements in the Collection Editor (which this Collection View is embedded in)
        sendInfoToCollectionEditor()
        enableNewCollectionButton()
        return numPhotos!
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
        configureCell(cell, indexPath: indexPath)
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
    
    // Is this func duplicating countDownloaded? No. This func is to update the count for an individual Photo when it has finished downloading.
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

                    self.sendInfoToCollectionEditor()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.cellView.image = image
                        cell.image = image // triggers didSet for image, stopping activity indicator and allowing enableUserInteraction for the cell
                        // Make an array of NSIndexPaths with just the current cell's indexpath in it
                        let indexPaths: [NSIndexPath] = [indexPath]
                        if self.fetchedResultsController.fetchedObjects?.count > 0 { //safeguard against reloading an item that isn't there anymore
                            self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
                        }
                    }
                }
            }

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
    
    //MARK:- Collection Editor UI
    
    // multi-purpose updates to parent view UI
    func sendInfoToCollectionEditor () {
        if let parentVC = self.parentViewController as? CollectionEditor {
            if selectedIndexes.count > 0 {
                parentVC.bottomButton.title = "Remove Selected Photos"
            } else {
                parentVC.bottomButton.title = "New Collection"
            }
            if numPhotos != nil {
                if numPhotos == 0 {
                    parentVC.numPhotosLabel.text = "No photos found yet, please wait..."
                    // fetch a new set of photos?
                    //TODO: refactor
//                    print( " in sendInfo")
//                    deleteAllPhotos(nil)
//                    return
                } else if numPhotos == 1 {
                    parentVC.numPhotosLabel.text = "One photo was found"
                } else {
                    parentVC.numPhotosLabel.text = "\(numPhotos!) photos were found"
                }
            } else {
                parentVC.numPhotosLabel.text = "No photos were found."
            }
        }
    }
    
    func updateNumPhotosLabel () {
        dispatch_async(dispatch_get_main_queue()) {
            if let parentVC = self.parentViewController as? CollectionEditor {
                if self.flickr.noPhotosCanBeFound == false {
                    parentVC.numPhotosLabel.text = "Expanding the search. Please wait..."
                } else {
                    parentVC.numPhotosLabel.text = "No photos can be found, please try another search."
                }
            }
        }
    }
    
    func enableNewCollectionButton () {
        if let parentVC = self.parentViewController as? CollectionEditor {
            if photoCounter! <= 0 || numPhotos == 0 {
                parentVC.bottomButton.enabled = true
            }
        }
    }
    
    func disableInteraction () {
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

                /* Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has values that we want in this case. */
                deletedIndexPaths.append(indexPath!)
          //  }
            break
        case .Update:
            /* Core Data would notify us of changes if any occured. This can be useful if you want to respond to changes that come about after data is downloaded. For example, when an image is downloaded from Flickr in the Virtual Tourist app */
            updatedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }
    
    /* This method is invoked after all of the changed in the current batch have been collected into the three index path arrays (insert, delete, and upate). We now need to loop through the arrays and perform the changes. */
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView!.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView!.insertItemsAtIndexPaths([indexPath])
            }
            
                for indexPath in self.deletedIndexPaths {
                    if let parentVC = self.parentViewController as? CollectionEditor {
                        parentVC.numPhotosLabel.text = "Removed \(self.deletedIndexPaths.count) photos"
                    }
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
                    self.updateNumPhotosLabel()
                    // decrement accuracy and run again
                    self.flickr.getFlickrImagesForCoordinates(self.coordinates!, getTotal: true, accuracyInt: self.flickr.currentAccuracy, searchtext: searchtext) { success, error in
                        if success {
                        // recursive call. Accuracy is decremented in the getFlickrImages.. func
                            if self.flickr.noPhotosCanBeFound == false {
                                self.deleteAllPhotos(searchtext)
                            } else {
                                self.updateNumPhotosLabel()
                                self.buttonTapAllowed = true
                                self.flickr.currentAccuracy = 16 // reset the accuracy
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
    
    //MARK:- Save Managed Object Context helper function
    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            _ = try? self.sharedContext.save()
        }
    }
}

