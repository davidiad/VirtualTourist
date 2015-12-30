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

/**
* This view controller demonstrates the objects involved in displaying pins on a map.
*
* The map is a MKMapView.
* The pins are represented by MKPointAnnotation instances.
*
* The view controller conforms to the MKMapViewDelegate so that it can receive a method
* invocation when a pin annotation is tapped. It accomplishes this using two delegate
* methods: one to put a small "info" button on the right side of each pin, and one to
* respond when the "info" button is tapped.
*/

class MapViewController: UIViewController, MKMapViewDelegate {
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    let model = VirtualTouristModel.sharedInstance
    let flickr = FlickrClient.sharedInstance
    
    var currentPin: Pin?
    
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
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
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began { // allows only 1 pin per touch
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            map.addAnnotation(annotation)
            
            // Add a new Pin object to data store
            // First, create a dictionary to init the Pin
            let pinDictionary = [
                "lat": NSNumber(double: newCoordinates.latitude),
                "lon": NSNumber(double: newCoordinates.longitude)
            ]
            
            currentPin = Pin(dictionary: pinDictionary, context: sharedContext)
            // in order to get a permanent ID, can save the Pin into the context
            CoreDataStackManager.sharedInstance().saveContext()
            annotation.title = String(currentPin!.objectID.URIRepresentation())
            
            
            // fetch the photo url's for this Pin
            flickr.getFlickrImagesForCoordinates(newCoordinates, getTotal: true) { success, error in
                print("getTotal was true")
            }
            flickr.getFlickrImagesForCoordinates(newCoordinates, getTotal:  false) { success, error in
                if success {
                    for url in self.model.photoArray! {
                        dispatch_async(dispatch_get_main_queue(), {
                            let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: self.sharedContext)!
                            let photo = Photo(entity: entity, insertIntoManagedObjectContext: self.sharedContext)
                            photo.pin = self.currentPin
                            photo.url = url

                            let request = NSURLRequest(URL: NSURL(string: url)!)
                            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                                if let imageData = data as NSData? {
                                    //self.image = UIImage(data: imageData)
                                }
                            }
                        })
                    }
                } else {
                    print("Error in getting Flickr Images: \(error)")
                }
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
//        if (annotation.state == UIGestureRecognizerState.Ended)
//        {
//            [self.mapView removeGestureRecognizer:sender];
//        }
    }
    
    func displayPins(pinArray: [Pin]) {
            
            // We will create an MKPointAnnotation for each dictionary in "locations". The
            // point annotations will be stored in this array, and then provided to the map view.
            var annotations = [MKPointAnnotation]()
            
            for pin in pinArray {
                
                let lat = CLLocationDegrees(pin.lat!)
                let lon = CLLocationDegrees(pin.lon!)
                
                // The lat and long are used to create a CLLocationCoordinates2D instance.
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let name = String(pin.objectID.URIRepresentation())   //String(lat) + ", " + String(lon)
                
                //sharedContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(pin.objectID)
                // Here we create the annotation and set its coordiate, title, and subtitle properties
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = name
                // Finally we place the annotation in an array of annotations.
                annotations.append(annotation)
            }
            
            // When the array is complete, we add the annotations to the map.
            map.addAnnotations(annotations)
    }

    
//    func tapPin(gestureRecognizer: UITapGestureRecognizer) {
//        let pinView = gestureRecognizer.view as! MKAnnotation
//        print("tapped")
//        print(pinView.coordinate)
//        performSegueWithIdentifier("fromMap", sender: pinView)
//    }
    
    func dragPin(gestureRecognizer: UIPanGestureRecognizer) {
        print("Drag!")
        let touchPoint = gestureRecognizer.locationInView(map)
        let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UITapGestureRecognizer {
            return true
        } else {
            return false
        }
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
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.brownColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView?.animatesDrop = false
            //pinView?.draggable = true // only works for after the pin is place (not what we're doing)
        }
        else {
            pinView!.annotation = annotation
            pinView?.pinTintColor = UIColor.blueColor()
        }
        //let pintap = UIPanGestureRecognizer(target: self, action: "tapPin:")
        //let pindrag = UIPanGestureRecognizer(target: self, action: "dragPin:")
        //pinView!.addGestureRecognizer(pintap)
        //pinView!.addGestureRecognizer(pindrag)
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
//        switch (newState) {
//        case .Starting:
//            view.dragState = .Dragging
//        case .Ending, .Canceling:
//            view.dragState = .None
//        default: break
//        }
        
        switch (newState) {
        case .Starting:
            
            if let startPin = view.annotation as? Pin {
                //delete the old photos here
                //or other code
            }
            
        case .Ending, .Canceling:
            
            if let endPin = view.annotation as? Pin {
                //get new photos
                //or other code
            }
        default: break
        }
  }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        _ = makeMapDictionary()
        saveMapInfo()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
//    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        
//        //TODO: Save MapViewInfo object to core data
//        saveMapInfo()
//        model.photoArray?.removeAll() // ensure that we don't see images from a previous pin by deleting them
//        flickr.getFlickrImagesForCoordinates((annotationView.annotation?.coordinate)!) { success, error in
//            if success {
//                print("Flickr Success")
//            }
//        }
//        self.performSegueWithIdentifier("fromMap", sender: annotationView.annotation)
//    }
    
    // Use this "select" function to tap the pin
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        saveMapInfo()
        /* I see no need to getFlickrImages again. They should already be stored, when the pin was added, whether this is a brand new pin, or a pre-existing one. But are the photos downloaded at this point?
        model.photoArray?.removeAll() // ensure that we don't see images from a previous pin by deleting them
        //TODO: Should be able to delete this photoArray, and get images directly from core data
        flickr.getFlickrImagesForCoordinates((view.annotation?.coordinate)!, getTotal: true) { success, error in
            print("getTotal was true")
        }
        flickr.getFlickrImagesForCoordinates((view.annotation?.coordinate)!, getTotal: false) { success, error in
            if success {
                print("Flickr Success")
            }
        }*/
        self.performSegueWithIdentifier("fromMap", sender: view.annotation)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //TODO: Not associating this pin with a managed object, therefore Pin doesn't get sent, and crash when Pin optional is force-unwrapped in CollectionViewController. Only happens when first launching app, but with saved core data (?)
        let pin = sender as! MKAnnotation
        let pinIDString = pin.title!
        let pinURI = NSURL(string: pinIDString!)
        let pinID = sharedContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(pinURI!)
        do {
            currentPin = try sharedContext.existingObjectWithID(pinID!) as? Pin
        } catch {
            print("Error: \(error)")
        }
        if let collectionEditor = segue.destinationViewController as? CollectionEditor {
            collectionEditor.coordinates = pin.coordinate
            print("pin.coordinate: \(pin.coordinate)")
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
            print("Pins: \(pinArray.count)")
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
        print("in saveMapInfo")
        print(info)
        deleteMapInfo()
        _ = NSFetchRequest(entityName: "MapViewInfo")
//        do {

                let mapInfo = NSEntityDescription.insertNewObjectForEntityForName("MapViewInfo", inManagedObjectContext: sharedContext) as! MapViewInfo

                mapInfo.lat = NSNumber(double: map.centerCoordinate.latitude)
                mapInfo.lon = NSNumber(double: map.centerCoordinate.longitude)
                mapInfo.latDelta = NSNumber(double: map.region.span.latitudeDelta)
                mapInfo.lonDelta = NSNumber(double: map.region.span.longitudeDelta)
                mapInfo.zoom = NSNumber(double: 1.0)
//            } else {
//                print("Non-zero count: \(infoArray.count)")
//            }
            CoreDataStackManager.sharedInstance().saveContext()
        
//        } catch let error as NSError {
//            print("Error in saveMapInfo(): \(error)")
//        }
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
    
//    func fetchAllActors() -> [Person] {
//        let fetchRequest = NSFetchRequest(entityName: "Person")
//        do {
//            return try sharedContext.executeFetchRequest(fetchRequest) as! [Person]
//        } catch let error as NSError {
//            print("Error in fetchAllActors(): \(error)")
//            return [Person]()
//        }
//    }
}
