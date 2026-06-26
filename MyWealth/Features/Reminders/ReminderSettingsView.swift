import SwiftUI

struct ReminderSettingsView: View {
    @StateObject private var reminderManager = ReminderManager.shared
    @State private var showPermissionAlert = false

    var body: some View {
        Form {
            Section("Reminder Status") {
                HStack {
                    Text("Notifications Permission")
                    Spacer()
                    if reminderManager.isNotificationPermissionGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(WealthMapDesignTokens.ColorToken.success)
                    } else {
                        Button(action: requestPermission) {
                            Text("Enable")
                                .foregroundColor(WealthMapDesignTokens.ColorToken.info)
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
                    .tint(WealthMapDesignTokens.ColorToken.brandPrimary)
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

                    if reminderManager.preference.frequency == .weekly {
                        Section("Alert Day") {
                            Picker("Day of Week", selection: Binding(
                                get: { reminderManager.preference.weekday },
                                set: { newWeekday in
                                    reminderManager.updateReminderPreference(weekday: newWeekday)
                                }
                            )) {
                                ForEach(ReminderWeekday.allCases) { weekday in
                                    Text(weekday.displayName).tag(weekday)
                                }
                            }
                        }
                    }

                    if reminderManager.preference.frequency == .monthly {
                        Section {
                            Picker("Day of Month", selection: Binding(
                                get: { reminderManager.preference.monthDay },
                                set: { newMonthDay in
                                    reminderManager.updateReminderPreference(monthDay: newMonthDay)
                                }
                            )) {
                                ForEach(1...ReminderPreference.maximumMonthlyReminderDay, id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                        } header: {
                            Text("Alert Day")
                        } footer: {
                            Text("Monthly reminders use days 1-28 so they run every month, including February and leap years. Days 29-31 are not offered because some months do not have them.")
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
                                    .font(WealthMapDesignTokens.Typography.headline)
                            } icon: {
                                Image(systemName: "sparkles")
                            }

                            Text("Reminders will be sent based on your portfolio activity. If you've recently updated your assets, duplicate reminders are skipped to avoid overload.")
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundColor(WealthMapDesignTokens.ColorToken.textSecondary)
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
    NavigationStack {
        ReminderSettingsView()
    }
}
