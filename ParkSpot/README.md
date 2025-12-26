# 🚗 ParkSpot

Snabb och enkel parkerings-app för iPhone.

## Funktioner

### Kärnfunktioner
- ✅ **Kamera först** - Ta bild direkt när du parkerar
- ✅ **GPS-sparning** - Position sparas automatiskt
- ✅ **Manuell radering** - Ta bort när du hittat bilen

### Avancerade funktioner
- ✅ **Flexibel parkeringstimer** - Slider från 15 min till 8 timmar
- ✅ **Anpassningsbara notiser** - Välj 2-3 påminnelser
- ✅ **Anteckningar** - Våning och övrigt
- ✅ **Parkeringshistorik** - Med radera-funktion (tid eller allt)
- ✅ **Dela position** - Skicka till vänner
- ✅ **Walking directions** - Med kompass
- ✅ **Spara till kamerarulle** - Valfritt, manuellt

### Kommer snart
- 🔜 Widget
- 🔜 AR Navigation
- 🔜 Apple Watch

## Installation

1. Skapa nytt iOS-projekt i Xcode (iOS 17+)
2. Kopiera alla filer från zip
3. Lägg till i Info.plist:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>ParkSpot behöver din plats för att spara var du parkerat.</string>

<key>NSCameraUsageDescription</key>
<string>ParkSpot använder kameran för att fotografera din parkeringsplats.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>ParkSpot kan spara bilder till din kamerarulle om du vill.</string>
```

## Struktur

```
ParkSpot/
├── App/
│   └── ParkSpotApp.swift
├── Models/
│   └── ParkingSpot.swift
├── Services/
│   ├── LocationService.swift
│   └── NotificationService.swift
└── Views/
    ├── MainTabView.swift
    ├── HomeView.swift
    ├── CameraView.swift
    ├── SaveParkingView.swift
    ├── NavigateView.swift
    ├── HistoryView.swift
    └── SettingsView.swift
```

## Användning

1. **Parkera** - Tryck på den stora blå knappen → Kameran öppnas → Ta bild
2. **Spara** - Lägg till info (valfritt) → Spara
3. **Hitta** - Tryck "Hitta bilen" → Följ kompassen
4. **Klar** - Tryck "Jag har hittat bilen" → Sparas till historik

---
Made with ❤️ in Sweden
