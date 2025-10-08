//
//  TimerViewModel.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import SwiftUI
import Combine
import AVFoundation
import UserNotifications

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
    @Published var menuBarTitle: String // dynamically updates menu bar
    @Published var mode: TimerMode = .work
    @Published var showAlert: Bool = false
    @Published var showBreakAlertPopover = false

    private var timer: Timer?

    init(startTime: Int) {
        self.timeRemaining = startTime
        self.menuBarTitle = "\(startTime / 60)m"
        self.start()
    }

    // Start timer
    func start() {
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
                    
                    if self.mode == .work && self.timeRemaining == 0 {
                                        DispatchQueue.main.async {
                                            self.switchToBreakMode()
                                            self.start()
                                        }
                                    } else if self.mode == .breakTime && self.timeRemaining == 0 {
                                        DispatchQueue.main.async {
                                            self.switchToWorkMode()
                                            self.start()
                                        }
                                    }
                }
            }
        }
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

    // Optional: formatted mm:ss for popover display
    var timeDisplay: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func switchToWorkMode() {
        mode = .work
        timeRemaining = 25 * 60                    // 25 * 60 // 25 minutes
        isRunning = false
        playSound(named: "Mode")
        NotificationCenter.default.post(name: .didExitBreakMode, object: nil)
    }

    func switchToBreakMode() {
        mode = .breakTime
        timeRemaining = 5 * 60                           // 5 * 60 // 5 minutes
        isRunning = false
        playSound(named: "Mode")
        NotificationCenter.default.post(name: .didEnterBreakMode, object: nil)
    }
    
    private var audioPlayer: AVAudioPlayer?

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
}


