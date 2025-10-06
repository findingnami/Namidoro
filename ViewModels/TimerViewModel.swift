//
//  TimerViewModel.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import SwiftUI
import Combine

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

    private var timer: Timer?

    init(startTime: Int) {
        self.timeRemaining = startTime
        self.menuBarTitle = "\(startTime / 60)m"
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
                    
                    // 🔔 Trigger alert 1 minute before break (only in work mode)
                    if self.mode == .work && self.timeRemaining == 60 {
                        self.showAlert = true
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
        timeRemaining = 25 * 60 // 25 minutes
        isRunning = false
    }

    func switchToBreakMode() {
        mode = .breakTime
        timeRemaining = 5 * 60 // 5 minutes
        isRunning = false
    }
}


