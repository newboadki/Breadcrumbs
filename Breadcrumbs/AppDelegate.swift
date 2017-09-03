//
//  AppDelegate.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 25/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    fileprivate var locationManager : LocationManager!
    fileprivate var metadataService : FlickrMetadataService!
    fileprivate var imageService : FlickrImageDownloadService!
    fileprivate var storageManager: StorageManager!
    fileprivate var hikeUseCaseController: HikeController!
    fileprivate var imagesViewController: ViewController!
    
    internal var urlBackgroundSessionCompletionHandler: (() -> Void)?
    
    fileprivate let apiKey = "4a719ce81ad983e08eb55f4e71e92def"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Configure components and delegate relationships. Normally, I would encapsulate and abstrct away this kind
        // of code from the applicationDelegate.
        let navigationViewController = self.window?.rootViewController as! UINavigationController
        self.imagesViewController = navigationViewController.topViewController as! ViewController
        
        self.locationManager = LocationManager(distanceThreshold: 100, desiredAccuracy: 100)
        imagesViewController.locationManager = self.locationManager
        
        self.metadataService = FlickrMetadataService(apiKey: self.apiKey)
        
        self.imageService = FlickrImageDownloadService(apiKey: self.apiKey)
        
        self.storageManager = StorageManager()
        // In this code sample I have decided to not persist the index of images taken, so every launch is clean.
        // Therefore, at start, clear the images in the documents directory.
        self.storageManager.clearDocumentsDirectory(ofFilesWithPrefix: FlickrImageDownloadService.imageFilePrefix)
        self.storageManager.clearDocumentsDirectory(ofFilesWithPrefix: FlickrMetadataService.metadataFilePrefix)
        
        self.hikeUseCaseController = HikeController(locationManager: self.locationManager,
                                                    metadataService: self.metadataService,
                                                    imageService: self.imageService,
                                                    storageManager: self.storageManager,
                                                    viewController: imagesViewController)
        
        self.locationManager.delegate = self.hikeUseCaseController
        self.metadataService.downloadDelegate = self.hikeUseCaseController
        self.imageService.downloadDelegate = self.hikeUseCaseController
        imagesViewController.controller = self.hikeUseCaseController
        
        return true
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.urlBackgroundSessionCompletionHandler = completionHandler
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        self.locationManager.handleInactiveState()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.locationManager.handleActiveState()
        self.imagesViewController.handleApplicationDidBecomeActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

}

