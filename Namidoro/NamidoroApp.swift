//
//  NamidoroApp.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import SwiftUI

@main
struct NamidoroApp: App {
    @StateObject private var timerVM = TimerViewModel(startTime: 2 * 60) // change to 25 * 60 once done testing

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            // Popover content
            if timerVM.mode == .work {
                            WorkModeView(timerVM: timerVM)
                        } else {
                            BreakModeView(timerVM: timerVM)
                        }
        } label: {
            // Label with icon on left, dynamic minutes on right
            HStack(spacing: 4) {
                Image(systemName: "n.circle")
                Text("\(timerVM.timeRemaining / 60)m")
            }
        }
        
        // 🔹 Full-screen window appears in break mode
                WindowGroup {
                    if timerVM.mode == .breakTime {
                        FullScreenBreakView(timerVM: timerVM)
                            .ignoresSafeArea()
                    } else {
                        EmptyView()
                    }
                }
                .windowStyle(.hiddenTitleBar)
                .windowResizability(.contentSize)
    }
}
