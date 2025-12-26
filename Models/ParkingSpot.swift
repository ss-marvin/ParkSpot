import Foundation
import SwiftData
import CoreLocation

@Model
final class ParkingSpot {
    var id: UUID = UUID()
    var latitude: Double = 0
    var longitude: Double = 0
    var photoData: Data?
    var floor: String?
    var note: String?
    var parkedAt: Date = Date()
    var expiresAt: Date?
    var isActive: Bool = true
    var address: String?
    
    init(latitude: Double, longitude: Double, photoData: Data?, floor: String? = nil, note: String? = nil, expiresAt: Date? = nil) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.photoData = photoData
        self.floor = floor
        self.note = note
        self.parkedAt = Date()
        self.expiresAt = expiresAt
        self.isActive = true
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var timeSinceParked: String {
        let interval = Date().timeIntervalSince(parkedAt)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 { return "\(hours)t \(minutes)m" }
        return "\(minutes) min"
    }
    
    var remainingTime: TimeInterval? {
        guard let expiresAt else { return nil }
        let remaining = expiresAt.timeIntervalSince(Date())
        return remaining > 0 ? remaining : 0
    }
    
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt
    }
}

@Model
final class ParkingHistory {
    var id: UUID = UUID()
    var latitude: Double = 0
    var longitude: Double = 0
    var address: String?
    var parkedAt: Date = Date()
    var foundAt: Date = Date()
    var photoData: Data?
    var floor: String?
    var note: String?
    
    init(from spot: ParkingSpot) {
        self.id = UUID()
        self.latitude = spot.latitude
        self.longitude = spot.longitude
        self.address = spot.address
        self.parkedAt = spot.parkedAt
        self.foundAt = Date()
        self.photoData = spot.photoData
        self.floor = spot.floor
        self.note = spot.note
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var duration: String {
        let interval = foundAt.timeIntervalSince(parkedAt)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 { return "\(hours)t \(minutes)m" }
        return "\(minutes) min"
    }
}
