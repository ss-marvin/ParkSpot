import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderTimes") private var reminderTimesString = "15,5"
    @AppStorage("defaultTimerMinutes") private var defaultTimer = 60
    
    @State private var reminder1 = 15
    @State private var reminder2 = 5
    @State private var reminder3 = 0
    @State private var enableReminder3 = false
    
    var body: some View {
        NavigationStack {
            List {
                // Notifikationer
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Påminnelse 1")
                            .font(.subheadline.bold())
                        Picker("", selection: $reminder1) {
                            Text("30 min innan").tag(30)
                            Text("15 min innan").tag(15)
                            Text("10 min innan").tag(10)
                            Text("5 min innan").tag(5)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Påminnelse 2")
                            .font(.subheadline.bold())
                        Picker("", selection: $reminder2) {
                            Text("15 min").tag(15)
                            Text("10 min").tag(10)
                            Text("5 min").tag(5)
                            Text("2 min").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Toggle("Extra påminnelse", isOn: $enableReminder3.animation())
                    
                    if enableReminder3 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Påminnelse 3")
                                .font(.subheadline.bold())
                            Picker("", selection: $reminder3) {
                                Text("60 min").tag(60)
                                Text("45 min").tag(45)
                                Text("30 min").tag(30)
                                Text("20 min").tag(20)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                } header: {
                    Text("Notifikationer")
                } footer: {
                    Text("Välj när du vill bli påmind innan parkeringen går ut")
                }
                .onChange(of: reminder1) { _, _ in saveReminders() }
                .onChange(of: reminder2) { _, _ in saveReminders() }
                .onChange(of: reminder3) { _, _ in saveReminders() }
                .onChange(of: enableReminder3) { _, _ in saveReminders() }
                
                // Standard timer
                Section("Standard parkeringstid") {
                    Picker("Tid", selection: $defaultTimer) {
                        Text("30 min").tag(30)
                        Text("1 timme").tag(60)
                        Text("1.5 timmar").tag(90)
                        Text("2 timmar").tag(120)
                        Text("3 timmar").tag(180)
                        Text("4 timmar").tag(240)
                    }
                }
                
                // Behörigheter
                Section("Behörigheter") {
                    Button {
                        NotificationService.shared.requestPermission()
                    } label: {
                        HStack {
                            Label("Notifikationer", systemImage: "bell.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label("Platsåtkomst", systemImage: "location.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                // Om
                Section("Om") {
                    LabeledContent("Version", value: "1.0.0")
                }
            }
            .navigationTitle("Inställningar")
            .onAppear {
                loadReminders()
            }
        }
    }
    
    private func loadReminders() {
        let times = reminderTimesString.split(separator: ",").compactMap { Int($0) }.sorted(by: >)
        if times.count >= 1 { reminder1 = times[0] }
        if times.count >= 2 { reminder2 = times[1] }
        if times.count >= 3 {
            reminder3 = times[2]
            enableReminder3 = true
        }
    }
    
    private func saveReminders() {
        var times = [reminder1, reminder2]
        if enableReminder3 && reminder3 > 0 {
            times.append(reminder3)
        }
        reminderTimesString = times.sorted(by: >).map(String.init).joined(separator: ",")
    }
}

#Preview {
    SettingsView()
}
