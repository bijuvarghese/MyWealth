import SwiftUI

struct ReminderStatusCard: View {
    @StateObject private var reminderManager = ReminderManager.shared
    
    var body: some View {
        if reminderManager.preference.isEnabled {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Reminders Active", systemImage: "bell.badge.fill")
                        .font(.headline)
                        .foregroundColor(.accent)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Type:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(reminderManager.preference.reminderType.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Frequency:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(reminderManager.preference.frequency.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Time:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(reminderManager.preference.reminderTime.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 6)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    ReminderStatusCard()
        .padding()
}
