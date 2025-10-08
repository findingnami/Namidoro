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
            // Show full countdown in mm:ss
            Text(timerVM.timeDisplay)
                .font(.title)

            // Start / Pause toggle
            Button(timerVM.isRunning ? "Pause" : "Start") {
                timerVM.isRunning ? timerVM.pause() : timerVM.start()
            }

            // ✅ Start break button — now triggers overlay + sound
            Button("Start Break Now") {
                timerVM.stop()
                timerVM.switchToBreakMode() // This will now:
                                            // - play sound
                                            // - send didEnterBreakMode notification

                // Optional: restart timer after switching
                timerVM.start()
            }

            // Quit button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 200)
        .padding()
        .onAppear {
            timerVM.start()
        }
        .alert("1 minute left before break!", isPresented: $timerVM.showAlert) {
            Button("OK", role: .cancel) { timerVM.showAlert = false }
        }
    }
}

struct WorkModeView_Previews: PreviewProvider {
    static var previews: some View {
        WorkModeView()
    }
}

#Preview {
    WorkModeView()
}
