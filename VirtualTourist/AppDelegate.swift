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
    
    //TODO:- delete unneeded commented code

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        saveContext()
//        do {
//            try sharedContext.save()
//        } catch {}
    }

    func applicationDidEnterBackground(application: UIApplication) {
        saveContext()
//        do {
//            try sharedContext.save()
//        } catch {}
    }

//    func applicationWillEnterForeground(application: UIApplication) {
//        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//    }
//
//    func applicationDidBecomeActive(application: UIApplication) {
//        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    }

    func applicationWillTerminate(application: UIApplication) {
        saveContext()
//        do {
//            try sharedContext.save()
//        } catch {}
    }
    
    //MARK:- Save Managed Object Context helper
    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            _ = try? self.sharedContext.save()
        }
    }
}

