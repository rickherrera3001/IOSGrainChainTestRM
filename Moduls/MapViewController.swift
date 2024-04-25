//
//  MapViewController.swift
//  IOSGrainChainTest
//
//  Created by Ricardo Developer on 23/04/24.
//

import UIKit
import GoogleMaps
import CoreLocation
import SwiftUI

struct Route {
    let name: String
    let coordinates: [CLLocationCoordinate2D]
}

class MapViewController: UIViewController {
    private var mapView: GMSMapView!
    private var locationManager = CLLocationManager()
    private var isRecording = false
    private var path = GMSMutablePath()
    private var polyline: GMSPolyline?
    private var routeName: String = ""
    let recordButton = UIButton(type: .system)
    var currentRouteCordinates = [CLLocation]()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let camera = GMSCameraPosition.camera(withLatitude: 19.639073, longitude: -99.088213, zoom: 12)
        mapView = GMSMapView(frame: view.bounds, camera: camera)
        view.addSubview(mapView)
        
        recordButton.setTitle("Iniciar Grabación", for: .normal)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordButton)
        
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
         ])
        // Configurar el locationManager para obtener la ubicación del usuario
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()//inicializa la ubicacon del usuario
        
        
    }
    
    @objc func toggleRecording() {
        isRecording.toggle()
        let buttonTitle = isRecording ? "Detener Grabación" : "Iniciar Grabación"
        recordButton.setTitle(buttonTitle, for: .normal)
        
        if !isRecording {
            saveRoute()
            path.removeAllCoordinates()
            polyline?.map = nil
            polyline = nil
        }
    }
    private func updateRecordingButtonTitle() {
        let buttonTitle = isRecording ? "Detener Grabación" : "Iniciar Grabación"
        (view.subviews.last as? UIButton)?.setTitle(buttonTitle, for: .normal)
        
    }

    private func saveRoute() {
           guard !routeName.isEmpty else { return }
        let route = Route(name: routeName, coordinates: Array(_immutableCocoaArray: path))
           
           // Aquí puedes guardar la ruta en la base de datos local o realizar otras acciones
           print("Ruta guardada: \(route)")
       }
   }


extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard isRecording, let location = locations.last else { return }
        
        currentRouteCordinates.append(location)
        
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15)
        mapView.animate(to: camera)
        
    }
}

        struct ViewControllerBridge: UIViewControllerRepresentable {
            
            
            
            func makeUIViewController(context: Context) -> MapViewController {
                
                return MapViewController()
            }
            func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
                
                
                
            }
        }

extension MapViewController {
    func drawRoute(from startCoordinate: CLLocationCoordinate2D, to endCoordinate: CLLocationCoordinate2D) {
        
        createDirectionRequest(from: startCoordinate, to: endCoordinate)
           
           // Obtener el servicio de direcciones
         
        _ = GMSMapViewOptions()
    
    }
    
    private func createDirectionRequest(from startCoordinate: CLLocationCoordinate2D, to endCoordinate: CLLocationCoordinate2D) {


        
        return
    }
    
    private func showRouteOnMap(_ route: Route) {
        let path = GMSMutablePath()
        
        for location in route.coordinates {
            path.add(location)
        }
        
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = .blue
        polyline.strokeWidth = 4
        polyline.map = mapView
    }
}


        
    
