//
//  MapViewController.swift
//  On The Map
//
//  Created by David Fierstein on 9/30/15.
//  Copyright (c) 2015 David Fierstein. All rights reserved.
//

import UIKit
import MapKit

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
    
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        //setupNav()
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "readAndDisplayAnnotations", name: refreshNotificationKey, object: nil)
//        navigationController?.title = "On The Map"
        map.delegate = self
        let longpress = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longpress.minimumPressDuration = 0.7
        map.addGestureRecognizer(longpress)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        //readAndDisplayAnnotations()
    }
    
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
        }
//        if (annotation.state == UIGestureRecognizerState.Ended)
//        {
//            [self.mapView removeGestureRecognizer:sender];
//        }
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
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        if control == annotationView.rightCalloutAccessoryView {
//            let app = UIApplication.sharedApplication()
//            app.openURL(NSURL(string: (annotationView.annotation!.subtitle)!!)!)
//        }
        //let coordinates = annotationView.annotation?.coordinate
        performSegueWithIdentifier("fromMap", sender: annotationView.annotation)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let pin = sender as! MKAnnotation
        print("about to segue")
        if let collectionEditor = segue.destinationViewController as? CollectionEditor {
//            let coordinatesText = String(pin.coordinate.latitude) + ", " + String(pin.coordinate.longitude)
//            collectionEditor.coordinatesText = coordinatesText

            collectionEditor.coordinates = pin.coordinate
        } else {
            print("segue fail")
        }
        
        
    }
}
