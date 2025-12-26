import SwiftUI
import SwiftData

@main
struct ParkSpotApp: App {
    @StateObject private var locationService = LocationService()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ParkingSpot.self, ParkingHistory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(locationService)
                .onAppear {
                    locationService.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
