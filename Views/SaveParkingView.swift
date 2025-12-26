import SwiftUI
import SwiftData
import CoreLocation

struct SaveParkingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService
    
    let image: UIImage
    let onComplete: () -> Void
    
    @State private var floor = ""
    @State private var note = ""
    @State private var enableTimer = false
    @State private var timerMinutes = 60
    @State private var isSaving = false
    
    @AppStorage("reminderTimes") private var reminderTimesString = "15,5"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Foto
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // GPS Status
                    HStack {
                        if let loc = locationService.location {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Position sparad")
                                    .font(.headline)
                                Text(String(format: "%.5f, %.5f", loc.coordinate.latitude, loc.coordinate.longitude))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView()
                            Text("Hämtar position...")
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Detaljer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detaljer (valfritt)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Våning (t.ex. P2, -1)", text: $floor)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                        
                        TextField("Övrigt", text: $note)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                    }
                    
                    // Timer
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Parkeringstimer", isOn: $enableTimer.animation())
                            .font(.headline)
                        
                        if enableTimer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tid: \(formatMinutes(timerMinutes))")
                                    .font(.subheadline)
                                
                                Slider(value: .init(
                                    get: { Double(timerMinutes) },
                                    set: { timerMinutes = Int($0) }
                                ), in: 15...480, step: 15)
                                .tint(.blue)
                                
                                HStack {
                                    Text("15 min")
                                    Spacer()
                                    Text("8 tim")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Spara parkering")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        onComplete()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    saveParking()
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                    } else {
                        Text("SPARA PARKERING")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(locationService.location != nil ? Color.blue.gradient : Color.gray.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .disabled(locationService.location == nil || isSaving)
                .padding()
                .background(.ultraThinMaterial)
            }
            .onAppear {
                locationService.startUpdating()
            }
        }
    }
    
    private func formatMinutes(_ m: Int) -> String {
        let h = m / 60
        let mins = m % 60
        if h > 0 && mins > 0 { return "\(h) tim \(mins) min" }
        if h > 0 { return "\(h) timmar" }
        return "\(mins) min"
    }
    
    private func saveParking() {
        guard let location = locationService.location else { return }
        
        isSaving = true
        
        let photoData = image.jpegData(compressionQuality: 0.7)
        
        var expiresAt: Date?
        if enableTimer {
            expiresAt = Date().addingTimeInterval(Double(timerMinutes * 60))
        }
        
        let spot = ParkingSpot(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            photoData: photoData,
            floor: floor.isEmpty ? nil : floor,
            note: note.isEmpty ? nil : note,
            expiresAt: expiresAt
        )
        
        // Geocode
        Task {
            let geocoder = CLGeocoder()
            if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
               let pm = placemarks.first {
                var addr = ""
                if let street = pm.thoroughfare { addr = street }
                if let num = pm.subThoroughfare { addr += " \(num)" }
                if let city = pm.locality {
                    if !addr.isEmpty { addr += ", " }
                    addr += city
                }
                spot.address = addr.isEmpty ? nil : addr
            }
            
            await MainActor.run {
                modelContext.insert(spot)
                
                // Notifikationer
                if let expires = expiresAt {
                    NotificationService.shared.requestPermission()
                    let times = reminderTimesString.split(separator: ",").compactMap { Int($0) }
                    NotificationService.shared.scheduleReminders(spotId: spot.id, expiresAt: expires, reminderTimes: times)
                }
                
                try? modelContext.save()
                onComplete()
                dismiss()
            }
        }
    }
}
