//
//  Model.swift
//  IOSGrainChainTest
//
//  Created by Ricardo Developer on 23/04/24.
//

import Foundation
import CoreLocation

// Modelo para representar una ruta
struct Routes {
    var name: String
    var locations: [CLLocation]
    var startDate: Date
    var endDate: Date?

    // Calcular la distancia total recorrida en metros
    var distance: CLLocationDistance {
        guard !locations.isEmpty else { return 0 }
        var totalDistance: CLLocationDistance = 0
        for i in 0..<locations.count - 1 {
            totalDistance += locations[i].distance(from: locations[i + 1])
        }
        return totalDistance
    }

    // Calcular el tiempo total de la ruta en segundos
    var totalTime: TimeInterval {
        guard let end = endDate else { return 0 }
        return end.timeIntervalSince(startDate)
    }
}

