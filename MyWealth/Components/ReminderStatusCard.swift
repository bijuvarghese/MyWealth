import SwiftUI

struct ReminderStatusCard: View {
    @StateObject private var reminderManager = ReminderManager.shared
    
    var body: some View {
        if reminderManager.preference.isEnabled {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Reminders Active", systemImage: "bell.badge.fill")
                        .font(WealthMapDesignTokens.Typography.headline)
                        .foregroundColor(WealthMapDesignTokens.ColorToken.brandPrimary)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Type:")
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundColor(WealthMapDesignTokens.ColorToken.textSecondary)
                        Spacer()
                        Text(reminderManager.preference.reminderType.displayName)
                            .font(WealthMapDesignTokens.Typography.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Frequency:")
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundColor(WealthMapDesignTokens.ColorToken.textSecondary)
                        Spacer()
                        Text(reminderManager.preference.frequency.displayName)
                            .font(WealthMapDesignTokens.Typography.caption)
                            .fontWeight(.semibold)
                    }

                    if reminderManager.preference.frequency == .weekly {
                        HStack {
                            Text("Day:")
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundColor(WealthMapDesignTokens.ColorToken.textSecondary)
                            Spacer()
                            Text(reminderManager.preference.weekday.displayName)
                                .font(WealthMapDesignTokens.Typography.caption)
                                .fontWeight(.semibold)
                        }
                    }

                    if reminderManager.preference.frequency == .monthly {
                        HStack {
                            Text("Day:")
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundColor(WealthMapDesignTokens.ColorToken.textSecondary)
                            Spacer()
                            Text("\(reminderManager.preference.monthDay)")
                                .font(WealthMapDesignTokens.Typography.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    HStack {
                        Text("Time:")
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundColor(WealthMapDesignTokens.ColorToken.textSecondary)
                        Spacer()
                        Text(reminderManager.preference.reminderTime.formatted(date: .omitted, time: .shortened))
                            .font(WealthMapDesignTokens.Typography.caption)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 6)
            }
            .padding()
            .background(WealthMapDesignTokens.ColorToken.surfaceGrouped)
            .cornerRadius(8)
        }
    }
}

#Preview {
    ReminderStatusCard()
        .padding()
}
