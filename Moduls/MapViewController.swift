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

class MapViewController: UIViewController {
    // MARK: - Variables de instancia
    private var mapView: GMSMapView!  // Mapa de Google
    private var locationManager = CLLocationManager()  // Administrador de ubicación
    private var isRecording = false // Estado de grabación
    private var path = GMSMutablePath() // Ruta del recorrido
    private var polyline: GMSPolyline? // Polilínea del recorrido
    let recordButton = UIButton(type: .system) // Botón de grabación
    var currentRouteCordinates = [CLLocation]() // Coordenadas del recorrido actual
    var routes = [Routes]()
    var startDate: Date = .now
    var endDate : Date = .now
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar el mapa
        let camera = GMSCameraPosition.camera(withLatitude: 19.639073, longitude: -99.088213, zoom: 12)
        mapView = GMSMapView(frame: view.bounds, camera: camera)
        view.addSubview(mapView)
        
        // Configurar el botón de grabación
        recordButton.setTitle("Iniciar Grabación", for: .normal)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordButton)
        
        // Configurar las restricciones del botón de grabación
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        
        // Configurar el administrador de ubicación
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation() // Inicializar la ubicación del usuario
    }
    
    // MARK: - Métodos de grabación
    @objc func toggleRecording() {
        isRecording.toggle()
        let buttonTitle = isRecording ? "Detener Grabación" : "Iniciar Grabación"
        recordButton.setTitle(buttonTitle, for: .normal)
        
        if !isRecording {
            // Agregar marcador al detener la grabación
            if let lastLoacation = currentRouteCordinates.last {
                addMarker(at: lastLoacation)
            }
            showSaveRouteAlert()
            let distanceTraveled = calculateDistanceTraveled()
            print("Distance Traveled: \(distanceTraveled) meters")
        } else {
            startDate = .now
        }
    }
    
    func calculateDistanceTraveled() -> Double {
        var distance: Double = 0.0
        
        guard currentRouteCordinates.count >= 2 else {
            return distance
        }
        for i in 1..<currentRouteCordinates.count {
            let startPoint = currentRouteCordinates[i-1]
            let endPoint = currentRouteCordinates[i]
            let distanceBetwwenTwoPoints = startPoint.distance(from: endPoint)
            distance += distanceBetwwenTwoPoints
        }
        return distance
    }
    
    
    // Mostrar alerta para guardar la ruta
    func showSaveRouteAlert() {
        let alertController = UIAlertController(title: "Guardar Ruta", message: "Escribe el nombre de tu ruta", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Nombre de la ruta"
        }
        
        let saveAction = UIAlertAction(title: "Guardar", style: .default) { (_) in
            guard let name = alertController.textFields?.first?.text else { return }
            print("Nombre de la ruta: \(name)")
            self.saveRoute(routeName: name)
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Guardar la ruta
    private func saveRoute(routeName: String) {
        guard !currentRouteCordinates.isEmpty else { return }
        
        let route = Routes(name: routeName, locations: currentRouteCordinates, startDate: startDate, endDate: endDate, distance: calculateDistanceTraveled())
        
        routes.append(route)
        clearRoute()
        print(routes)
    }
    
    
    // MARK: - Métodos auxiliares
    // Actualizar la polilínea con las nuevas ubicaciones
    func updatePolyline(with location: [CLLocation]) {
        for cordinates in location {
            
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = .systemRed
            polyline.strokeWidth = 3.0
            polyline.map = mapView
        }
    }
    
    // Limpiar la ruta
    func clearRoute() {
        mapView.clear()
        currentRouteCordinates.removeAll()
    }
    
    // Agregar marcador
    func addMarker(at coordinate: CLLocation) {
        let marker = GMSMarker()
        marker.position = coordinate.coordinate
        marker.title = title
        marker.map = mapView
    }
}

// Representación de la vista como UIViewController
struct ViewControllerBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapViewController {
        return MapViewController()
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        // No se necesita implementación para la actualización
    }
}

// Extensión para manejar eventos de CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        if isRecording {
            addLocationToRoute(location)
            
            // Añadir marcador en la primera ubicación
            if path.count() == 0 {
                addMarker(at: location)
            }
            
            path.add(location.coordinate)
            currentRouteCordinates.append(location)
            
            // Centrar el mapa en la última ubicación
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15)
            mapView.animate(to: camera)
        }
    }
    
    // Añadir ubicación a la ruta
    func addLocationToRoute(_ coordinate: CLLocation) {
        currentRouteCordinates.append(coordinate)
        updatePolyline(with: currentRouteCordinates)
    }
}
