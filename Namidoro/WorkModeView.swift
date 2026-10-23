//
//  WorkModeView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/1/25.
//

import SwiftUI

struct WorkModeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @State private var showingSettings = false

    var body: some View {
        if showingSettings {
            SettingsPanelView(onBack: { showingSettings = false })
        } else {
            VStack(spacing: 12) {
                Text(timerVM.timeDisplay)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                TaskListView()

                Divider()
                    .opacity(0.3)

                VStack(spacing: 2) {
                    MenuRow(title: timerVM.isRunning ? "Pause" : "Start", systemImage: timerVM.isRunning ? "pause.fill" : "play.fill") {
                        timerVM.isRunning ? timerVM.pause() : timerVM.start()
                        AppDelegate.closeMenuBarExtraPopover()
                    }

                    MenuRow(title: "Start Break Now", systemImage: "cup.and.saucer") {
                        timerVM.switchToBreakMode()
                        AppDelegate.closeMenuBarExtraPopover()
                    }

                    // Does not close the popover — opens the inline panel below instead.
                    MenuRow(title: "Settings", systemImage: "gearshape") {
                        showingSettings = true
                    }

                    // Color.secondary (as a Color, not the hierarchical ShapeStyle) resolves to
                    // NSColor.secondaryLabelColor, which bakes in reduced alpha over labelColor
                    // by system design — that's what read as "greyed out/disabled" at rest.
                    // Color.gray is a fixed, fully-opaque tone: still visually distinct from the
                    // other rows' default .primary tint, without the built-in transparency.
                    MenuRow(title: "Quit", systemImage: "power", tint: .gray) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .frame(width: 250)
            .padding()
        }
    }
}

#Preview {
    let settingsStore = SettingsStore()
    let sampleTimer = TimerViewModel(startTime: settingsStore.workMinutes * 60, settingsStore: settingsStore)
    let sampleStore = TaskStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview-tasks-\(UUID()).json"))
    sampleStore.tasks = [
        TaskItem(title: "Write quarterly report"),
        TaskItem(title: "Review PR feedback"),
        TaskItem(title: "Buy groceries", isDone: true)
    ]
    sampleStore.selectedTaskID = sampleStore.tasks[0].id
    return WorkModeView()
        .environmentObject(sampleTimer)
        .environmentObject(sampleStore)
        .environmentObject(settingsStore)
}
