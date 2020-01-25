//
//  NewtorkError.swift
//  AnimalSpotter
//
//  Created by alfredo on 1/24/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

enum NetworkError: Error{
    case badAuth
    case badData
    case noAuth
    case noDecode
    case otherError
}
