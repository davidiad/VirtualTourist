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

class CollectionEditor: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UITextFieldDelegate {

    let flickr = FlickrClient.sharedInstance
    let model = VirtualTouristModel.sharedInstance
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var coordinates : CLLocationCoordinate2D?
    var currentPin: Pin?
    
    var embeddedCollectionView: CollectionViewController?
    
    var testy: Int = 0
    var keyboardHeight: CGFloat?

    @IBOutlet weak var mapView: MKMapView!
    //@IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var searchbox: UITextField!
    @IBOutlet weak var numPhotosLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        searchbox.delegate = self
        mapView.delegate = self
        let span = MKCoordinateSpanMake(0.25, 0.25)
        //dispatch_async(dispatch_get_main_queue()) {
            if self.coordinates != nil {
                self.mapView.centerCoordinate = self.coordinates!
                let region = MKCoordinateRegionMake(self.coordinates!, span)
                self.mapView.region = region
                self.placePin()
                
            } else {
                print("no coords in CollectionEditor")
            }
        //}
    }
    
    override func viewDidAppear(animated: Bool) {
        if currentPin != nil {
            print("IN CEDITOR: \(currentPin)")
            if currentPin?.search != nil {
                if let searchtext = currentPin?.search?.searchString {
                    print("SEARCH FOR: \(searchtext)")
                    searchbox.text = searchtext
                } else {
                    print("NO SEARCHTEXT IN CEDITOR")
                }
            }
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
        
        if embeddedCollectionView?.selectedIndexes.count <= 0 {
            
            bottomButton.enabled = false
            print("BB TAPPED")
            if embeddedCollectionView?.buttonTapAllowed == true { //Check to make sure we're not in the middle of deleting old photos and fetching new ones
                if searchbox.text != nil && searchbox.text != "" {
                    dispatch_async(dispatch_get_main_queue()) {
                        // Insert a new search object if there is an entry in the searchbox
                        let entity = NSEntityDescription.entityForName("Search", inManagedObjectContext: self.sharedContext)!
                        let search = Search(entity: entity, insertIntoManagedObjectContext: self.sharedContext)
                        search.searchString = self.searchbox.text
                        self.currentPin?.search = search
                        search.pin = self.currentPin
                        do {
                            try self.sharedContext.save()
                        } catch {
                            print("Could not save the search")
                        }
                    }
                }
                embeddedCollectionView?.deleteAllPhotos(self.searchbox.text!)
            }
        } else {
            print("BB remove TAPPED")
            embeddedCollectionView?.deleteSelectedPhotos()
            updateBottomButton()
        }
    }
    
    func updateBottomButton() {
        bottomButton.title = "New Collection"
    }
    
    //MARK:- Keyboard dismissal
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Cancels textfield editing when user touches outside the textfield
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if searchbox.isFirstResponder() {
            view.endEditing(true)
        }
        super.touchesBegan(touches, withEvent:event)
    }
}
