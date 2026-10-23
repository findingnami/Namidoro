//
//  SettingsStore.swift
//  Namidoro
//

import Foundation
import ServiceManagement
import UserNotifications
import AppKit
import os

final class SettingsStore: ObservableObject {
    static let workMinutesRange = 1...120
    static let breakMinutesRange = 1...60
    static let menuBarTitleLengthRange = 10...50

    @Published var workMinutes: Int {
        didSet {
            let clamped = Self.clamp(workMinutes, to: Self.workMinutesRange)
            guard clamped == workMinutes else { workMinutes = clamped; return }
            persist()
        }
    }
    @Published var breakMinutes: Int {
        didSet {
            let clamped = Self.clamp(breakMinutes, to: Self.breakMinutesRange)
            guard clamped == breakMinutes else { breakMinutes = clamped; return }
            persist()
        }
    }
    @Published var oneMinuteWarningEnabled: Bool { didSet { persist() } }
    @Published var soundsEnabled: Bool { didSet { persist() } }

    @Published var menuBarTitleLength: Int {
        didSet {
            let clamped = Self.clamp(menuBarTitleLength, to: Self.menuBarTitleLengthRange)
            guard clamped == menuBarTitleLength else { menuBarTitleLength = clamped; return }
            persist()
        }
    }
    @Published var showTaskInMenuBar: Bool { didSet { persist() } }

    // Mirrors SMAppService.mainApp.status. Toggling it from the UI drives register()/
    // unregister(); syncing it FROM that status (refreshLaunchAtLoginStatus) must not
    // re-trigger that side effect, hence the guard in the didSet below.
    @Published var launchAtLogin: Bool {
        didSet {
            guard !isSyncingLaunchAtLoginFromSystem, launchAtLogin != oldValue else { return }
            applyLaunchAtLoginChange(enable: launchAtLogin)
        }
    }
    @Published private(set) var launchAtLoginErrorMessage: String?

    // Sounds and the break overlay don't depend on this — only the banner notification
    // (showMenuBarNotification) does, and that silently no-ops when denied. This just
    // drives whether the Settings panel shows a notice about it.
    @Published private(set) var notificationsDenied = false

    private var isSyncingLaunchAtLoginFromSystem = false
    private let defaults: UserDefaults
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Namidoro", category: "SettingsStore")

    private enum Keys {
        static let workMinutes = "workMinutes"
        static let breakMinutes = "breakMinutes"
        static let oneMinuteWarningEnabled = "oneMinuteWarningEnabled"
        static let soundsEnabled = "soundsEnabled"
        static let menuBarTitleLength = "menuBarTitleLength"
        static let showTaskInMenuBar = "showTaskInMenuBar"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedWork = defaults.object(forKey: Keys.workMinutes) as? Int
        let storedBreak = defaults.object(forKey: Keys.breakMinutes) as? Int
        let storedTitleLength = defaults.object(forKey: Keys.menuBarTitleLength) as? Int
        self.workMinutes = Self.clamp(storedWork ?? 25, to: Self.workMinutesRange)
        self.breakMinutes = Self.clamp(storedBreak ?? 5, to: Self.breakMinutesRange)
        self.oneMinuteWarningEnabled = defaults.object(forKey: Keys.oneMinuteWarningEnabled) as? Bool ?? true
        self.soundsEnabled = defaults.object(forKey: Keys.soundsEnabled) as? Bool ?? true
        self.menuBarTitleLength = Self.clamp(storedTitleLength ?? 28, to: Self.menuBarTitleLengthRange)
        self.showTaskInMenuBar = defaults.object(forKey: Keys.showTaskInMenuBar) as? Bool ?? true
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private func persist() {
        defaults.set(workMinutes, forKey: Keys.workMinutes)
        defaults.set(breakMinutes, forKey: Keys.breakMinutes)
        defaults.set(oneMinuteWarningEnabled, forKey: Keys.oneMinuteWarningEnabled)
        defaults.set(soundsEnabled, forKey: Keys.soundsEnabled)
        defaults.set(menuBarTitleLength, forKey: Keys.menuBarTitleLength)
        defaults.set(showTaskInMenuBar, forKey: Keys.showTaskInMenuBar)
    }

    // MARK: - Launch at Login

    // Call when the Settings panel appears — SMAppService's status can change outside the
    // app (e.g. the user removed it in System Settings > General > Login Items) and the
    // toggle would otherwise go stale.
    func refreshLaunchAtLoginStatus() {
        let isEnabled = SMAppService.mainApp.status == .enabled
        guard isEnabled != launchAtLogin else { return }
        isSyncingLaunchAtLoginFromSystem = true
        launchAtLogin = isEnabled
        isSyncingLaunchAtLoginFromSystem = false
    }

    private func applyLaunchAtLoginChange(enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginErrorMessage = nil
        } catch {
            Self.logger.error("SMAppService \(enable ? "register" : "unregister", privacy: .public) failed: \(String(describing: error), privacy: .public)")
            launchAtLoginErrorMessage = enable
                ? "Couldn't enable Launch at Login. Make sure Namidoro is in /Applications, then try again."
                : "Couldn't disable Launch at Login. Try again from System Settings \u{203A} General \u{203A} Login Items."
            isSyncingLaunchAtLoginFromSystem = true
            launchAtLogin = !enable
            isSyncingLaunchAtLoginFromSystem = false
        }
    }

    // MARK: - Notification Permission

    // Call when the Settings panel appears — the user may have changed this in System
    // Settings since the app last asked, or since it last checked.
    func refreshNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsDenied = settings.authorizationStatus == .denied
            }
        }
    }

    static func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
