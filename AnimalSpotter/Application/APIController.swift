//
//  APIController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 4/16/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

class APIController {
    
    private let baseUrl = URL(string: "https://lambdaanimalspotter.vapor.cloud/api")!
    var bearer: Bearer?
    
    func signUp(with user: User, completion: @escaping (Error?) -> ()) {
        let signUpUrl = baseUrl.appendingPathComponent("users/signup")
        
        var request = URLRequest(url: signUpUrl)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            print("Error encoding user object: \(error)")
            completion(error)
            return
        }
        URLSession.shared.dataTask(with: request) { (_, response, error) in
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError(domain: "", code: response.statusCode, userInfo:nil))
                return
            }
            
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    func signIn(with user: User, completion: @escaping (Error?) -> ()) {
        let loginUrl = baseUrl.appendingPathComponent("users/login")
        
        var request = URLRequest(url: loginUrl)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            print("Error encoding user object: \(error)")
            completion(error)
            return
        }
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError(domain: "", code: response.statusCode, userInfo:nil))
                return
            }
            
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(NSError())
                return
            }
            
            let decoder = JSONDecoder()
            do {
                self.bearer = try decoder.decode(Bearer.self, from: data)
            } catch {
                print("Error decoding bearer object: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    // create function for fetching all animal names

    func fetchAllAnimalNames(completion: @escaping (Result<[String], NetworkError>) -> Void) {
        //check for bearer token
        guard let bearer = bearer else { completion(.failure(.noAuth)); return }
        
        //MARK: - Get URL Request Ready
        
        let allAnimalsURL = baseUrl.appendingPathComponent("animals/all")
        var request = URLRequest(url: allAnimalsURL)
        
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            //Downcast to HTTPURLResponse to read status code
            let response = response as? HTTPURLResponse
            
            //MARK: - Error Check
            
            switch true {
            case response!.statusCode == 401:
                completion(.failure(.badAuth))
                return
            case error != nil: //something went wrong with connection or other
                print("Error receiving animal name data: \(error!)")
                completion(.failure(.otherError))
                return
            case data == nil:
                completion(.failure(.badData))
                return
            default:
                break
            }
            
            //MARK: -  Decode Data
            
            let decoder = JSONDecoder()
            
            do {
                let animalNames = try decoder.decode([String].self, from: data!)
                completion(.success(animalNames)) }
            catch {
                print("Error decoding animal objects: \(error)")
                completion(.failure(.noDecode))
                return }
        }
        task.resume()
    }
    // create function for fetching a specific animal
    
    func fetchDetails(for animalName: String, completion: @escaping (Result<Animal, NetworkError>) -> Void) {
        //check for bearer token
        guard let bearer = bearer else { completion(.failure(.noAuth)); return }

        //MARK: - Get URL Request Ready

        let animalNameURL = baseUrl.appendingPathComponent("animals/\(animalName)")
        var request = URLRequest(url: animalNameURL)

        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            //Downcast to HTTPURLResponse to read status code
            let response = response as? HTTPURLResponse
            
            //MARK: - Response Error Handling
            
            switch true {
            case response!.statusCode == 401:
                completion(.failure(.badAuth))
                return
            case error != nil: //something went wrong with connection or other
                print("Error receiving \(animalName) details: \(error!)")
                completion(.failure(.otherError))
                return
            case data == nil:
                completion(.failure(.badData))
                return
            default:
                break
            }
            
            //MARK: -  Decode Data
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                let animal = try decoder.decode(Animal.self, from: data!)
                completion(.success(animal)) }
            catch {
                print("Error decoding animal object: \(error)")
                completion(.failure(.noDecode))
                return }
        }
        task.resume()
    }
    // create function to fetch image
    
    func fetchImage(at urlString: String, completion: @escaping (Result<UIImage, NetworkError>) -> Void) {
        let imageURL = URL(string: urlString)!
        var request = URLRequest(url: imageURL)
        
        request.httpMethod = HTTPMethod.get.rawValue
        
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let _ = error {
                completion(.failure(.otherError))
                return
            }
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
        
            let image = UIImage(data: data)!
            completion(.success(image))
        }
        task.resume()
    }
}
