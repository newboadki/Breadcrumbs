1. WHAT THE APP DOES
2. OVERALL ARCHITECTURE
3. COMPROMISES
--------------------------------




1. WHAT THE APP DOES --
- The application is listening for location updates through the standard service, using deferred updates
in the background when possibe. There are checks to discard low-accuracy, and too close to the previous position readings.

- When a location change is considered valid, then the app will request image metadata for that location in the background.

- I have intentionally avoided to request images in the background. Even, if I could have have requested them in the background like with the metadata,
in order to save battery I let the user-interface request images on demand. This is because I assume, during a walk, the user will not look at the images
 as often as each 100m. Once the user takes the phone out, images will be requested as she scrolls, only for the visible images.

- Images get cached once downloaded.


2. OVERALL ARCHITECTURE --

- AppDelegate: I have used the appDelegate to instantiate and connect the rest of components. It also passes some notifications on to other components.

- A viewController, the user interface, interacts with the locationManager and requests data from a controller behind a protocol (HikeController).
   -> It asks the LocationManager to start and stop location updates as per user request.
   -> It requests data from the HikeController and receives it inmediatelly if cached or via delegation if an asynchronous requests needs to be performed.

- HikeController represents the logic for the main use case in the app. It coordinates the retrieval of metadata and images as well as the
interaction with the storage manager.

- StoreManager. Caches the images.

- LocationManager. Encapsulates the complexity of dealing with CoreLocationManager, configures it according to the application state and filters out
invalid locations.



3. COMPROMISES --

- Battery life vs location accuracy. I have not aimed to get the best accuracy possible in the device.
- I have not used any complex algorithms to improve accuracy based on previous locations, speed and accuracy of the measurement.
- I have not kept into account, changes in altitude.
- I have delayed the retrieval of the images to be on-demand, requested by the UI. Only metadata is retrieved in the
background to minimise radio consuption during the walk.
- More complex persistence solutions like CoreData might be a better option in real applications.
- I am simply keeping the images in disk and have a StorageManager to access them.
- I have not implemented the concept of a Hike with a set of images, so that they could be persisted and shown again. After the app it quit,
the state is reset and the in-memory StorageManager is deleted.
- Error handling should be done exhaustively in a real application.
- No unit testing.
