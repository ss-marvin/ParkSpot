import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    @Published var heading: CLHeading?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        authStatus = manager.authorizationStatus
    }
    
    var isAuthorized: Bool {
        authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways
    }
    
    func requestPermission() {
        if authStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if isAuthorized {
            manager.startUpdatingLocation()
        }
    }
    
    func startUpdating() {
        if isAuthorized {
            manager.startUpdatingLocation()
        }
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func startHeading() {
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }
    
    func stopHeading() {
        manager.stopUpdatingHeading()
    }
    
    func bearing(to coord: CLLocationCoordinate2D) -> Double {
        guard let loc = location else { return 0 }
        let lat1 = loc.coordinate.latitude * .pi / 180
        let lon1 = loc.coordinate.longitude * .pi / 180
        let lat2 = coord.latitude * .pi / 180
        let lon2 = coord.longitude * .pi / 180
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }
    
    func distance(to coord: CLLocationCoordinate2D) -> Double? {
        guard let loc = location else { return nil }
        let target = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return loc.distance(from: target)
    }
    
    // MARK: - Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            DispatchQueue.main.async {
                self.location = loc
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authStatus = manager.authorizationStatus
            if self.isAuthorized {
                manager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
