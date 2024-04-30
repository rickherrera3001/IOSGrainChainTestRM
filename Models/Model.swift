//
//  Model.swift
//  IOSGrainChainTest
//
//  Created by Ricardo Developer on 23/04/24.
//

import Foundation
import CoreLocation

struct Routes {
    var name: String
    var locations: [CLLocation]
    var startDate: Date
    var endDate: Date?
    var distance: Double
}

