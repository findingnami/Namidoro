//
//  WorkModeView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/1/25.
//

import SwiftUI

struct WorkModeView: View {
    @ObservedObject var timerVM: TimerViewModel
    @State private var showFullScreenBreak = false

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
                timerVM.mode = .breakTime
                timerVM.reset(to: 1 * 60) // 5-minute break
                timerVM.start()
                
                // Activate FullScreenBreakView
                showFullScreenBreak = true
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
        .alert("1 minute left before break!", isPresented: $timerVM.showAlert) {
            Button("OK", role: .cancel) { timerVM.showAlert = false }
        }
        
        // Full-screen break overlay
                    if showFullScreenBreak {
                        FullScreenBreakView(timerVM: timerVM)
                            .edgesIgnoringSafeArea(.all)
                            .transition(.opacity)
                            .onReceive(timerVM.$mode) { mode in
                                // Hide full screen when back to work
                                if mode == .work {
                                    withAnimation {
                                        showFullScreenBreak = false
                                    }
                                }
                            }
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
