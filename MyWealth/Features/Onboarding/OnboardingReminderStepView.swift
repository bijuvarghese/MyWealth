import SwiftUI

struct OnboardingReminderStepView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var remindersEnabled: Bool
    @Binding var reminderType: ReminderType
    @Binding var reminderFrequency: ReminderFrequency
    @StateObject private var reminderManager = ReminderManager.shared

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        primaryTextColor
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Portfolio Reminders", isOn: $remindersEnabled)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Stay on Top of Your Wealth", systemImage: "bell.badge")
                        .font(.title3.bold())
                        .foregroundStyle(primaryTextColor)
                    
                    Text("Get gentle reminders to keep your portfolio updated and review your wealth regularly.")
                        .font(.body)
                        .foregroundStyle(primaryTextColor)
                    
                    Text("You can change this anytime in Settings.")
                        .font(.footnote)
                        .foregroundStyle(secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                }
            }

            if remindersEnabled {
                Section("Reminder Type") {
                    Picker("Type", selection: $reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $reminderFrequency) {
                        ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .onChange(of: remindersEnabled) { _, isEnabled in
            if isEnabled && !reminderManager.isNotificationPermissionGranted {
                reminderManager.requestNotificationPermission()
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
