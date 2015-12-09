//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by David Fierstein on 12/3/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit
import MapKit

/* from Sleeping in the Library
/* 1 - Define constants */
let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.galleries.getPhotos"
//let METHOD_NAME = "flickr.photos.geo.photosForLocation"  //requires auth
let API_KEY = "461697eded75e4c63f0a952aa1761c43"
let GALLERY_ID = "5704-72157622566655097"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
*/

/* 1 - Define constants */
let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
//let METHOD_NAME = "flickr.photos.geo.photosForLocation"  //requires auth
let API_KEY = "461697eded75e4c63f0a952aa1761c43"
//let GALLERY_ID = "5704-72157622566655097"
let EXTRAS = "url_m"
let ACCURACY = "16"
let MEDIA = "photos"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

var lat = "38.9047"
var lon = "77.0164"


class FlickrClient: NSObject {
    
    //TODO:- get the pictures based on the pin coordinates
    
    static let sharedInstance = FlickrClient()
    let model = VirtualTouristModel.sharedInstance
    
    func getFlickrImagesFromCoordinates(coordinates: CLLocationCoordinate2D) {
        
        lat = "\"" + String(coordinates.latitude) + "\""
        lon = "\"" + String(coordinates.longitude) + "\""
        
        /* 2 - API method arguments */
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "accuracy": ACCURACY,
            "media": MEDIA,
            "lat": lat,
            "lon": lon,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        
        //        let urlString = BASE_URL + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* 5 - Check for a successful response */
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("No data was returned by the request!")
                return
            }
            
            /* 6 - Parse the data (i.e. convert the data to JSON and look for values!) */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary,
                photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.setUIEnabled(enabled: true)
                    })
                    print("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                    return
            }
            
            // Put all of the url strings into an array, and pass that into the data model to store
            self.model.photoArray?.removeAll()
            
            for photo in photoArray {
                guard let imageUrlString = photo["url_m"] as? String else {
                    dispatch_async(dispatch_get_main_queue(), {
                        //
                    })
                    // handle error
                    print("Cannot find key 'url_m' in \(photo)")
                    return
                }
                self.model.photoArray?.append(imageUrlString)
            }
            
            /* 7 - Generate a random number, then select a random photo */
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
            let photoTitle = photoDictionary["title"] as? String /* non-fatal */
            
            /* GUARD: Does our photo have a key for 'url_m'? */
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("Cannot find key 'url_m' in \(photoDictionary)")
                return
            }
            
            /* 8 - If an image exists at the url, set the image and title */
            let imageURL = NSURL(string: imageUrlString)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                dispatch_async(dispatch_get_main_queue(), {
                    //                    self.setUIEnabled(enabled: true)
                    //                    self.photoImageView.image = UIImage(data: imageData)
                    //                    self.photoTitle.text = photoTitle ?? "(Untitled)"
                })
            } else {
                print("Image does not exist at \(imageURL)")
            }
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    func getImageFromFlickr() {
/* from Sleeping in the Library
        /* 2 - API method arguments */
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "gallery_id": GALLERY_ID,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
   */
        /* 2 - API method arguments */
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "accuracy": ACCURACY,
            "media": MEDIA,
            "lat": lat,
            "lon": lon,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
//        /* 2 - API method arguments */
//        let methodArguments = [
//            "method": METHOD_NAME,
//            "api_key": API_KEY,
//            "lat": 36.5,
//            "lon":  -122,
//            "accuracy": 12,
//            "extras": EXTRAS,
//            "format": DATA_FORMAT,
//            "nojsoncallback": NO_JSON_CALLBACK
//        ]
        
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)

//        let urlString = BASE_URL + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* 5 - Check for a successful response */
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("No data was returned by the request!")
                return
            }
            
            /* 6 - Parse the data (i.e. convert the data to JSON and look for values!) */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary,
                photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.setUIEnabled(enabled: true)
                    })
                    print("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                    return
            }
            
            // Put all of the url strings into an array, and pass that into the data model to store
            self.model.photoArray?.removeAll()
            
            for photo in photoArray {
                guard let imageUrlString = photo["url_m"] as? String else {
                    dispatch_async(dispatch_get_main_queue(), {
                        //
                    })
                    // handle error
                    print("Cannot find key 'url_m' in \(photo)")
                    return
                }
                self.model.photoArray?.append(imageUrlString)
            }
            
            /* 7 - Generate a random number, then select a random photo */
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
            let photoTitle = photoDictionary["title"] as? String /* non-fatal */
            
            /* GUARD: Does our photo have a key for 'url_m'? */
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.setUIEnabled(enabled: true)
                })
                print("Cannot find key 'url_m' in \(photoDictionary)")
                return
            }
            
            /* 8 - If an image exists at the url, set the image and title */
            let imageURL = NSURL(string: imageUrlString)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                dispatch_async(dispatch_get_main_queue(), {
//                    self.setUIEnabled(enabled: true)
//                    self.photoImageView.image = UIImage(data: imageData)
//                    self.photoTitle.text = photoTitle ?? "(Untitled)"
                })
            } else {
                print("Image does not exist at \(imageURL)")
            }
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    // Configure UI
    
    func setUIEnabled(enabled enabled: Bool) {
//        photoTitle.enabled = enabled
//        grabImageButton.enabled = enabled
//        
//        if enabled {
//            grabImageButton.alpha = 1.0
//        } else {
//            grabImageButton.alpha = 0.5
//        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
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
}
