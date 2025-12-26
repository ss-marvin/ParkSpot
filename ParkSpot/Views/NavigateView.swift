import SwiftUI
import MapKit
import Photos

struct NavigateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService
    
    let spot: ParkingSpot
    let onFound: () -> Void
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var route: MKRoute?
    @State private var showSavePhotoAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Karta
                Map(position: $cameraPosition) {
                    Marker("Min bil", coordinate: spot.coordinate)
                        .tint(.blue)
                    if let userCoord = locationService.location?.coordinate {
                        Marker("Jag", coordinate: userCoord)
                            .tint(.green)
                    }
                    if let route {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .frame(height: 300)
                .onAppear {
                    setupMap()
                    calculateRoute()
                    locationService.startHeading()
                }
                .onDisappear {
                    locationService.stopHeading()
                }
                
                // Info
                VStack(spacing: 24) {
                    // Stats
                    HStack(spacing: 30) {
                        // Avstånd
                        VStack {
                            if let dist = locationService.distance(to: spot.coordinate) {
                                Text(formatDistance(dist))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.blue)
                            } else {
                                Text("--")
                                    .font(.system(size: 32, weight: .bold))
                            }
                            Text("avstånd")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Kompass
                        VStack {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.blue)
                                .rotationEffect(.degrees(
                                    locationService.bearing(to: spot.coordinate) - (locationService.heading?.trueHeading ?? 0)
                                ))
                                .animation(.smooth, value: locationService.heading?.trueHeading)
                            Text("riktning")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Tid
                        VStack {
                            if let route {
                                Text("\(Int(route.expectedTravelTime / 60))")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.green)
                            } else {
                                Text("--")
                                    .font(.system(size: 32, weight: .bold))
                            }
                            Text("min gång")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Knappar
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                openInMaps()
                            } label: {
                                Label("Kartor", systemImage: "map.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                            }
                            .buttonStyle(.bordered)
                            
                            ShareLink(
                                item: URL(string: "https://maps.apple.com/?ll=\(spot.latitude),\(spot.longitude)")!,
                                subject: Text("Min bil"),
                                message: Text("Jag parkerade här")
                            ) {
                                Label("Dela", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Spara foto till kamerarulle
                        if spot.photoData != nil {
                            Button {
                                savePhotoToLibrary()
                            } label: {
                                Label("Spara foto till kamerarulle", systemImage: "square.and.arrow.down")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Button {
                            onFound()
                        } label: {
                            Label("JAG HAR HITTAT BILEN", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.green.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Hitta bilen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Stäng") { dismiss() }
                }
            }
            .alert("Foto sparat", isPresented: $showSavePhotoAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func setupMap() {
        var coords = [spot.coordinate]
        if let userCoord = locationService.location?.coordinate {
            coords.append(userCoord)
        }
        cameraPosition = .region(MKCoordinateRegion(
            center: spot.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    private func calculateRoute() {
        guard let userLoc = locationService.location else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: spot.coordinate))
        request.transportType = .walking
        
        Task {
            let directions = MKDirections(request: request)
            if let response = try? await directions.calculate() {
                await MainActor.run {
                    route = response.routes.first
                }
            }
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: spot.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Min bil"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
    
    private func formatDistance(_ m: Double) -> String {
        if m < 1000 { return "\(Int(m)) m" }
        return String(format: "%.1f km", m / 1000)
    }
    
    private func savePhotoToLibrary() {
        guard let data = spot.photoData, let image = UIImage(data: data) else { return }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                DispatchQueue.main.async {
                    showSavePhotoAlert = true
                }
            }
        }
    }
}
