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
}


