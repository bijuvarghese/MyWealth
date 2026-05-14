import SwiftUI

struct OnboardingReminderStepView: View {
    @Binding var remindersEnabled: Bool
    @Binding var reminderType: ReminderType
    @Binding var reminderFrequency: ReminderFrequency
    @StateObject private var reminderManager = ReminderManager.shared

    var body: some View {
        Form {
            Section {
                Toggle("Enable Portfolio Reminders", isOn: $remindersEnabled)
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Stay on Top of Your Wealth", systemImage: "bell.badge")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Get gentle reminders to keep your portfolio updated and review your wealth regularly.")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text("You can change this anytime in Settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if remindersEnabled {
                Section("Reminder Type") {
                    Picker("Type", selection: $reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $reminderFrequency) {
                        ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Smart Reminders", systemImage: "sparkles")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        Text("We'll skip reminders if you've recently updated your assets, and remind you if your portfolio hasn't been updated in a while.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onChange(of: reminderManager.isNotificationPermissionGranted) { _, isGranted in
            if isGranted {
                remindersEnabled = true
            }
        }
    }
}

#Preview {
    OnboardingReminderStepView(
        remindersEnabled: .constant(true),
        reminderType: .constant(.reviewPortfolio),
        reminderFrequency: .constant(.weekly)
    )
}
