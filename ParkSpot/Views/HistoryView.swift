import SwiftUI
import SwiftData
import MapKit
import Photos

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParkingHistory.parkedAt, order: .reverse) private var history: [ParkingHistory]
    
    @State private var showDeleteOptions = false
    @State private var selectedItem: ParkingHistory?
    
    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("Historik")
            .toolbar {
                if !history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Radera") {
                            showDeleteOptions = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog("Radera historik", isPresented: $showDeleteOptions) {
                Button("Senaste veckan", role: .destructive) {
                    deleteHistory(olderThan: 7)
                }
                Button("Senaste månaden", role: .destructive) {
                    deleteHistory(olderThan: 30)
                }
                Button("Radera allt", role: .destructive) {
                    deleteAllHistory()
                }
                Button("Avbryt", role: .cancel) {}
            }
            .sheet(item: $selectedItem) { item in
                HistoryDetailView(item: item)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Ingen historik")
                .font(.title2.bold())
            Text("Tidigare parkeringar visas här")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var listView: some View {
        List {
            ForEach(history) { item in
                Button {
                    selectedItem = item
                } label: {
                    HStack(spacing: 12) {
                        // Thumbnail
                        if let data = item.photoData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Image(systemName: "car.fill")
                                        .foregroundStyle(.gray)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.address ?? "Okänd plats")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(item.parkedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(item.duration)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(history[index])
        }
        try? modelContext.save()
    }
    
    private func deleteHistory(olderThan days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        for item in history where item.parkedAt > cutoff {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
    
    private func deleteAllHistory() {
        for item in history {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

// MARK: - Detail View

struct HistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ParkingHistory
    
    @State private var showSaveAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Foto
                    if let data = item.photoData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Karta
                    Map {
                        Marker("Parkering", coordinate: item.coordinate)
                            .tint(.blue)
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Info
                    VStack(alignment: .leading, spacing: 12) {
                        if let addr = item.address {
                            Label(addr, systemImage: "mappin")
                        }
                        Label(item.parkedAt.formatted(date: .long, time: .shortened), systemImage: "calendar")
                        Label("Varaktighet: \(item.duration)", systemImage: "clock")
                        if let floor = item.floor {
                            Label("Våning: \(floor)", systemImage: "arrow.up.arrow.down")
                        }
                        if let note = item.note {
                            Label(note, systemImage: "note.text")
                        }
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Knappar
                    VStack(spacing: 12) {
                        Button {
                            openInMaps()
                        } label: {
                            Label("Öppna i Kartor", systemImage: "map")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                        
                        if item.photoData != nil {
                            Button {
                                savePhoto()
                            } label: {
                                Label("Spara foto till kamerarulle", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Detaljer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { dismiss() }
                }
            }
            .alert("Foto sparat", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: item.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Tidigare parkering"
        mapItem.openInMaps()
    }
    
    private func savePhoto() {
        guard let data = item.photoData, let image = UIImage(data: data) else { return }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                DispatchQueue.main.async {
                    showSaveAlert = true
                }
            }
        }
    }
}
