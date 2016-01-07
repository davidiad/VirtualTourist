//
//  CollectionEditor.swift
//  VirtualTourist
//
//  Created by David Fierstein on 11/27/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class CollectionEditor: UIViewController, MKMapViewDelegate, UICollectionViewDelegate {

    let flickr = FlickrClient.sharedInstance
    let model = VirtualTouristModel.sharedInstance
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var coordinates : CLLocationCoordinate2D?
    var currentPin: Pin?
    
    var embeddedCollectionView: CollectionViewController?
    
    var testy: Int = 0

    @IBOutlet weak var mapView: MKMapView!
    //@IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var searchbox: UITextField!
    @IBOutlet weak var numPhotosLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        mapView.delegate = self
        let span = MKCoordinateSpanMake(0.25, 0.25)
        if coordinates != nil {
            mapView.centerCoordinate = coordinates!
            let region = MKCoordinateRegionMake(coordinates!, span)
            mapView.region = region
            placePin()

        } else {
            print("no coords in CollectionEditor")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func placePin() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates!
        //annotation.title = String(newCoordinates)// as String
        mapView.addAnnotation(annotation)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
            pinView?.pinTintColor = UIColor.blueColor()
        }
        return pinView
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        updateBottomButton()
        if let collectionViewController = segue.destinationViewController as? CollectionViewController {
            collectionViewController.coordinates = self.coordinates
            collectionViewController.currentPin = self.currentPin
            embeddedCollectionView = collectionViewController
        } else {
            print("segue to CollectionViewController fail")
        }
    }
    
    @IBAction func bottomButtonTapped(sender: AnyObject) {
        if embeddedCollectionView?.selectedIndexes.count > 0 {
            embeddedCollectionView?.deleteSelectedPhotos()
            self.updateBottomButton()
        } else {
            embeddedCollectionView?.deleteAllPhotos()
            // fetch the photo url's for this Pin
            // TODO: move to a better place, and consolidate with similar code in MapViewController
//            if let searchterm = searchbox.text {
//                print(searchterm)
//            }
            flickr.getFlickrImagesForCoordinates(coordinates!, getTotal:  true, searchtext: searchbox.text) { success, error in
                
            }
            flickr.getFlickrImagesForCoordinates(coordinates!, getTotal: false, searchtext: searchbox.text) { success, error in
                if success {
                    for url in self.model.photoArray! {
                        dispatch_async(dispatch_get_main_queue(), {
                            let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: self.sharedContext)!
                            let photo = Photo(entity: entity, insertIntoManagedObjectContext: self.sharedContext)
                            photo.pin = self.currentPin
                            photo.url = url
                            
                            _ = FlickrClient.sharedInstance.taskForImage(photo.url!) { data, error in
                                
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
                            
                            /*older, deprecated download code
                            let request = NSURLRequest(URL: NSURL(string: url)!)
                            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                                if let imageData = data as NSData? {
                                    //
                                }
                            }
                            */
                        })
                    }
                } else {
                    print("Error in getting Flickr Images: \(error)")
                }
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func updateBottomButton() {
       // if selectedIndexes.count > 0 {
       //     bottomButton.title = "Remove Selected Photos"
      //  } else {
            bottomButton.title = "New Collection"
       // }
    }
}
