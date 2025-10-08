//
//  FullScreenBreakView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/6/25.
//

import SwiftUI

struct FullScreenBreakView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @State private var currentTime = Date()
    @State private var isVisible = false // fade animation
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // match this duration in AppDelegate when hiding the window
    static let animationDuration: TimeInterval = 0.5

    var body: some View {
        ZStack {
            // background blur + content always present so opacity animation works reliably
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: Self.animationDuration), value: isVisible)

            VStack(spacing: 20) {
                Text("Take a pause for a few minutes.")
                    .font(.system(size: 36, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text(timerVM.timeDisplay)
                    .font(.system(size: 80, weight: .bold))
                    .monospacedDigit()

                Button("Skip Break") {
                    // local fade + then tell VM to switch
                    withAnimation(.easeOut(duration: Self.animationDuration)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + Self.animationDuration) {
                        // switch back to work mode - this will also trigger notifications
                        timerVM.stop()
                        timerVM.switchToWorkMode()
                        timerVM.reset(to: 2 * 60) // 25 * 60
                        timerVM.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.title3)
                .padding(.top, 10)

                Text(currentTime.formatted(date: .omitted, time: .shortened))
                    .font(.headline)
                    .padding(.top, 30)
                    .onReceive(timer) { time in currentTime = time }
            }
            .padding()
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: Self.animationDuration), value: isVisible)
        }
        .onAppear {
            // fade in
            withAnimation(.easeIn(duration: Self.animationDuration)) {
                isVisible = true
            }
        }
        // Listen for AppDelegate asking overlay to fade out
        .onReceive(NotificationCenter.default.publisher(for: .fadeOutBreakOverlay)) { _ in
            withAnimation(.easeOut(duration: Self.animationDuration)) {
                isVisible = false
            }
        }
    }
}

#Preview {
    let sampleTimer = TimerViewModel(startTime: 5 * 60)
    sampleTimer.mode = .breakTime
    return FullScreenBreakView()
}
