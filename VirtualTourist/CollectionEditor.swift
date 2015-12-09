//
//  CollectionEditor.swift
//  VirtualTourist
//
//  Created by David Fierstein on 11/27/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit
import MapKit

class CollectionEditor: UIViewController, MKMapViewDelegate, UICollectionViewDelegate {

    var coordinates : CLLocationCoordinate2D?


    @IBOutlet weak var mapView: MKMapView!
    //@IBOutlet weak var coordinatesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let span = MKCoordinateSpanMake(0.25, 0.25)
        //coordinatesLabel.text = coordinatesText
        if coordinates != nil {
            //let coordinatesText = String(coordinates?.latitude) + ", " + String(coordinates?.longitude)
            //coordinatesLabel.text! = coordinatesText
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
        //print("in vfa")
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
        // Get the new view controller using segue.destinationViewController.
        if let collectionViewController = segue.destinationViewController as? CollectionViewController {
            collectionViewController.coordinates = coordinates
        } else {
            print("segue to CollectionViewController fail")
        }
    }
}
