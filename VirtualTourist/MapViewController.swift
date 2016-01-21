//
//  MapViewController.swift
//  On The Map
//
//  Created by David Fierstein on 9/30/15.
//  Copyright (c) 2015 David Fierstein. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    let model = VirtualTouristModel.sharedInstance
    let flickr = FlickrClient.sharedInstance
    
    var currentPin: Pin?
    
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        flickr.makeDate()
        map.delegate = self
        let longpress = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longpress.minimumPressDuration = 0.7
        map.addGestureRecognizer(longpress)
    }
    
    override func viewWillAppear(animated: Bool) {
        let mapInfo = fetchMapInfo()
        map.centerCoordinate.latitude = Double(mapInfo.lat!)
        map.centerCoordinate.longitude = Double(mapInfo.lon!)
        let mapSpan = MKCoordinateSpanMake(Double(mapInfo.latDelta!), Double(mapInfo.lonDelta!))
        map.region = MKCoordinateRegionMake(map.centerCoordinate, mapSpan)
        
        let pinArray = fetchPins()
        displayPins(pinArray)
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.locationInView(map)
        let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
        //TODO: convert to switch statement. Not necessary, but cleaner code
        if gestureRecognizer.state == UIGestureRecognizerState.Began { // allows only 1 pin per touch

            // Add a new Pin object to data store
            // First, create a dictionary to init the Pin
            let pinDictionary = [
                "lat": NSNumber(double: newCoordinates.latitude),
                "lon": NSNumber(double: newCoordinates.longitude)
            ]
            currentPin = Pin(dictionary: pinDictionary, context: sharedContext)
            currentPin?.coordinate = newCoordinates
            map.addAnnotation(currentPin!)
            
            // in order to get a permanent ID, we can save the Pin into the context
            CoreDataStackManager.sharedInstance().saveContext()
            currentPin?.title = String(currentPin!.objectID.URIRepresentation())
            
        } else if gestureRecognizer.state == UIGestureRecognizerState.Changed {
            // in change state
            //to use KVO
            currentPin?.willChangeValueForKey("coordinate")
            // change coordinate to new location
            currentPin?.coordinate = newCoordinates
            currentPin?.didChangeValueForKey("coordinate")
        } else if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            // fetch the photo url's for this Pin
            // Run the fetch to get the total repeatedly, reducing accuracy each time, until at least 1 photo is found
            flickr.currentAccuracy = 16 // reset accuracy to the default
            flickr.getFlickrImagesForCoordinates(newCoordinates, getTotal: true, accuracyInt: nil, searchtext: nil) { success, error in
                print("flickr.totalPhotos: \(self.flickr.totalPhotos)")
                self.flickr.getFlickrImagesForCoordinates(newCoordinates, getTotal:  false, accuracyInt: nil, searchtext: nil) { success, error in
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
                                
                            } )
                        }
                    } else {
                        print("Error in getting Flickr Images: \(error)")
                    }
                }

            }
//            if (flickr.totalPhotos == nil || (flickr.totalPhotos == 0 && flickr.noPhotosCanBeFound == false)) {
//                repeat {
//                    flickr.getFlickrImagesForCoordinates(newCoordinates, getTotal: true, searchtext: nil) { success, error in
//                        print("flickr.totalPhotos: \(self.flickr.totalPhotos)")
//                    }
//                } while (flickr.totalPhotos == nil || (flickr.totalPhotos == 0 && flickr.noPhotosCanBeFound == false))
//            }
            /*
            flickr.getFlickrImagesForCoordinates(newCoordinates, getTotal:  false, searchtext: nil) { success, error in
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
                            
                        } )
                    }
                } else {
                    print("Error in getting Flickr Images: \(error)")
                }
            }
            */
            
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func displayPins(pinArray: [Pin]) {
        
        for pin in pinArray {
            let name = String(pin.objectID.URIRepresentation())   //String(lat) + ", " + String(lon)
            
            pin.title = name  // eventually should be able to move this value into a stored property of Pin
        }
        
        // When the array is complete, we add the annotations to the map.
        map.addAnnotations(pinArray)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - MKMapViewDelegate
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.brownColor()
            pinView?.animatesDrop = true
            pinView?.draggable = false // only works for after the pin is place (not what we're doing)
        }
        else {
            pinView!.annotation = annotation
            //TODO: make pins a consistent color
            pinView?.pinTintColor = UIColor.blueColor()
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        _ = makeMapDictionary()
        saveMapInfo()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // Use this "select" function to tap the pin
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        saveMapInfo()
        // Not sure why, but unless the annotation is deselected, it is not selectable if returning from the collection view
        mapView.deselectAnnotation(view.annotation, animated: false)

        self.performSegueWithIdentifier("fromMap", sender: view.annotation)
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        //
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let pin = sender as! Pin
        let pinIDString = pin.title!
        let pinURI = NSURL(string: pinIDString)
        let pinID = sharedContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(pinURI!)
        do {
            currentPin = try sharedContext.existingObjectWithID(pinID!) as? Pin
        } catch {
            print("Error: \(error)")
        }
        if let collectionEditor = segue.destinationViewController as? CollectionEditor {
            collectionEditor.coordinates = pin.coordinate
            if currentPin != nil {
                collectionEditor.currentPin = currentPin
            } else {
                print("Segueing to maps, but there is no currentPin!")
            }
        } else {
            print("segue to CollectionEditor fail")
        }
    }
    
    //MARK:-Core Data Functions
    
    func fetchPins() -> [Pin] {
        var pinArray = [Pin]()
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            pinArray = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("Error in fetchPins request: \(error)")
        }
        return pinArray
    }
    
    func fetchMapInfo() -> MapViewInfo {
        let fetchRequest = NSFetchRequest(entityName: "MapViewInfo")
        do {
            let infoArray = try sharedContext.executeFetchRequest(fetchRequest) as! [MapViewInfo]
            if infoArray.count > 0 {
                return infoArray[0]
            } else {
                print("No objects in fetchMapInfo request")
                NSEntityDescription.insertNewObjectForEntityForName("MapViewInfo", inManagedObjectContext: sharedContext) as! MapViewInfo
                let defaultInfo = makeMapDictionary()
                return MapViewInfo(dictionary: defaultInfo, context: sharedContext)
            }
        } catch let error as NSError {
            print("Error in fetchMapInfo(): \(error)")
            let defaultInfo = makeMapDictionary()
            return MapViewInfo(dictionary: defaultInfo, context: sharedContext)
        }
    }
    
    func saveMapInfo() {
        let info = makeMapDictionary()
        deleteMapInfo()
        _ = NSFetchRequest(entityName: "MapViewInfo")
        
        
        let mapInfo = NSEntityDescription.insertNewObjectForEntityForName("MapViewInfo", inManagedObjectContext: sharedContext) as! MapViewInfo
        
        mapInfo.lat = NSNumber(double: map.centerCoordinate.latitude)
        mapInfo.lon = NSNumber(double: map.centerCoordinate.longitude)
        mapInfo.latDelta = NSNumber(double: map.region.span.latitudeDelta)
        mapInfo.lonDelta = NSNumber(double: map.region.span.longitudeDelta)
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func deleteMapInfo() {
        let fetchRequest = NSFetchRequest(entityName: "MapViewInfo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
        do {
            try sharedContext.executeRequest(deleteRequest)
        } catch let error as NSError {
            print("Error in deleteMapInfo: \(error)")
        }
    }
    
    // make dict for map info values
    func makeMapDictionary() -> [String : AnyObject] {
        
        let mapDictionary = [
            "lat": NSNumber(double: map.centerCoordinate.latitude),
            "lon": NSNumber(double: map.centerCoordinate.longitude),
            "latDelta": NSNumber(double: map.region.span.latitudeDelta),
            "lonDelta": NSNumber(double: map.region.span.longitudeDelta),
            "zoom": NSNumber(double: 1.0)
        ]
        
        return mapDictionary
    }
}
