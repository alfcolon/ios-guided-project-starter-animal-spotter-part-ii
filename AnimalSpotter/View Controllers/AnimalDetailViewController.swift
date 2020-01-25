//
//  AnimalDetailViewController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 6/18/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

class AnimalDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var timeSeenLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var animalImageView: UIImageView!
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDetails()
    }
    
    // MARK: - Properties
    
    var animalName: String?
    var apiController: APIController?
 
    // MARK: - Methods
    
    private func getDetails() {
        guard let animalName = animalName else { return }
        guard let apiController = apiController else { return }
        
        apiController.fetchDetails(for: animalName) { result in
            do {
                let animal = try result.get()
                DispatchQueue.main.async {
                    self.updateViews(with: animal)
                }
                apiController.fetchImage(at: animal.imageURL) { result in
                    if let image = try? result.get() {
                        DispatchQueue.main.async {
                            self.animalImageView.image = image
                        }
                    }
                }
            }
            catch {
                if let error = error as? NetworkError {
                    switch error {
                    case .badAuth:
                        print("Bearer token invalid")
                    case .badData:
                        print("No data receieved or data corrupted")
                    case .noAuth:
                        print("No bearer token exists")
                    case .noDecode:
                        print("JSON could not be decoded")
                    case .otherError:
                        print("Other error occured, see log")
                    }
                }
            }
        }
    }
    private func updateViews(with animal: Animal){
        title = animal.name
        descriptionLabel.text = animal.description
        coordinatesLabel.text = "lat: \(animal.latitude), long: \(animal.longitude)"
        
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short
        
        timeSeenLabel.text = df.string(from: animal.timeSeen)
    }
}
