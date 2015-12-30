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
let CONTENT_TYPE = "1"
let MEDIA = "photos"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

let PER_PAGE_DEFAULT = 21

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient() // makes this class a singleton
    let model = VirtualTouristModel.sharedInstance
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    var totalPhotos: Int?
    var photoDownloadCounter: Int = 21 //default to 21 images -- will be updated each time a collection view is opened.
    
    // A bit awkward to use getTotal to toggle whether to get the total # of photos, or to get a set of 21 photos. But avoids repeat of most of the code in this func. Is there a better way?
    // fist time calling this, accuracy is set to 16. If no photos returned, reduce accuracy by 1 and call again until at least 1 photo is returned
    /* Flickr.api accuracy reference. Probably go no lower than about 5 (what's the point of searching the entire World from 1 coordinate?)
    World level is 1
    Country is ~3
    Region is ~6
    City is ~11
    Street is ~16
    */
    func getFlickrImagesForCoordinates(coordinates: CLLocationCoordinate2D, getTotal: Bool, completion: (success: Bool, error: NSError?) -> Void) {
        let lat = String(coordinates.latitude)
        let lon = String(coordinates.longitude)
        
        //TODO: if no photos are found, reduce this accuracy number and try again
        var accuracy = "16"
        var per_page = String(PER_PAGE_DEFAULT)
        var page = "1"
        
        // calculate which page to use
        if totalPhotos != nil {
            if totalPhotos > PER_PAGE_DEFAULT {
                if totalPhotos > 4000 {
                    totalPhotos = 4000
                }
                let pages = Int(totalPhotos! / PER_PAGE_DEFAULT)
                let randomPageIndex = Int(arc4random_uniform(UInt32(pages)))
                page = String(randomPageIndex)
                print("PAGE: \(page)")
            }
        }
        
        // if we are only trying to get the total # of photos, no need to get more than 1 page with 1 photo in it.
        if getTotal {
            per_page = "1"
        }
        
        /* 2 - API method arguments */
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "accuracy": accuracy,
            "content_type": CONTENT_TYPE,
            "media": MEDIA,
            "lat": lat,
            "lon": lon,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": per_page,
            "page": page
        ]
        
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
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
            if getTotal {
                // parse the total # of photos available
                guard let photosDictionary = parsedResult["photos"] as? NSDictionary
                else {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.setUIEnabled(enabled: true)
                        })
                        print("Cannot find key 'photos' in \(parsedResult)")
                        return
                }
                self.totalPhotos = Int((photosDictionary["total"] as? String)!)
                if self.totalPhotos == nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.setUIEnabled(enabled: true)
                    })
                    print("Cannot find key 'total' in \(parsedResult)")
                    return
                    
                } else {
                    print("total: \(self.totalPhotos)")
                    
                }
                
//                // calculate which page to use
//                if totalPhotos < 22 {
//                    page = "1"
//                } else {
//                    let pages = Int(totalPhotos / 21)
//                    let randomPageIndex = Int(arc4random_uniform(UInt32(pages)))
//                    page = String(randomPageIndex)
//                }
            } else { // We are getting the photos this time, not just the total # of photos
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
                        })
                        // handle error
                        print("Cannot find key 'url_m' in \(photo)")
                        return
                    }
                    self.model.photoArray?.append(imageUrlString)
                }
                completion(success: true, error: nil)
            }
//            /* 7 - Generate a random number, then select a random photo */
//            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
//            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
//            let photoTitle = photoDictionary["title"] as? String /* non-fatal */
//            
//            /* GUARD: Does our photo have a key for 'url_m'? */
//            guard let imageUrlString = photoDictionary["url_m"] as? String else {
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.setUIEnabled(enabled: true)
//                })
//                print("Cannot find key 'url_m' in \(photoDictionary)")
//                return
//            }
//            
//            /* 8 - If an image exists at the url, set the image and title */
//            let imageURL = NSURL(string: imageUrlString)
//            if let imageData = NSData(contentsOfURL: imageURL!) {
//                dispatch_async(dispatch_get_main_queue(), {
//                    //                    self.setUIEnabled(enabled: true)
//                    //                    self.photoImageView.image = UIImage(data: imageData)
//                    //                    self.photoTitle.text = photoTitle ?? "(Untitled)"
//                })
//            } else {
//                print("Image does not exist at \(imageURL)")
//            }
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                print("A download completed")
//                self.photoDownloadCounter -= 1
//                if self.photoDownloadCounter <= 0 {
//                    // reset counter
//                    self.photoDownloadCounter = 21
//                    // send notice that bottomButton can now be enabled
//                }
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        
        return task
    }
    
    // SOme possible code for background downloading of images
//    func backgroundFetch(){
//        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
//        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//        
//        //dispatch in background HERE
//        dispatch_async(backgroundQueue) {
//            let path = self.directoryPath()
//            let pathArray = [path, "\(self.id)"]
//            let filePath = NSURL.fileURLWithPathComponents(pathArray)!
//            
//            let fileManager = NSFileManager()
//            
//            if fileManager.fileExistsAtPath(filePath.path!) == false {
//                //download to documents directory, if image doesn't exist yet
//                let downloadedImage = NSData(contentsOfURL: NSURL(string:self.url)!)
//                downloadedImage?.writeToURL(filePath, atomically: true)
//            }
//        }
//    }

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
    
    /* prev
    func getFlickrImagesForCoordinates(coordinates: CLLocationCoordinate2D, completion: (success: Bool, error: NSError?) -> Void) {
        
        let lat = String(coordinates.latitude)
        let lon = String(coordinates.longitude)
        
        /* 2 - API method arguments */
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "accuracy": ACCURACY,
            "content_type": CONTENT_TYPE,
            "media": MEDIA,
            "lat": lat,
            "lon": lon,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": PER_PAGE,
            "page": PAGE
        ]
        
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
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
                        //                        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: self.sharedContext)!
                        //                        let photo = Photo(entity: entity, insertIntoManagedObjectContext: self.sharedContext)
                        //                        //photo.pin = self.currentPin
                        //                        photo.url = url
                    })
                    // handle error
                    print("Cannot find key 'url_m' in \(photo)")
                    return
                }
                self.model.photoArray?.append(imageUrlString)
            }
            completion(success: true, error: nil)
            
            //            /* 7 - Generate a random number, then select a random photo */
            //            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            //            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
            //            let photoTitle = photoDictionary["title"] as? String /* non-fatal */
            //
            //            /* GUARD: Does our photo have a key for 'url_m'? */
            //            guard let imageUrlString = photoDictionary["url_m"] as? String else {
            //                dispatch_async(dispatch_get_main_queue(), {
            //                    self.setUIEnabled(enabled: true)
            //                })
            //                print("Cannot find key 'url_m' in \(photoDictionary)")
            //                return
            //            }
            //
            //            /* 8 - If an image exists at the url, set the image and title */
            //            let imageURL = NSURL(string: imageUrlString)
            //            if let imageData = NSData(contentsOfURL: imageURL!) {
            //                dispatch_async(dispatch_get_main_queue(), {
            //                    //                    self.setUIEnabled(enabled: true)
            //                    //                    self.photoImageView.image = UIImage(data: imageData)
            //                    //                    self.photoTitle.text = photoTitle ?? "(Untitled)"
            //                })
            //            } else {
            //                print("Image does not exist at \(imageURL)")
            //            }
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    */
}

