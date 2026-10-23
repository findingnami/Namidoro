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

            MenuRow(title: timerVM.isRunning ? "Pause" : "Start") {
                timerVM.isRunning ? timerVM.pause() : timerVM.start()
                AppDelegate.closeMenuBarExtraPopover()
            }

            MenuRow(title: "Start Break Now") {
                timerVM.switchToBreakMode()
                AppDelegate.closeMenuBarExtraPopover()
            }

            MenuRow(title: "Quit") {
                NSApplication.shared.terminate(nil)
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
