import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func scheduleReminders(spotId: UUID, expiresAt: Date, reminderTimes: [Int]) {
        // reminderTimes = minuter innan utgång, t.ex. [30, 15, 5]
        for minutes in reminderTimes {
            let triggerDate = expiresAt.addingTimeInterval(-Double(minutes * 60))
            guard triggerDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Parkeringen går snart ut"
            content.body = minutes == 1 ? "1 minut kvar!" : "\(minutes) minuter kvar"
            content.sound = minutes <= 5 ? .defaultCritical : .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: triggerDate.timeIntervalSinceNow,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "parking-\(spotId.uuidString)-\(minutes)",
                content: content,
                trigger: trigger
            )
            
            center.add(request)
        }
        
        // Utgångsnotis
        if expiresAt > Date() {
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Parkeringen har gått ut!"
            content.body = "Tiden är slut"
            content.sound = .defaultCritical
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: expiresAt.timeIntervalSinceNow,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "parking-expired-\(spotId.uuidString)",
                content: content,
                trigger: trigger
            )
            
            center.add(request)
        }
    }
    
    func cancelReminders(spotId: UUID) {
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.contains(spotId.uuidString) }.map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
