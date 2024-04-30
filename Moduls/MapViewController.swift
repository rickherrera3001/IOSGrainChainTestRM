// Definición del archivo y la fecha de creación
//
//  MapViewController.swift
//  IOSGrainChainTest
//
//  Created by Ricardo Developer on 23/04/24.

import UIKit
import GoogleMaps
import CoreLocation
import SwiftUI
import Foundation
import SwiftData

// Definición de una estructura que representa una ruta
struct Route {
    let name: String // Nombre de la ruta
    let coordinates: [CLLocationCoordinate2D] // Coordenadas de la ruta
}

// Definición de la clase del controlador de vista del mapa
class MapViewController: UIViewController, UITextFieldDelegate {
    private var mapView: GMSMapView! // Vista del mapa de Google
    private var locationManager = CLLocationManager() // Administrador de ubicación
    private var isRecording = false // Indica si se está grabando una ruta
    private var path = GMSMutablePath() // Camino de la ruta
    private var polyline: GMSPolyline? // Línea de la ruta
    private var routeName: String = "" // Nombre de la ruta actual
    private var currentRouteCoordinates = [CLLocation]() // Coordenadas de la ruta actual
    private var startMarker: GMSMarker? // Marcador de inicio de ruta
    private var endMarker: GMSMarker? // Marcador de fin de ruta
    // Botón para iniciar/detener la grabación de la ruta
    private lazy var recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Iniciar Grabación", for: .normal)
        button.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuración inicial del mapa y del botón
        let camera = GMSCameraPosition.camera(withLatitude: 19.639073, longitude: -99.088213, zoom: 12)
        mapView = GMSMapView(frame: view.bounds, camera: camera)
        view.addSubview(mapView)
        view.addSubview(recordButton)
        
        // Configuración de las restricciones del botón
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        
        // Configuración del administrador de ubicación
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Método para mostrar el UIAlertController y guardar la ruta
    private func showSaveRouteAlert() {
        let alertController = UIAlertController(title: "Guardar Ruta", message: "Ingrese un nombre para guardar la ruta", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Nombre de la ruta"
        }
        
        let saveAction = UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let routeName = alertController.textFields?.first?.text else { return }
            self?.saveRoute(with: routeName)
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        alertController.textFields?.first?.delegate = self
        
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    // Método para guardar la ruta y actualizar el modelo
    private func saveRoute(with name: String) {
        guard !currentRouteCoordinates.isEmpty else {
            print("No hay ruta para guardar.")
            return
        }
        
        // Crear una instancia de la ruta
        let newRoute = Route(name: name, coordinates: currentRouteCoordinates.map { $0.coordinate })
        
        // Guardar la ruta en el modelo o donde lo necesites
        let route = Routes(name: name, locations: currentRouteCoordinates, startDate: Date(), endDate: nil, distance: calculateDistance()) // Asume que tienes una función para calcular la distancia de la ruta
        
        // Aquí puedes almacenar la nueva ruta en tu modelo o hacer lo que necesites con ella
        print("Ruta guardada: \(route)")
        
        // Limpia la ruta actual
        clearRoute()
        
    }

    
    // Calcula la distancia total de la ruta
    private func calculateDistance() -> Double {
        var totalDistance: Double = 0
        
        for i in 0..<currentRouteCoordinates.count - 1 {
            let coordinate1 = currentRouteCoordinates[i].coordinate
            let coordinate2 = currentRouteCoordinates[i + 1].coordinate
            let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
            let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
            totalDistance += location1.distance(from: location2)
        }
        
        return totalDistance
    }
    
    
    // Método llamado al presionar el botón de grabación
    @objc private func toggleRecording() {
        isRecording.toggle()
        
        let buttonTitle = isRecording ? "Detener Grabación" : "Iniciar Grabación"
        recordButton.setTitle(buttonTitle, for: .normal)
        
        if isRecording {
            clearRoute()
            currentRouteCoordinates.removeAll()
            startMarker = nil
            
            if let firstLocation = locationManager.location {
                startMarker = createMarker(at: firstLocation.coordinate, title: "Inicio")
                currentRouteCoordinates.append(firstLocation)
            }
        } else {
            locationManager.stopUpdatingLocation()
            
            if let lastLocation = currentRouteCoordinates.last {
                endMarker = createMarker(at: lastLocation.coordinate, title: "Fin")
            }
            
            // Pide al usuario que guarde la ruta
            showSaveRouteAlert()
        }
    }

    
    // Método para borrar la ruta actual
    private func clearRoute() {
        path.removeAllCoordinates()
        polyline?.map = nil
        polyline = nil
    }
    
    // Método para crear un marcador en una ubicación dada
    private func createMarker(at coordinate: CLLocationCoordinate2D, title: String) -> GMSMarker {
        let marker = GMSMarker(position: coordinate)
        marker.title = title
        marker.map = mapView
        return marker
    }
    
    // Método para dibujar una ruta dada
    private func drawRoute(_ route: Route) {
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
     

// Extensión para manejar eventos del administrador de ubicación
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        // Mover la cámara a la ubicación actual
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 15)
        mapView.animate(to: camera)
        
        // Agregar la ubicación actual a la ruta si estamos grabando
        if isRecording {
            currentRouteCoordinates.append(location)
            
            // Dibujar la ruta
            if currentRouteCoordinates.count >= 2 {
                let startCoordinate = currentRouteCoordinates[currentRouteCoordinates.count - 2].coordinate
                let endCoordinate = currentRouteCoordinates[currentRouteCoordinates.count - 1].coordinate
                drawRoute(Route(name: "", coordinates: [startCoordinate, endCoordinate]))
            }
        }
    }
}

// Representación de un controlador de vista para ser utilizado en SwiftUI
struct ViewControllerBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapViewController {
        return MapViewController()
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        
    }
}
