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
        setupBreakExitObserver() // 👈 observer added here
    }

    // MARK: - Timer Control
   /* func start() {
        guard !isRunning else { return }
        isRunning = true
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.isRunning && self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    self.menuBarTitle = "\(self.timeRemaining / 60)m"
                    
                    // 🔔 1 minute before break alert (only during work mode)
                    if self.mode == .work && self.timeRemaining == 60 {
                        self.playSound(named: "Alert")
                        self.showMenuBarNotification(title: "Break Incoming", message: "1 minute left before your break!")
                    }
                } else if self.isRunning && self.timeRemaining == 0 {
                    // ⏰ Time’s up — automatically switch modes
                    self.stop()
                    
                    if self.mode == .work {
                        DispatchQueue.main.async {
                            self.switchToBreakMode()
                            self.start()
                        }
                    } else if self.mode == .breakTime {
                        DispatchQueue.main.async {
                            self.switchToWorkMode()
                            self.start()
                        }
                    }
                }
            }
        }
    } */
    
    func start() {
        // if already running, do nothing
        if isRunning { return }
        isRunning = true
        timer?.invalidate()

        // Create a Timer and add it to the main RunLoop in .common mode so UI updates while menus/popovers are open
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // do updates on main thread just in case
            DispatchQueue.main.async {
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
                        self.start()
                    } else {
                        self.switchToWorkMode()
                        self.start()
                    }
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
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    // MARK: - Display Helpers
    var timeDisplay: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Mode Switching
    func switchToWorkMode() {
        mode = .work
        timeRemaining = 2 * 60       // 25 * 60
        isRunning = false
        playSound(named: "Mode")
        NotificationCenter.default.post(name: .didExitBreakMode, object: nil)
    }
    
    func switchToBreakMode() {
        mode = .breakTime
        timeRemaining = 1 * 60       // 5 * 60
        isRunning = false

        // ✅ Ensure sound plays
        playSound(named: "Mode")

        // ✅ Post notification to trigger AppDelegate overlay
        NotificationCenter.default.post(name: .didEnterBreakMode, object: nil)

        print("🟢 Entered Break Mode — Overlay triggered, sound played.")
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
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            } else {
                print("Notification sent: \(title)")
            }
        }
    }
    
    // MARK: - Observer for Break Exit
    private func setupBreakExitObserver() {
        NotificationCenter.default.addObserver(
            forName: .didExitBreakMode,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // ask overlay to fade out
            NotificationCenter.default.post(name: .fadeOutBreakOverlay, object: nil)
            
            // wait for fade-out animation before closing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                self?.hideFullScreenOverlay()
            }
        }
    }

    private func hideFullScreenOverlay() {
        // Add logic to hide or close your fullscreen NSWindow here.
        // If you manage your overlay elsewhere, you can leave this empty.
        print("🟣 Hiding fullscreen overlay after fade-out.")
    }
}

