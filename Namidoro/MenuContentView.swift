//
//  MenuContentView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/8/25.
//

import SwiftUI

// A full-width row with its own hover highlight, used instead of a plain Button so the
// highlight tracks the mouse reliably inside a MenuBarExtra. Needed because the default
// .menu style rebuilds native NSMenuItems whenever @Published state (timeRemaining) changes,
// which resets whatever item AppKit thinks is highlighted — see .menuBarExtraStyle(.window)
// in NamidoroApp.swift, which keeps this as a normal SwiftUI view instead.
struct MenuRow: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .primary
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Group {
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                }
                .frame(width: 16, alignment: .center)

                Text(title)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.accentColor.opacity(0.85) : Color.clear)
            )
            .foregroundStyle(isHovering ? Color.white : tint)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct MenuContentView: View {
    @EnvironmentObject var timerVM: TimerViewModel

    var body: some View {
        Group {
            if timerVM.mode == .work {
                WorkModeView()
            } else {
                // Inline break popover — NOT FullScreenBreakView
                VStack(spacing: 12) {
                    Text("Break")
                        .font(.headline)
                    Text(timerVM.timeDisplay)
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    MenuRow(title: "Skip Break", systemImage: "forward.fill") {
                        timerVM.switchToWorkMode()
                        AppDelegate.closeMenuBarExtraPopover()
                    }
                }
                .frame(width: 250)
                .padding()
            }
        }
    }
}

#Preview("Break") {
    let sampleTimer = TimerViewModel(startTime: TimerViewModel.breakDuration)
    sampleTimer.mode = .breakTime
    return MenuContentView()
        .environmentObject(sampleTimer)
        .environmentObject(TaskStore())
}
