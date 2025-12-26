import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Hem", systemImage: "car.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("Historik", systemImage: "clock.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Inställningar", systemImage: "gearshape.fill")
                }
        }
    }
}
