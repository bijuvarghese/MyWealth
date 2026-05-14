import Foundation
import Combine

class ReminderPreferenceStore: ObservableObject {
    @Published var preference: ReminderPreference {
        didSet {
            savePreference()
        }
    }
    
    private let userDefaultsKey = "com.mywealth.reminder.preference"
    
    init() {
        self.preference = Self.loadPreference()
    }
    
    func savePreference() {
        do {
            let encoded = try JSONEncoder().encode(preference)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Error saving reminder preference: \(error)")
        }
    }
    
    private static func loadPreference() -> ReminderPreference {
        guard let data = UserDefaults.standard.data(forKey: "com.mywealth.reminder.preference") else {
            return ReminderPreference()
        }
        
        do {
            return try JSONDecoder().decode(ReminderPreference.self, from: data)
        } catch {
            print("Error loading reminder preference: \(error)")
            return ReminderPreference()
        }
    }
    
    func reset() {
        preference = ReminderPreference()
    }
}
