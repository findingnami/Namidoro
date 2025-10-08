//
//  BreakModeView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/1/25.
//

import SwiftUI

struct BreakModeView: View {
    @ObservedObject var timerVM: TimerViewModel   // share the same timer

    var timeDisplay: String {
        let minutes = timerVM.timeRemaining / 60
        let seconds = timerVM.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(timeDisplay)

            Button(timerVM.isRunning ? "Pause" : "Start") {
                timerVM.isRunning ? timerVM.pause() : timerVM.start()
            }

            Button("Start Work Mode") {
                timerVM.stop()
                timerVM.mode = .work
                timerVM.reset(to: 25 * 60) // 25-minute work
                timerVM.start()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 200)
        .onAppear {
            timerVM.start()  // auto-start break timer
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BreakModeView(timerVM: TimerViewModel(startTime: 5 * 60))
        .padding()
}
