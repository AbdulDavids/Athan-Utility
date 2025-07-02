import Foundation
import Adhan
#if canImport(AlarmKit)
import AlarmKit
#endif

/// Manages syncing iOS alarms with the daily Fajr prayer time.
/// Requires iOS 26's AlarmKit framework.
@available(iOS 26.0, *)
class AlarmSyncManager {
    static let shared = AlarmSyncManager()
    private var alarmStore: AKAlarmStore

    private init() {
#if canImport(AlarmKit)
        alarmStore = AKAlarmStore()
#else
        alarmStore = AKAlarmStore()
#endif
    }

    /// Settings controlling how the alarm sync behaves.
    struct Settings: Codable {
        var isEnabled: Bool = false
        /// Minutes offset from the calculated Fajr time.
        var offsetMinutes: Int = 0
        /// Weekday numbers (1-7) on which the alarm should fire.
        var daysOfWeek: [Int] = Array(1...7)

        static let archiveName = "alarmsyncsettings"

        static var shared: Settings = {
            if let data = unarchiveData(archiveName) as? Data,
               let decoded = try? JSONDecoder().decode(Settings.self, from: data) {
                return decoded
            } else {
                return Settings()
            }
        }()

        static func archive() {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(Settings.shared) as? Data {
                archiveData(archiveName, object: data)
            }
        }
    }

    /// Updates the Fajr alarm according to today's calculated time.
    func syncFajrAlarm(prayerTimes: PrayerTimes) {
        guard Settings.shared.isEnabled else { return }
        let fajrDate = Calendar.current.date(byAdding: .minute,
                                             value: Settings.shared.offsetMinutes,
                                             to: prayerTimes.fajr)!
        // Remove existing alarms created by the app.
        alarmStore.getAllAlarms { alarms in
            for alarm in alarms where alarm.label == "Athan Fajr" {
                self.alarmStore.removeAlarm(alarm)
            }
            self.createAlarm(date: fajrDate)
        }
    }

    private func createAlarm(date: Date) {
        var components = Calendar.current.dateComponents([.hour, .minute], from: date)
        components.weekday = nil
        let newAlarm = AKAlarm(fireDateComponents: components)
        newAlarm.enabled = true
        newAlarm.label = "Athan Fajr"
        newAlarm.repeatSchedule = Settings.shared.daysOfWeek
        alarmStore.addAlarm(newAlarm)
    }
}
