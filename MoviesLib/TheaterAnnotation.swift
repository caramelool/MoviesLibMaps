//
//  TheaterAnnotation.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import Foundation
import MapKit

class TheaterAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(_ theater: Theater) {
        self.title = theater.name
        self.subtitle = theater.address
        self.coordinate = CLLocationCoordinate2D(
            latitude: theater.latitude, longitude: theater.longitude)
    }
}
