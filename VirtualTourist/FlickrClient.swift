//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/3/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit
import MapKit
import CoreData

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "461697eded75e4c63f0a952aa1761c43"
let EXTRAS = "url_m"
let CONTENT_TYPE = "1"
let MEDIA = "photos"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let ACCURACY_DEFAULT = 16
let PER_PAGE_DEFAULT = 21
let RADIUS_DEFAULT = "32" // 32 is max allowed, in km

class FlickrClient: NSObject {

    //MARK:- Vars
    static let sharedInstance = FlickrClient() // makes this class a singleton
    let model = VirtualTouristModel.sharedInstance
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var totalPhotos: Int?
    var currentAccuracy: Int = ACCURACY_DEFAULT
    var noPhotosCanBeFound: Bool = false
    
    //MARK:- Flickr image fetch functions
    // When getTotal is true, only fetching the total # of photos
    // When getTotal is false, actually fetching the photos
    func getFlickrImagesForCoordinates(coordinates: CLLocationCoordinate2D, getTotal: Bool, accuracyInt: Int?, searchtext: String?,completion: (success: Bool, error: NSError?) -> Void) {
        let lat = String(coordinates.latitude)
        let lon = String(coordinates.longitude)
        
        var text: String = ""
        var accuracy = {
            String(accuracyInt ?? ACCURACY_DEFAULT)
        }()
        var per_page = String(PER_PAGE_DEFAULT)
        var page = "1"
        if searchtext != nil {
            text = "\(searchtext!)"
        }
        let min_date_upload = {
            // As accuracy is decreased, makeDate() increases the date range as well
            makeDate()
        }()
        let radius = {
            calculateRadius()
        }()

        // calculate which page to use
        if totalPhotos != nil {

            if totalPhotos > 0 {
                noPhotosCanBeFound = false
            }
            if totalPhotos > PER_PAGE_DEFAULT {
                // Even though the "total" may be over 4000, Flickr will only let you access the first 4000
                // So, limit the total to 4000, otherwise they send you duplicate photos
                if totalPhotos > 4000 {
                    totalPhotos = 4000
                }
                let pages = Int(totalPhotos! / PER_PAGE_DEFAULT)
                let randomPageIndex = Int(arc4random_uniform(UInt32(pages)))
                page = String(randomPageIndex)
            }
        }
        
        // if we are only trying to extract the total # of photos from the JSON, no need to get more than 1 page with 1 photo in it.
        if getTotal {
            per_page = "1"
            if totalPhotos != nil {
                // If no photos are found in the search, increase the search area
                if totalPhotos == 0 {
                    if noPhotosCanBeFound == false {
                        let decrementedAccuracy = Int(accuracy)! - 1
                        if decrementedAccuracy > 0 { // limit the range to no more than the Country
                            accuracy = String(decrementedAccuracy)
                            currentAccuracy = decrementedAccuracy
                        } else {
                            noPhotosCanBeFound = true
                        }
                    }
                }
            }
        }
        
        //  API method arguments
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": text,
            "accuracy": accuracy,
            "radius" : radius,
            "content_type": CONTENT_TYPE,
            "media": MEDIA,
            "lat": lat,
            "lon": lon,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": per_page,
            "page": page,
            "min_date_upload": min_date_upload
        ]
        
        // Initialize session and url
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        // Initialize task for getting data
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            // Check for a successful response
            // GUARD: Was there an error?
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            // - Parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // GUARD: Did Flickr return an error (stat != ok)?
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            if getTotal { // This time, we are just getting the total # of photos, not fetching any of them
                // parse the total # of photos available
                guard let photosDictionary = parsedResult["photos"] as? NSDictionary
                else {
                    print("Cannot find key 'photos' in \(parsedResult)")
                    return
                }
                self.totalPhotos = Int((photosDictionary["total"] as? String)!)
                if self.totalPhotos == nil {
                    print("Cannot find key 'total' in \(parsedResult)")
                    return
                } else {
                    completion(success: true, error: nil)
                }
                
            } else { // We are getting the photos this time, not just the total # of photos
                // GUARD: Are the "photos" and "photo" keys in our result?
                guard let photosDictionary = parsedResult["photos"] as? NSDictionary,
                    photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                        print("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                        return
                }
                
                // Put all of the url strings into an array, and pass that into the data model (not core data) to store
                self.model.photoArray?.removeAll()
                for photo in photoArray {
                    guard let imageUrlString = photo["url_m"] as? String else {
                        // handle error
                        print("Cannot find key 'url_m' in \(photo)")
                        return
                    }
                    self.model.photoArray?.append(imageUrlString)
                }
                completion(success: true, error: nil)
            }
        }
        
        // Resume (execute) the task
        task.resume()
    }
    
    // Task method for downloading individual images
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        
        return task
    }
    
    
    //MARK: Helper functions
    
    // Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // Convert date into unix timestamp format used by Flickr API
    func makeDate() -> String {
        // In order to increase the chance of finding photos if expanding the search due to no photos being found in the first run, extend the date further back with each reduction in accuracy
        let numDaysBeforeNow = (-300 * (16 - currentAccuracy)) + 1
        let userCalendar = NSCalendar.currentCalendar()
        
        let aTimeBeforeNow = userCalendar.dateByAddingUnit(
            [.Day],
            value: numDaysBeforeNow,
            toDate: NSDate(),
            options: [])!
        
        let epochTimestamp = String(aTimeBeforeNow.timeIntervalSince1970)
        return epochTimestamp
    }
    
    // Increase the search radius as accuracy is reduced
    func calculateRadius() -> String {
        if currentAccuracy < 10 {
            return RADIUS_DEFAULT
        } else {
            return String( (5 * (16 - currentAccuracy)) + 2 )
        }
    }
}
