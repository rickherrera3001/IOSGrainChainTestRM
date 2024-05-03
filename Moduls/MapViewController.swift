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

class MapViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Variables de instancia
    private var mapView: GMSMapView!  // Mapa de Google
    private var locationManager = CLLocationManager()  // Administrador de ubicación
    private var isRecording = false // Estado de grabación
    private var path = GMSMutablePath() // Ruta del recorrido
    private var polyline: GMSPolyline? // Polilínea del recorrido
    let recordButton = UIButton(type: .system) // Botón de grabación
    var currentRouteCordinates = [CLLocation]() // Coordenadas del recorrido actual
    var routes = [Routes]() // Lista de rutas guardadas
    var startDate: Date = .now // Fecha de inicio de la grabación
    var endDate : Date = .now // Fecha de fin de la grabación
    let screenSize =  UIScreen.main.bounds // Tamaño de la pantalla
    
    var tableView = UITableView()
    
    
    // MARK: - Métodos de instancia
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        
        let screenHeigh = screenSize.height/2 // Calcula el alto de la pantalla dividido por 2
        let rect = CGRect(x: 0, y: 0, width: screenHeigh, height: screenSize.width) // Define un rectángulo con el ancho y alto de la pantalla, intercambiados
        
        // Configurar el mapa con una posición y zoom específicos
        let camera = GMSCameraPosition.camera(withLatitude: 19.639073, longitude: -99.088213, zoom: 12)
        mapView = GMSMapView(frame: rect, camera: camera)
        view.addSubview(mapView)
        
        // Configurar la tabla
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        tableView = UITableView(frame:  CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2))
        
        // Configurar la tabla
        func setupTableView() {
            tableView = UITableView(frame: CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2))
            tableView.backgroundColor = .gray
            tableView.dataSource = self
            tableView.delegate = self
            view.addSubview(tableView)
            
            
            tableView.register(routeListCell.self, forCellReuseIdentifier: "Cell")
            tableView.dataSource = self
            tableView.delegate = self
            view.addSubview(tableView)
        }
        
        
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
    
    // MARK: - UITableViewDataSource
    // Este método devuelve el número de filas en la sección especificada de la tabla.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Retorna la cantidad de elementos en el arreglo 'routes', que probablemente representan el número de rutas guardadas.
        return routes.count
    }
    
    // Este método configura y devuelve una celda para mostrar en la tabla en una ubicación específica.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! routeListCell
        
        let route = routes[indexPath.row]
        cell.textLabel?.text = route.name
        
        let distanceInKilometers = route.distance / 1000
        cell.detailTextLabel?.text = String(format: "%2f km" , distanceInKilometers)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: - Métodos de grabación
    @objc func toggleRecording() {
        isRecording.toggle()
        let buttonTitle = isRecording ? "Detener Grabación" : "Iniciar Grabación"
        recordButton.setTitle(buttonTitle, for: .normal)
        
        if !isRecording {
            // Agregar marcador al detener la grabación
            if let lastLocation = currentRouteCordinates.last {
                addMarker(at: lastLocation)
            }
            showSaveRouteAlert()
            let distanceTraveled = calculateDistanceTraveled()
            print("Distance Traveled: \(distanceTraveled) meters")
        } else {
            startDate = .now
        }
    }
    
    // MARK: - Métodos auxiliares
    // Función para calcular la distancia recorrida
    func calculateDistanceTraveled() -> Double {
        var distance: Double = 0.0
        
        guard currentRouteCordinates.count >= 2 else {
            return distance
        }
        for i in 1..<currentRouteCordinates.count {
            let startPoint = currentRouteCordinates[i-1]
            let endPoint = currentRouteCordinates[i]
            let distanceBetweenTwoPoints = startPoint.distance(from: endPoint)
            distance += distanceBetweenTwoPoints
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
        tableView.reloadData()
    }
    
    // Actualizar la polilínea con las nuevas ubicaciones
    func updatePolyline(with locations: [CLLocation]) {
        for coordinate in locations {
            path.add(coordinate.coordinate)
        }
        
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = .systemRed
        polyline.strokeWidth = 3.0
        polyline.map = mapView
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
        marker.title = coordinate.description // Set a title to marker
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

// Implementación de CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        if isRecording {
            addLocationToRoute(location)
            
            // Añadir marcador en la primera ubicación
            if path.count() == 0 {
                addMarker(at: location)
            }
            
            currentRouteCordinates.append(location)
            updatePolyline(with: currentRouteCordinates)
            
            // Centrar el mapa en la última ubicación
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15)
            mapView.animate(to: camera)
        }
    }
    
    // Añadir ubicación a la ruta
    func addLocationToRoute(_ coordinate: CLLocation) {
        currentRouteCordinates.append(coordinate)
    }
}

// Definición de la clase UITableViewCell para las celdas de la tabla
class routeListCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier:  reuseIdentifier)
        
        // Configurar las propiedades de la celda
        textLabel?.numberOfLines = 0 // Permite múltiples líneas en el título
        detailTextLabel?.numberOfLines = 0 // Permite múltiples líneas en el detalle
    }
    // Este método es requerido para conformarse al protocolo NSCoding, pero en este caso se implementa como una fatal error.
    required init?(coder: NSCoder) {
        // Lanza un error fatal indicando que la inicialización desde un codificador no ha sido implementada.
        fatalError("init(coder:) has not been implemented")
    }
}




