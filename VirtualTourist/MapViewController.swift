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
        //setupNav()
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "readAndDisplayAnnotations", name: refreshNotificationKey, object: nil)
//        navigationController?.title = "On The Map"
        //TODO: read in location and zoom from persisted MapViewInfo object
        map.delegate = self
        let longpress = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longpress.minimumPressDuration = 0.7
        map.addGestureRecognizer(longpress)
    }
    
    override func viewWillAppear(animated: Bool) {
        let mapInfo = fetchMapInfo()
        //let mapInfo = NSEntityDescription.insertNewObjectForEntityForName("MapViewInfo", inManagedObjectContext: sharedContext) as! MapViewInfo
        //        mapInfo.lat = map.centerCoordinate.latitude
        //        mapInfo.lon = map.centerCoordinate.longitude
        //        mapInfo.latDelta = map.region.span.latitudeDelta
        //        mapInfo.lonDelta = map.region.span.longitudeDelta
        map.centerCoordinate.latitude = Double(mapInfo.lat!)
        map.centerCoordinate.longitude = Double(mapInfo.lon!)
        let mapSpan = MKCoordinateSpanMake(Double(mapInfo.latDelta!), Double(mapInfo.lonDelta!))
        map.region = MKCoordinateRegionMake(map.centerCoordinate, mapSpan)
        
        print("VWA")
        print(Double(mapInfo.lat!))
        print(Double(mapInfo.lon!))
        //let mapRegion = MKMapSizeMake(Double(mapInfo.lonDelta!), Double(mapInfo.latDelta!))
        //CoreDataStackManager.sharedInstance().saveContext()
        
        let pinArray = fetchPins()
        displayPins(pinArray)
    }
    
    override func viewDidAppear(animated: Bool) {
        //readAndDisplayAnnotations()
    }//        var sharedContext: NSManagedObjectContext {
//            return CoreDataStackManager.sharedInstance().managedObjectContext
//        }

    
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        if (annotation is MKUserLocation) {
//            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
//            //return nil so map draws default view for it (eg. blue dot)...
//            return nil
//        }
//        
//        let reuseId = "test"
//        
//        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
//        if anView == nil {
//            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//            anView?.image = UIImage(named:"xaxas")
//            anView?.canShowCallout = true
//        }
//        else {
//            //we are re-using a view, update its annotation reference...
//            anView?.annotation = annotation
//        }
//        
//        return anView
//    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began { // allows only 1 pin per touch
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            annotation.title = String(newCoordinates)// as String
            map.addAnnotation(annotation)
            print(newCoordinates.latitude)
            print(newCoordinates.longitude)
            
            // Add a new Pin object to data store
            // First, create a dictionary to init the Pin
            let pinDictionary = [
                "lat": NSNumber(double: newCoordinates.latitude),
                "lon": NSNumber(double: newCoordinates.longitude)
            ]
            
            currentPin = Pin(dictionary: pinDictionary, context: sharedContext)
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
                let name = String(lat) + ", " + String(lon)
                
                // Here we create the annotation and set its coordiate, title, and subtitle properties
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title =  name
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
    /*
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            var touchPoint = gestureRecognizer.locationInView(mapView)
            var newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoder failed with error" + error!.localizedDescription)
                    return
                }
                
                if placemarks!.count > 0 {
                    let pm = placemarks![0]
                    
                    // not all places have thoroughfare & subThoroughfare so validate those values
                    annotation.title = pm.thoroughfare! + ", " + pm.subThoroughfare!
                    annotation.subtitle = pm.subLocality
                    self.mapView.addAnnotation(annotation)
                    print(pm)
                }
                else {
                    annotation.title = "Unknown Place"
                    self.mapView.addAnnotation(annotation)
                    print("Problem with the data received from geocoder")
                }
                places.append(["name":annotation.title,"latitude":"\(newCoordinates.latitude)","longitude":"\(newCoordinates.longitude)"])
            })
        }
    }
    */
//    func readAndDisplayAnnotations() {
//        if let _studentInfoArray = OnTheMapData.sharedInstance.studentInfoArray {
//            
//            // We will create an MKPointAnnotation for each dictionary in "locations". The
//            // point annotations will be stored in this array, and then provided to the map view.
//            var annotations = [MKPointAnnotation]()
//            
//            for studentInfo in _studentInfoArray {
//                
//                let lat = CLLocationDegrees(studentInfo.lat!)
//                let lon = CLLocationDegrees(studentInfo.lon!)
//                
//                // The lat and long are used to create a CLLocationCoordinates2D instance.
//                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//                let name = studentInfo.firstName! + " " + studentInfo.lastName!
//                
//                // Here we create the annotation and set its coordiate, title, and subtitle properties
//                let annotation = MKPointAnnotation()
//                annotation.coordinate = coordinate
//                annotation.title =  name
//                if let linkString = studentInfo.link {
//                    let mediaURL = "\(linkString)"
//                    annotation.subtitle = mediaURL
//                }
//                // Finally we place the annotation in an array of annotations.
//                annotations.append(annotation)
//            }
//            
//            // When the array is complete, we add the annotations to the map.
//            self.mapView.addAnnotations(annotations)
//        } else {
//            //print("studentInfo nil?")
//        }
//    }
    
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
            pinView?.animatesDrop = true
            pinView?.draggable = true
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
    
//    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
//        switch (newState) {
//        case .Starting:
//            view.dragState = .Dragging
//        case .Ending, .Canceling:
//            view.dragState = .None
//        default: break
//        }
//    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("regionChanged")
        let info = makeMapDictionary()
        print(info)
        saveMapInfo()

        //TODO: save this info into core data, replacing the existing object if there is one
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        //TODO: Save MapViewInfo object to core data
        saveMapInfo()
        model.photoArray?.removeAll() // ensure that we don't see images from a previous pin by deleting them
        flickr.getFlickrImagesForCoordinates((annotationView.annotation?.coordinate)!) { success, error in
            if success {
                print("Flickr Success")
            }
        }
        self.performSegueWithIdentifier("fromMap", sender: annotationView.annotation)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let pin = sender as! MKAnnotation
        if let collectionEditor = segue.destinationViewController as? CollectionEditor {
//            let coordinatesText = String(pin.coordinate.latitude) + ", " + String(pin.coordinate.longitude)
//            collectionEditor.coordinatesText = coordinatesText

            collectionEditor.coordinates = pin.coordinate
            collectionEditor.currentPin = currentPin
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
            //var infoArray = try sharedContext.executeFetchRequest(fetchRequest) as! [MapViewInfo]
            //if infoArray.count == 0 {
                //print("count was 0")
                let mapInfo = NSEntityDescription.insertNewObjectForEntityForName("MapViewInfo", inManagedObjectContext: sharedContext) as! MapViewInfo
                //NSEntityDescription.insertNewObjectForEntityForName("MapViewInfo", inManagedObjectContext: sharedContext) as! MapViewInfo
                mapInfo.lat = NSNumber(double: map.centerCoordinate.latitude)
                mapInfo.lon = NSNumber(double: map.centerCoordinate.longitude)
                mapInfo.latDelta = NSNumber(double: map.region.span.latitudeDelta)
                mapInfo.lonDelta = NSNumber(double: map.region.span.longitudeDelta)
                mapInfo.zoom = NSNumber(double: 1.0)
//            } else {
//                print("Non-zero count: \(infoArray.count)")
//            }
            //infoArray[0] = MapViewInfo(dictionary: info, context: sharedContext)
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