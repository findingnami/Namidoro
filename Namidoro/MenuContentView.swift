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
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering ? Color.accentColor.opacity(0.85) : Color.clear)
                )
                .foregroundStyle(isHovering ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
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
                VStack(spacing: 10) {
                    Text("Break")
                        .font(.headline)
                    Text(timerVM.timeDisplay)
                        .font(.title)
                    MenuRow(title: "Skip Break") {
                        timerVM.switchToWorkMode()
                        AppDelegate.closeMenuBarExtraPopover()
                    }
                }
                .frame(width: 200)
                .padding()
            }
        }
    }
}
