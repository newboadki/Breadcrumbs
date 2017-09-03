//
//  ViewController.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 26/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import UIKit

protocol ListOfLocationImagesUserInterface: class {
    func handle(url: URL, for indexPath: IndexPath)
    func reload()    
    func handleApplicationDidBecomeActive()
}

class ViewController: UITableViewController, ListOfLocationImagesUserInterface {
        
    @IBOutlet weak var button: UIBarButtonItem!
    
    // Delegate object for location-related tasks
    var locationManager : LocationManager!
    
    /// Entry point for data related requests. I would normally consider hiding it behind a protocol.
    var controller: HikeController!
    
    /// Keeps the state of the start button.
    fileprivate var started : Bool = false
    
    
    
    // MARK: - View's life-cycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.handleApplicationDidBecomeActive()
    }

    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.controller.count()
    }

    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let imageCell = cell as? ImageCell {
            imageCell.theImageView.image = nil
            // If the image is already cached this method returns inmediatelly. Otherwise, we'll get notified via handle:url:for:
            if let url = self.controller.fetchImage(atIndexPath: indexPath), let data = try? Data(contentsOf: url) {
                
                let image = UIImage(data: data)
                imageCell.theImageView.image = image
            }
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        return cell
    }
}


extension ViewController {
    
    public func handle(url: URL, for indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    public func reload() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    public func handleApplicationDidBecomeActive() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if (self.started) {
                // This is to prevent potential errors, where we come from the background when the user left the service running, but the OS
                // might have decided to stop it.
                self.locationManager.startUpdates()
            }
        }
    }
}


// MARK:- Actions

extension ViewController {
    
    @IBAction func buttonPressed(_ sender: UIBarButtonItem) {
        
        // Toggle the state
        self.started = !self.started
        
        // Start/Stop location updates
        if self.started {
            self.locationManager.startUpdates()
            self.button.title = NSLocalizedString("Finish", comment: "Finish")
        } else {
            self.locationManager.stopUpdates()
            self.button.title = NSLocalizedString("Start", comment: "Start")
        }
    }
}
