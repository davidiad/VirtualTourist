//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by David Fierstein on 11/24/15.
//  Copyright © 2015 David Fierstein. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        saveContext()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        saveContext()
    }

    func applicationWillTerminate(application: UIApplication) {
        saveContext()
    }
    
    //MARK:- Save Managed Object Context helper
    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            _ = try? self.sharedContext.save()
        }
    }
}

