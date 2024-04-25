//
//  AppDelegate.swift
//  IOSGrainChainTest
//
//  Created by Ricardo Developer on 23/04/24.
//

import Foundation
import UIKit
import GoogleMaps

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configura tu API key de Google Maps aquí
        GMSServices.provideAPIKey("AIzaSyDYo_a449EYcTB05TN6Ai5O4GrjhMsN22k")
        return true
    }
}
