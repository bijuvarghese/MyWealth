import SwiftUI

struct ReminderSettingsView: View {
    @StateObject private var reminderManager = ReminderManager.shared
    @State private var showPermissionAlert = false
    @State private var selectedTime = ReminderPreference.defaultReminderTime()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder Status") {
                    HStack {
                        Text("Notifications Permission")
                        Spacer()
                        if reminderManager.isNotificationPermissionGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button(action: requestPermission) {
                                Text("Enable")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if reminderManager.isNotificationPermissionGranted {
                    Section("Reminder Settings") {
                        Toggle("Enable Reminders", isOn: Binding(
                            get: { reminderManager.preference.isEnabled },
                            set: { newValue in
                                if newValue {
                                    reminderManager.enableReminders()
                                } else {
                                    reminderManager.disableReminders()
                                }
                            }
                        ))
                    }
                    
                    if reminderManager.preference.isEnabled {
                        
                        Section("Frequency") {
                            Picker("Frequency", selection: Binding(
                                get: { reminderManager.preference.frequency },
                                set: { newFrequency in
                                    reminderManager.updateReminderPreference(frequency: newFrequency)
                                }
                            )) {
                                ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                                    Text(frequency.displayName).tag(frequency)
                                }
                            }
                        }
                        
                        Section("Reminder Time") {
                            DatePicker(
                                "Time",
                                selection: Binding(
                                    get: { reminderManager.preference.reminderTime },
                                    set: { newTime in
                                        reminderManager.updateReminderPreference(time: newTime)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                        
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text("Smart Reminders")
                                        .font(.headline)
                                } icon: {
                                    Image(systemName: "sparkles")
                                }
                                
                                Text("Reminders will be sent based on your portfolio activity. If you've recently updated your assets, duplicate reminders are skipped to avoid overload.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("How It Works")
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Enable Notifications", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Enable notifications in Settings to receive reminders about your portfolio.")
        }
    }
    
    private func requestPermission() {
        reminderManager.requestNotificationPermission()
        if !reminderManager.isNotificationPermissionGranted {
            showPermissionAlert = true
        }
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

#Preview {
    ReminderSettingsView()
}
