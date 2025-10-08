//
//  NamidoroApp.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import SwiftUI
import UserNotifications
import AppKit

@main
struct NamidoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerVM = TimerViewModel(startTime: 2 * 60) // 25 * 60

    init() {
        // Link timerVM to AppDelegate
        //        appDelegate.timerVM = timerVM
        
        // Ask for notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

    var body: some Scene {
            MenuBarExtra(isInserted: .constant(true)) {
                // Popover content — attach onAppear HERE ✅
                Group {
                    if timerVM.mode == .work {
                        WorkModeView(timerVM: timerVM)
                    } else {
                        BreakModeView(timerVM: timerVM)
                    }
                }
                .onAppear {
                    appDelegate.timerVM = timerVM
                    print("✅ Linked timerVM to AppDelegate")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "n.circle")
                    Text("\(timerVM.timeRemaining / 60)m")
                }
            }
        }
}
