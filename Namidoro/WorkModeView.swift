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

            TaskListView()

            VStack(spacing: 2) {
                MenuRow(title: timerVM.isRunning ? "Pause" : "Start", systemImage: timerVM.isRunning ? "pause.fill" : "play.fill") {
                    timerVM.isRunning ? timerVM.pause() : timerVM.start()
                    AppDelegate.closeMenuBarExtraPopover()
                }

                MenuRow(title: "Start Break Now", systemImage: "cup.and.saucer") {
                    timerVM.switchToBreakMode()
                    AppDelegate.closeMenuBarExtraPopover()
                }

                MenuRow(title: "Quit", systemImage: "power", tint: .secondary) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .frame(width: 240)
        .padding()
    }
}

#Preview {
    let sampleTimer = TimerViewModel(startTime: TimerViewModel.workDuration)
    return WorkModeView()
        .environmentObject(sampleTimer)
        .environmentObject(TaskStore())
}
