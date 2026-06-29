//
//  MenuContentView.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/8/25.
//

import SwiftUI

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
                    Button("Skip Break") {
                        timerVM.switchToWorkMode()
                    }
                }
                .frame(width: 200)
                .padding()
            }
        }
        .frame(width: 200)
    }
}
