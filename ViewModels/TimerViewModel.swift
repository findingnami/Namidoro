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

extension Notification.Name {
    static let didEnterBreakMode = Notification.Name("didEnterBreakMode")
    static let didExitBreakMode  = Notification.Name("didExitBreakMode")
    static let fadeOutBreakOverlay = Notification.Name("fadeOutBreakOverlay")
}

class TimerViewModel: ObservableObject {
    enum TimerMode {
        case work
        case breakTime
    }
    
    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var menuBarTitle: String // dynamically updates menu bar
    @Published var mode: TimerMode = .work
    @Published var showAlert: Bool = false
    @Published var showBreakAlertPopover = false

    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?

    init(startTime: Int) {
        self.timeRemaining = startTime
        self.menuBarTitle = "\(startTime / 60)m"
        self.start()
    }

    // MARK: - Timer Control
    func start() {
        // if already running, do nothing
        if isRunning { return }
        
        // Invalidate any existing timer FIRST before setting isRunning
        timer?.invalidate()
        timer = nil
        
        isRunning = true

        // Create a Timer and add it to the main RunLoop in .common mode so UI updates while menus/popovers are open
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.isRunning else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                self.menuBarTitle = "\(self.timeRemaining / 60)m"

                if self.mode == .work && self.timeRemaining == 60 {
                    self.playSound(named: "Alert")
                    self.showMenuBarNotification(title: "Break Incoming", message: "1 minute left before your break!")
                }
            } else {
                // time up -> switch modes
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

    func pause() { isRunning = false }

    func reset(to seconds: Int) {
        isRunning = false
        timeRemaining = seconds
        menuBarTitle = "\(seconds / 60)m"
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Display Helpers
    var timeDisplay: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Mode Switching
    func switchToWorkMode() {
        stop()  // Ensure timer is fully stopped first
        mode = .work
        timeRemaining = 2 * 60       // 25 * 60
        menuBarTitle = "\(timeRemaining / 60)m"
        playSound(named: "Mode")
        NotificationCenter.default.post(name: .didExitBreakMode, object: nil)
        start()  // Start the work timer
    }
    
    func switchToBreakMode() {
        stop()  // Ensure timer is fully stopped first
        mode = .breakTime
        timeRemaining = 1 * 60       // 5 * 60
        menuBarTitle = "\(timeRemaining / 60)m"
        playSound(named: "Mode")
        NotificationCenter.default.post(name: .didEnterBreakMode, object: self)
        start()  // Start the break timer
    }
    
    // MARK: - Sounds
    func playSound(named name: String) {
        if let soundURL = Bundle.main.url(forResource: name, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error)")
            }
        } else {
            print("Sound file not found: \(name)")
        }
    }
    
    // MARK: - Notifications
    func showSystemAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
    
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

