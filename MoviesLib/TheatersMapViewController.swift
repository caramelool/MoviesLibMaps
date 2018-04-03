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
        
        loadXML()
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
            } else {
                annotationView.annotation = annotation
            }
        }
        return annotationView
    }
    
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
        print("Velocidade do usuario: \(userLocation.location?.speed ?? 0)")
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)
        mapView.setRegion(region, animated: true)
    }
}

//MARK: -
extension TheatersMapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
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
        self.mapView.removeAnnotation(self.poiAnnotation as! MKAnnotation)
        self.poiAnnotation.removeAll()
    }
    
    private func reloadPOIAnnotation() {
        self.mapView.addAnnotations(self.poiAnnotation)
    }
}
