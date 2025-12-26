import SwiftUI
import SwiftData
import MapKit
import Combine

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @Query(filter: #Predicate<ParkingSpot> { $0.isActive }) private var activeSpots: [ParkingSpot]
    
    @State private var showCamera = false
    @State private var showNavigate = false
    @State private var capturedImage: UIImage?
    
    private var activeSpot: ParkingSpot? { activeSpots.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if let spot = activeSpot {
                    // Aktiv parkering
                    ActiveParkingView(spot: spot, onNavigate: { showNavigate = true }, onFound: markAsFound)
                } else {
                    // Ingen parkering - stor knapp i mitten
                    noParkingView
                }
            }
            .navigationTitle("ParkSpot")
            .onAppear {
                locationService.startUpdating()
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    capturedImage = image
                }
            }
            .sheet(isPresented: .init(
                get: { capturedImage != nil },
                set: { if !$0 { capturedImage = nil } }
            )) {
                if let image = capturedImage {
                    SaveParkingView(image: image) {
                        capturedImage = nil
                    }
                }
            }
            .sheet(isPresented: $showNavigate) {
                if let spot = activeSpot {
                    NavigateView(spot: spot, onFound: {
                        markAsFound()
                        showNavigate = false
                    })
                }
            }
        }
    }
    
    private var noParkingView: some View {
        VStack {
            Spacer()
            
            // Stor parkera-knapp
            Button {
                showCamera = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)
                        .shadow(color: .blue.opacity(0.4), radius: 20, y: 10)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                        Text("PARKERA")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Tryck för att spara parkering")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)
        }
    }
    
    private func markAsFound() {
        guard let spot = activeSpot else { return }
        let history = ParkingHistory(from: spot)
        modelContext.insert(history)
        NotificationService.shared.cancelReminders(spotId: spot.id)
        spot.isActive = false
        try? modelContext.save()
    }
}

// MARK: - Active Parking View

struct ActiveParkingView: View {
    let spot: ParkingSpot
    let onNavigate: () -> Void
    let onFound: () -> Void
    
    @EnvironmentObject private var locationService: LocationService
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Karta
                Map(position: $cameraPosition) {
                    Marker("Min bil", coordinate: spot.coordinate)
                        .tint(.blue)
                    if let userCoord = locationService.location?.coordinate {
                        Marker("Jag", coordinate: userCoord)
                            .tint(.green)
                    }
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                .onAppear {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: spot.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))
                }
                
                // Info
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(spot.address ?? "Parkerad")
                                .font(.headline)
                            Text("Parkerad \(spot.timeSinceParked) sedan")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let dist = locationService.distance(to: spot.coordinate) {
                            Text(formatDistance(dist))
                                .font(.title2.bold())
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    // Timer
                    if spot.expiresAt != nil {
                        TimerCard(spot: spot)
                    }
                    
                    // Info
                    if spot.floor != nil || spot.note != nil {
                        HStack {
                            if let floor = spot.floor {
                                Label(floor, systemImage: "arrow.up.arrow.down")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let note = spot.note {
                                Spacer()
                                Text(note)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Foto
                if let data = spot.photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 120)
            }
            .padding(.top)
        }
        
        // Knappar längst ner
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                // Hitta bilen
                Button {
                    onNavigate()
                } label: {
                    Label("HITTA BILEN", systemImage: "location.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                HStack(spacing: 12) {
                    // Hittad
                    Button {
                        onFound()
                    } label: {
                        Label("HITTAD", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.green.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Parkera till bil
                    Button {
                        // TODO: Öppna kamera för ny bil
                    } label: {
                        Label("NY BIL", systemImage: "plus")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    private func formatDistance(_ m: Double) -> String {
        if m < 1000 { return "\(Int(m)) m" }
        return String(format: "%.1f km", m / 1000)
    }
}

// MARK: - Timer Card

struct TimerCard: View {
    let spot: ParkingSpot
    @State private var remaining: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Image(systemName: spot.isExpired ? "exclamationmark.triangle.fill" : "timer")
                .font(.title2)
                .foregroundStyle(spot.isExpired ? .red : remaining < 300 ? .orange : .green)
            
            VStack(alignment: .leading) {
                Text(spot.isExpired ? "UTGÅNGEN" : formatTime(remaining))
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(spot.isExpired ? .red : .primary)
                Text("kvar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background((spot.isExpired ? Color.red : remaining < 300 ? Color.orange : Color.green).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onReceive(timer) { _ in
            remaining = spot.remainingTime ?? 0
        }
        .onAppear {
            remaining = spot.remainingTime ?? 0
        }
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
