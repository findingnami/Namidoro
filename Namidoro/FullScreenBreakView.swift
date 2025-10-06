//
//  FullScreenBreakView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/6/25.
//

import SwiftUI

struct FullScreenBreakView: View {
    @ObservedObject var timerVM: TimerViewModel
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 🔹 Background Blur
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // 🧘 Message
                Text("Take a pause for a few minutes.")
                    .font(.system(size: 36, weight: .semibold))
                    .multilineTextAlignment(.center)

                // ⏳ Countdown synced with timerVM
                Text(timerVM.timeDisplay)
                    .font(.system(size: 80, weight: .bold))
                    .monospacedDigit()

                // 🚫 Skip Break button
                Button("Skip Break") {
                    self.timerVM.stop()
                    self.timerVM.switchToWorkMode()
                }
                .buttonStyle(.borderedProminent)
                .font(.title3)
                .padding(.top, 10)

                // 🕒 Current time
                Text(currentTime.formatted(date: .omitted, time: .shortened))
                    .font(.headline)
                    .padding(.top, 30)
                    .onReceive(timer) { time in
                        currentTime = time
                    }
            }
            .padding()
        }
    }
}

#Preview {
    let sampleTimer = TimerViewModel(startTime: 5 * 60)
    sampleTimer.mode = .breakTime
    return FullScreenBreakView(timerVM: sampleTimer)
}
