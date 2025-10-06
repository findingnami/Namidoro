//
//  WorkModeView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/1/25.
//

import SwiftUI

struct WorkModeView: View {
    @ObservedObject var timerVM: TimerViewModel

    var body: some View {
        VStack(spacing: 10) {
            // Show full countdown in mm:ss
            Text(timerVM.timeDisplay)
                .font(.title)

            // Start / Pause toggle
            Button(timerVM.isRunning ? "Pause" : "Start") {
                timerVM.isRunning ? timerVM.pause() : timerVM.start()
            }

            // Start break placeholder
            Button("Start Break Now") {
                timerVM.stop()
                print("Switch to break mode") // implement later
            }

            // Quit button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 200)
        .padding()
        .onAppear {
            timerVM.start() // automatically start when popover opens
        }
    }
}

struct WorkModeView_Previews: PreviewProvider {
    static var previews: some View {
        WorkModeView(timerVM: TimerViewModel(startTime: 25 * 60))
    }
}

#Preview {
    WorkModeView(timerVM: TimerViewModel(startTime: 1500))
}
