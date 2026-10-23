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

    // TODO: 25 * 60 / 5 * 60 for release
    static let workDuration: Int = 2 * 60
    static let breakDuration: Int = 1 * 60

    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var mode: TimerMode = .work
    @Published var showAlert: Bool = false

    private var timer: Timer?
    private var hasTriggeredOneMinuteWarning: Bool = false
    private var timerID: UUID = UUID()  // Track the current valid timer

    init(startTime: Int) {
        self.timeRemaining = startTime
        // Timer is started explicitly (AppDelegate.applicationDidFinishLaunching) instead of here.
        // Every TimerViewModel() used to start its own live Timer on creation, which is what let a
        // single stray instance run silently in the background.
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
        
        // Generate a new timer ID for this timer session
        let currentTimerID = UUID()
        timerID = currentTimerID

        // Create a Timer and add it to the main RunLoop in .common mode so UI updates while menus/popovers are open
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // FIRST check: Is this the current valid timer?
            guard self.timerID == currentTimerID else {
                // This is a stale timer, exit immediately
                return
            }
            
            // SECOND check: Is the timer still supposed to be running?
            guard self.isRunning else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1

                // Only trigger the 1-minute warning if we're still in work mode and haven't already triggered it
                // AND this is still the current valid timer
                if self.mode == .work && 
                   self.timeRemaining == 60 && 
                   !self.hasTriggeredOneMinuteWarning &&
                   self.timerID == currentTimerID {
                    self.hasTriggeredOneMinuteWarning = true
                    Self.playSound(named: "Alert")
                    self.showMenuBarNotification(title: "Break Incoming", message: "1 minute left before your break!")
                }
            } else {
                // time up -> switch modes
                // Double-check this is still the valid timer before switching modes
                guard self.timerID == currentTimerID else { return }
                
                self.stop()
                if self.mode == .work {
                    self.switchToBreakMode()
                } else {
                    self.switchToWorkMode()
                }
            }
        }

        self.timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        // timeRemaining is preserved
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Generate a new timer ID to invalidate any stale callbacks
        timerID = UUID()
    }
    
    // MARK: - Mode Switching
    func switchToWorkMode() {
        // Prevent switching if already in work mode
        guard mode != .work else { return }
        
        stop()
        mode = .work
        timeRemaining = Self.workDuration
        hasTriggeredOneMinuteWarning = false  // Reset the flag for the new work session
        Self.playSound(named: "Mode")
        NotificationCenter.default.post(name: .didExitBreakMode, object: self)
        start()
    }
    
    func switchToBreakMode() {
        // Prevent switching if already in break mode
        guard mode != .breakTime else { return }
        
        stop()
        mode = .breakTime
        timeRemaining = Self.breakDuration
        hasTriggeredOneMinuteWarning = false  // Reset for next work session
        Self.playSound(named: "Mode")
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
