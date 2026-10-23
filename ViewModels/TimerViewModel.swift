//
//  TimerViewModel.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import Foundation
import AVFoundation
import UserNotifications
import AppKit
import os

extension Notification.Name {
    static let didEnterBreakMode = Notification.Name("didEnterBreakMode")
    static let didExitBreakMode  = Notification.Name("didExitBreakMode")
}

class TimerViewModel: ObservableObject {
    enum TimerMode {
        case work
        case breakTime
    }

    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var mode: TimerMode = .work

    // var, not let: NamidoroApp can't reference one @StateObject from another's default-value
    // expression (Swift struct property defaults can't see sibling properties or self), so the
    // real shared SettingsStore is wired in after construction, from body — mirroring how
    // AppDelegate.timerVM is handed over post-construction rather than threaded through init.
    var settingsStore: SettingsStore
    private let now: () -> Date
    // The wall-clock instant the current session ends. timeRemaining is derived from this on
    // every tick instead of being decremented — a Timer that's suspended for the duration of
    // sleep (see observeSleepWake below) can't drift the countdown the way a per-tick `-= 1`
    // would once it resumes.
    private var endDate: Date?
    private var timer: Timer?
    // private(set) rather than private so tests can assert the warning fired without
    // needing an observable side effect (sound/notification) to hook into.
    private(set) var hasTriggeredOneMinuteWarning: Bool = false
    private var timerID: UUID = UUID()  // Track the current valid timer
    // Captured when a work session starts so a later Settings change (step 5) can't retroactively
    // gate the warning for a session that's already in flight.
    private var workSessionDuration: Int
    private var wasRunningBeforeSleep = false
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    init(startTime: Int? = nil, settingsStore: SettingsStore = SettingsStore(), now: @escaping () -> Date = Date.init) {
        self.settingsStore = settingsStore
        self.now = now
        let resolvedStart = startTime ?? settingsStore.workMinutes * 60
        self.timeRemaining = resolvedStart
        self.workSessionDuration = resolvedStart
        // Timer is started explicitly from NamidoroApp.body, not here — starting it on creation
        // would let any throwaway TimerViewModel run its own live Timer in the background.
        observeSleepWake()
    }

    deinit {
        if let sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver) }
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }

    // MARK: - Display Helpers
    var timeDisplay: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Timer Control
    func start() {
        // if already running, do nothing
        if isRunning { return }

        // Invalidate any existing timer FIRST before setting isRunning
        timer?.invalidate()
        timer = nil

        isRunning = true
        endDate = now().addingTimeInterval(TimeInterval(timeRemaining))

        // Generate a new timer ID for this timer session
        let currentTimerID = UUID()
        timerID = currentTimerID

        // Create a Timer and add it to the main RunLoop in .common mode so UI updates while menus/popovers are open
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.timerID == currentTimerID else {
                // Stale timer from a previous start() — exit immediately
                return
            }
            self.tick()
        }

        self.timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func pause() {
        guard isRunning else { return }
        if let endDate {
            timeRemaining = max(0, Int(ceil(endDate.timeIntervalSince(now()))))
        }
        isRunning = false
        timer?.invalidate()
        timer = nil
        endDate = nil
        // timeRemaining is preserved
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        endDate = nil

        // Generate a new timer ID to invalidate any stale callbacks
        timerID = UUID()
    }

    // Drives one countdown step from `endDate`. Exposed (rather than private) so tests can
    // advance the countdown deterministically through the injected `now` clock instead of
    // waiting on a real Timer and real sleep().
    func tick() {
        guard isRunning, let endDate else { return }

        timeRemaining = max(0, Int(ceil(endDate.timeIntervalSince(now()))))

        if mode == .work,
           settingsStore.oneMinuteWarningEnabled,
           !hasTriggeredOneMinuteWarning,
           workSessionDuration > 60,
           timeRemaining <= 60 {
            hasTriggeredOneMinuteWarning = true
            if settingsStore.soundsEnabled {
                Self.playSound(named: "Alert")
            }
            showMenuBarNotification(title: "Break Incoming", message: "1 minute left before your break!")
        }

        if timeRemaining == 0 {
            stop()
            if mode == .work {
                switchToBreakMode()
            } else {
                switchToWorkMode()
            }
        }
    }

    // MARK: - Sleep / Wake

    // A Timer never fires while the Mac is asleep, but the moment it wakes, RunLoop would
    // otherwise deliver one that computes `endDate.timeIntervalSince(now())` against the
    // POST-wake wall clock — silently consuming the entire sleep duration (and potentially
    // firing a mode switch for a session that "ended" while asleep). Pausing before sleep and
    // resuming with a freshly-computed endDate after wake keeps sleep time from counting at all.
    private func observeSleepWake() {
        let center = NSWorkspace.shared.notificationCenter
        sleepObserver = center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleWillSleep()
        }
        wakeObserver = center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleDidWake()
        }
    }

    private func handleWillSleep() {
        guard isRunning else { return }
        wasRunningBeforeSleep = true
        pause()
    }

    private func handleDidWake() {
        guard wasRunningBeforeSleep else { return }
        wasRunningBeforeSleep = false
        start()
    }

    // MARK: - Mode Switching
    func switchToWorkMode() {
        // Prevent switching if already in work mode
        guard mode != .work else { return }

        stop()
        mode = .work
        // Read fresh from settingsStore here (not cached earlier) so a setting change made
        // mid-session only takes effect for this NEW session, never the one in progress.
        workSessionDuration = settingsStore.workMinutes * 60
        timeRemaining = workSessionDuration
        hasTriggeredOneMinuteWarning = false  // Reset the flag for the new work session
        if settingsStore.soundsEnabled {
            Self.playSound(named: "Mode")
        }
        NotificationCenter.default.post(name: .didExitBreakMode, object: self)
        start()
    }

    func switchToBreakMode() {
        // Prevent switching if already in break mode
        guard mode != .breakTime else { return }

        stop()
        mode = .breakTime
        timeRemaining = settingsStore.breakMinutes * 60
        hasTriggeredOneMinuteWarning = false  // Reset for next work session
        if settingsStore.soundsEnabled {
            Self.playSound(named: "Mode")
        }
        NotificationCenter.default.post(name: .didEnterBreakMode, object: self)
        start()
    }
    
    // MARK: - Sounds

    // Static so every call shares one player registry — a per-instance registry would let a
    // replaced TimerViewModel re-trigger playback from a stale, released AVAudioPlayer.
    private static let audioLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Namidoro", category: "audio")
    private static var audioPlayers: [String: AVAudioPlayer] = [:]
    private static var fallbackSounds: [String: NSSound] = [:]

    static func playSound(named name: String) {
        // Reuse one preloaded AVAudioPlayer per sound name so a strong reference survives
        // for the duration of playback instead of getting replaced/released mid-sound. Two
        // different names (e.g. Alert + Mode firing together) never share a slot, so one
        // can't cut the other off.
        if let existing = audioPlayers[name] {
            existing.currentTime = 0
            existing.play()
            return
        }

        guard let soundURL = Bundle.main.url(forResource: name, withExtension: "wav") else {
            audioLogger.error("playSound: '\(name, privacy: .public).wav' not found — Bundle.main.url(forResource:withExtension:) returned nil")
            playFallback(named: name, url: nil)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            if player.play() {
                audioPlayers[name] = player
            } else {
                audioLogger.error("playSound: AVAudioPlayer.play() returned false for '\(name, privacy: .public)' — falling back to NSSound")
                playFallback(named: name, url: soundURL)
            }
        } catch {
            audioLogger.error("playSound: AVAudioPlayer(contentsOf:) threw for '\(name, privacy: .public)': \(String(describing: error), privacy: .public)")
            playFallback(named: name, url: soundURL)
        }
    }

    private static func playFallback(named name: String, url: URL?) {
        guard let resolvedURL = url ?? Bundle.main.url(forResource: name, withExtension: "wav") else {
            audioLogger.error("playSound fallback: no URL available for '\(name, privacy: .public)', NSSound can't load it either")
            return
        }
        guard let sound = NSSound(contentsOf: resolvedURL, byReference: true) else {
            audioLogger.error("playSound fallback: NSSound(contentsOf:byReference:) failed to load '\(name, privacy: .public)'")
            return
        }
        fallbackSounds[name] = sound
        sound.play()
    }
    
    // MARK: - Notifications
    func showMenuBarNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = nil  // Don't play sound here, we handle it separately with playSound()

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            } else {
                print("Notification sent: \(title)")
            }
        }
    }
}
