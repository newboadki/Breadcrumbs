//
//  LocationManager.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 25/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import Foundation
import CoreLocation


/// Conforming classes will handle specific location events related to this application.
protocol LocationManagerDelegate : class {
    
    /// Notifies the delegate that the passed coordinate meets the conditions with wich
    /// the location manager ws configured.
    ///
    /// - Parameters:
    ///   - latitude: Latitude
    ///   - longitude: Longitude
    func positionThresholdMet(atLatitude latitude: Double, andLongitude longitude: Double)
    
    /// This method gets called when there's a non-recoverable error.
    ///
    /// - Parameter error: Non-recoverable error.
    func handle(error: LocationRetrievalError)
}



enum LocationRetrievalError : Error {
    case serviceDisabled
    case serviceOnlyAllowedOnForeground
}


/// Encapsulates the logic to configure the geo-location hardware and filter those locations that are 
/// considered of interest for this particular application.
///
/// Whenever possible deferrered updates are enabled.
class LocationManager : NSObject {
    
    /// Instance of CoreLocation's framework location manager.
    var coreLocationManager : CLLocationManager!
    
    /// Delegate instance to will receive location updates and erros.
    weak var delegate : LocationManagerDelegate?
    
    /// Determines the distance that new location updates should have with respect the previous updates to be notified.
    fileprivate var distanceThreshold: CLLocationDistance
    
    /// Desired accuracy of the meassurements that CoreLocation will provide.
    fileprivate var desiredAccuracy: CLLocationAccuracy
    
    /// Indicates if the system has been requested to defer updates.
    fileprivate var deferringLocationUpdates : Bool = false
    
    /// Instance of a timer to schedule of location updates for those cases where the system choses to turn them off.
    fileprivate var updateReschedulingtimer : Timer?
    
    /// Indicates if this class if operating while the app is in the background.
    fileprivate var isInBackground: Bool = false
    
    /// Keeps track of whether location updates are on.
    private var started: Bool = false

    
    
    // MARK: Initializers
    
    /// Designated initializer
    ///
    /// - Parameters:
    ///   - distanceThreshold: Determines the distance that new location updates should have with respect the previous updates to be notified.
    ///   - desiredAccuracy: Desired accuracy of the meassurements that CoreLocation will provide.
    required init(distanceThreshold:CLLocationDistance, desiredAccuracy: CLLocationAccuracy) {
        self.coreLocationManager = CLLocationManager()
        self.coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.distanceThreshold = distanceThreshold
        self.desiredAccuracy = desiredAccuracy
        self.coreLocationManager.distanceFilter = distanceThreshold; // meters
        self.coreLocationManager.activityType = .fitness
        self.coreLocationManager.pausesLocationUpdatesAutomatically = true
        super.init()
        self.coreLocationManager.delegate = self
    }
    
    
    
    // MARK: Public API
    
    /// Call this method to start location updates
    func startUpdates() {
        self.started = true
        self.coreLocationManager.requestAlwaysAuthorization()
        self.coreLocationManager.startUpdatingLocation()
    }
    
    /// Call this method to stop location updates
    func stopUpdates() {
        self.coreLocationManager.stopUpdatingLocation()
        self.started = false
    }
    
    /// Call this method to inform this class that it should handle the application resigning active
    func handleInactiveState() {
        self.isInBackground = true
        self.coreLocationManager.pausesLocationUpdatesAutomatically = false
        self.coreLocationManager.allowsBackgroundLocationUpdates = true
    }

    /// Call this method to inform this class that it should handle the application becoming active
    func handleActiveState() {
        self.isInBackground = false
        self.coreLocationManager.pausesLocationUpdatesAutomatically = true
        self.coreLocationManager.allowsBackgroundLocationUpdates = false // The documentation encourages this behaviour        
    }
}



// MARK:- Helpers

fileprivate extension LocationManager {
    
    /// Convenience method to start deferring updates
    /// Updates will only be deferred if not active and when in the background.
    func deferUpdates() {
        if !self.deferringLocationUpdates && self.isInBackground {
            self.deferringLocationUpdates = true
            self.coreLocationManager.allowDeferredLocationUpdates(untilTraveled: self.distanceThreshold, timeout: 60) // in seconds
        }
    }
}



// MARK:- CLLocationManagerDelegate Protocol

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Try to defer updates whenever possible
        self.deferUpdates()
        
        // CoreLocation will stack updates, specially when deferring updates.
        // Discard the update if it does not respect the requested accuracy
        for location in locations {

            // Discard measurament with low accuracy.
            if location.horizontalAccuracy > self.desiredAccuracy {
                continue
            }
            
            // Process the location
            self.delegate?.positionThresholdMet(atLatitude: location.coordinate.latitude, andLongitude: location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if error is CLError,
           let cle = error as? CLError {
            
            switch cle.code {
                case .denied:
                    // The service has been disabled by the user, we stop tracking location
                    self.coreLocationManager.stopUpdatingLocation()
                    self.delegate?.handle(error: .serviceDisabled)
                    break
                case .deferredFailed, .deferredNotUpdatingLocation, .deferredAccuracyTooLow, .deferredDistanceFiltered, .deferredCanceled:
                    self.deferringLocationUpdates = false
                    break

                default:
                    // We are ignoring other types of errors here.
                    break
            }
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        
        self.stopUpdates()
        
        // The system considers that the updates can be turned off beucase the user is unlikely to be moving.
        // Schedule updates to start again in 2 minutes. This number should be better tuned.
        // An alternative would be to schedule a geo-barrier and a notification, but it requires when-in-use authorization.
        self.updateReschedulingtimer?.invalidate()
        self.updateReschedulingtimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false, block: { [unowned self] (timer) in
            self.startUpdates()
        })
    }

    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        self.deferringLocationUpdates = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
            case .authorizedWhenInUse:
                // Notifiy delegate the app will work with restrictions
                self.delegate?.handle(error: .serviceOnlyAllowedOnForeground)
                break
            case .authorizedAlways:
                // No action, that app can work
                break
            case .denied, .restricted, .notDetermined:
                // Notify delegate the app won't be able to track the user's path
                self.stopUpdates()
                self.delegate?.handle(error: .serviceDisabled)
                break
        }
    }
}
