//
//  WorkModeView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/1/25.
//

import SwiftUI

struct WorkModeView: View {
    @EnvironmentObject var timerVM: TimerViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text(timerVM.timeDisplay)
                .font(.title)

            Button(timerVM.isRunning ? "Pause" : "Start") {
                timerVM.isRunning ? timerVM.pause() : timerVM.start()
            }

            Button("Start Break Now") {
                timerVM.switchToBreakMode()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 200)
        .padding()
    }
}

#Preview {
    let sampleTimer = TimerViewModel(startTime: 25 * 60)
    return WorkModeView()
        .environmentObject(sampleTimer)
}
