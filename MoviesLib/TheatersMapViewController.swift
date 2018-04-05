//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit
import MapKit

class TheatersMapViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Constants
    let TYPE_THEATER = "Theater"
    let TYPE_POI = "POI"
    
    // MARK: - Properties
    
    var currentEement: String!
    var theater: Theater!
    var theaters: [Theater] = []
    lazy var locationManager = CLLocationManager()
    var poiAnnotation: [MKPointAnnotation] = []
    
    // MARK: - Super Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        mapView.delegate = self
        
//        loadXML()
        showAddress("Rua Vichi 46 - Vila Metalurgica")
        requestUserLocationAuthorization()
    }
    
    // MARK: - Methods
    
    func loadXML() {
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"),
            let xmlParser = XMLParser(contentsOf: xml) else { return }
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters() {
        for theater in theaters {
            let annotation = TheaterAnnotation(theater)
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func requestUserLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = true
            
            switch CLLocationManager.authorizationStatus() {
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Usuário já autorizou o uso da localização!")
                case .denied:
                    print("Usuário negou a autorização")
                case .notDetermined:
                    locationManager.requestWhenInUseAuthorization()
                case .restricted:
                    print("Sifu!")
            }
        }
    }
    
    func getRoute(destination coordinate: CLLocationCoordinate2D) {
        guard let userCordinate = locationManager.location?.coordinate else { return }
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error == nil {
                guard let response = response else { return }
                let routes = response.routes.sorted(by: { $0.expectedTravelTime < $1.expectedTravelTime})
                guard let route = routes.first else { return }
                print("Nome da rota: \(route.name)")
                print("Distancia: \(route.distance)")
                print("Duração: \(route.expectedTravelTime/60/60)")
                print("Tipo de transporte: \(route.transportType)")
                
                self.mapView.removeOverlays(self.mapView.overlays)
                self.mapView.add(route.polyline, level: .aboveRoads)
                self.mapView.showAnnotations(self.mapView.annotations, animated: true)
            } else {
                print(error ?? "")
            }
        }
    }
    
    private func showAddress(_ address: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            if error == nil {
                guard let placemarks = placemarks else { return }
                guard let placemark = placemarks.first else { return }
                guard let coordinate = placemark.location?.coordinate else { return }
                
                let annotation = MKPointAnnotation()
                annotation.title = placemark.name
                annotation.subtitle = placemark.postalCode ?? "--"
                annotation.coordinate = coordinate
                self.mapView.addAnnotation(annotation)
                
                let region = MKCoordinateRegionMakeWithDistance(coordinate, 400, 400)
                self.mapView.setRegion(region, animated: true)
            } else {
                print(error ?? "")
            }
        }
    }
}

// MARK: - XMLParserDelegate
extension TheatersMapViewController: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentEement = elementName
        
        if elementName == TYPE_THEATER {
            theater = Theater()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.isEmpty { return }
        switch currentEement {
            case "name":
                theater.name = content
            case "address":
                theater.address = content
            case "latitude":
                theater.latitude = Double(content)!
            case "longitude":
                theater.longitude = Double(content)!
            case "url":
                theater.url = content
            default:
                break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == TYPE_THEATER {
            theaters.append(theater)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        addTheaters()
    }
    
}

//MARK: - MKMapViewDelegate
extension TheatersMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView!
        if annotation is TheaterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: TYPE_THEATER)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier:
                    TYPE_THEATER)
                annotationView.image = UIImage(named: "theaterIcon")
                annotationView.canShowCallout = true
            
                createCalloutAccessoryView(in: annotationView)
            } else {
                annotationView.annotation = annotation
            }
        } else if annotation is MKPointAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: TYPE_POI)
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier:
                    TYPE_POI)
                (annotationView as! MKPinAnnotationView).pinTintColor = .blue
                (annotationView as! MKPinAnnotationView).animatesDrop = true
                annotationView.canShowCallout = true
            } else {
                annotationView.annotation = annotation
            }
        }
        return annotationView
    }
    
    private func createCalloutAccessoryView(`in` annotationView: MKAnnotationView) {
        let btLeft = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        btLeft.setImage(UIImage(named: "car"), for: .normal)
        annotationView.leftCalloutAccessoryView = btLeft
        
        let btRight = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = btRight
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            getRoute(destination: view.annotation!.coordinate)
        } else if control == view.rightCalloutAccessoryView {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController {
                guard let theaterAnnotation = (view.annotation as? TheaterAnnotation) else { return }
                vc.url = theaterAnnotation.theater.url
                self.present(vc, animated: true, completion: nil)
            }
            
            
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            renderer.lineWidth = 3.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        let camera = MKMapCamera()
//        camera.pitch = 80
//        camera.altitude = 100
//        camera.centerCoordinate = view.annotation!.coordinate
//        mapView.setCamera(camera, animated: true)
//    }
    
}

//MARK: - CLLocationManagerDelegate
extension TheatersMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
//        print("Velocidade do usuario: \(userLocation.location?.speed ?? 0)")
//        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)
//        mapView.setRegion(region, animated: true)
    }
}

//MARK: -
extension TheatersMapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            self.clearPOIAnnotation()
            if error == nil {
                guard let response = response else { return }
                for item in response.mapItems {
                    let place = MKPointAnnotation()
                    place.coordinate = item.placemark.coordinate
                    place.title = item.name
                    place.subtitle = item.phoneNumber
                    self.poiAnnotation.append(place)
                }
                self.reloadPOIAnnotation()
            } else {
                print(error ?? "")
            }
        }
    }
    
    private func clearPOIAnnotation() {
        self.mapView.removeAnnotations(self.poiAnnotation)
        self.poiAnnotation.removeAll()
    }
    
    private func reloadPOIAnnotation() {
        self.mapView.addAnnotations(self.poiAnnotation)
    }
}
