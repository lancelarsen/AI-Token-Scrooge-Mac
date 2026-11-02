import AppKit
import AVFoundation
import UserNotifications

@MainActor final class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?
    func play(settings: RadarSettings, cue: String, preview: Bool = false) {
        guard preview || settings.sound, ["alert", "info", "snooze", "dismiss", "refresh"].contains(cue) else { return }
        let name = "\(settings.soundTheme == "Classic" ? "classic" : "duck")-\(cue == "refresh" ? "dismiss" : cue)"
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = Float(min(100, max(0, settings.soundVolume))) / 100
            player?.play()
        } catch { NSSound.beep() }
    }
}

protocol NotificationDelivering: Sendable {
    func authorize() async throws
    func enqueue(id: String, title: String, detail: String, delay: TimeInterval?) async throws
    func cancel(_ id: String) async
}

extension NotificationDelivering {
    func enqueue(id: String, title: String, detail: String) async throws {
        try await enqueue(id: id, title: title, detail: detail, delay: nil)
    }
}

actor NotificationService: NotificationDelivering {
    static let shared = NotificationService()
    func authorize() async throws {
        let center = UNUserNotificationCenter.current()
        do {
            guard try await center.requestAuthorization(options: [.alert, .badge]) else { throw NotificationError.denied }
        } catch { throw NotificationError.explainingPermission(error) }
    }
    func send(id: String, title: String, detail: String, delay: TimeInterval? = nil) async throws {
        try await authorize()
        try await enqueue(id: id, title: title, detail: detail, delay: delay)
    }
    func enqueue(id: String, title: String, detail: String, delay: TimeInterval? = nil) async throws {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = detail
        content.categoryIdentifier = "quota-alert"
        let trigger = delay.map { UNTimeIntervalNotificationTrigger(timeInterval: max(1, $0), repeats: false) }
        do { try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) }
        catch { throw NotificationError.explainingPermission(error) }
    }
    func cancel(_ id: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
}
enum NotificationError: LocalizedError {
    case denied
    var errorDescription: String? { "Notifications are disabled for AI Token Scrooge. In System Settings → Notifications → AI Token Scrooge, turn on Allow notifications." }
    static func explainingPermission(_ error: Error) -> Error {
        let native = error as NSError
        guard native.domain == UNErrorDomain, native.code == UNError.Code.notificationsNotAllowed.rawValue else { return error }
        return NotificationError.denied
    }
}
