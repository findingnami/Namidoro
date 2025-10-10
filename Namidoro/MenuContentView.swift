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
                FullScreenBreakView()
            }
        }
        .frame(width: 200)
    }
}
