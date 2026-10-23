//
//  SettingsPanelView.swift
//  Namidoro
//

import SwiftUI

// Shown inline inside the work-mode popover in place of WorkModeView's normal content
// (toggled by its own local @State), never as a separate window — so it inherits the same
// popover-stays-open behavior for free: nothing in here calls AppDelegate.closeMenuBarExtraPopover().
struct SettingsPanelView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.headline)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                Stepper(value: $settingsStore.workMinutes, in: SettingsStore.workMinutesRange) {
                    settingsRow(label: "Work", value: "\(settingsStore.workMinutes) min")
                }
                Stepper(value: $settingsStore.breakMinutes, in: SettingsStore.breakMinutesRange) {
                    settingsRow(label: "Break", value: "\(settingsStore.breakMinutes) min")
                }

                Divider().opacity(0.3)

                Toggle("1-Minute Warning", isOn: $settingsStore.oneMinuteWarningEnabled)
                Toggle("Sounds", isOn: $settingsStore.soundsEnabled)
                Toggle("Launch at Login", isOn: $settingsStore.launchAtLogin)

                if let message = settingsStore.launchAtLoginErrorMessage {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                if settingsStore.notificationsDenied {
                    Divider().opacity(0.3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications are off for Namidoro. Sounds and the break overlay still work.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Button("Open Notification Settings\u{2026}") {
                            SettingsStore.openNotificationSettings()
                        }
                        .font(.caption2)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(10)
            .taskCardBackground()
        }
        .frame(width: 250)
        .padding()
        .onAppear {
            settingsStore.refreshLaunchAtLoginStatus()
            settingsStore.refreshNotificationPermissionStatus()
        }
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

#Preview {
    SettingsPanelView(onBack: {})
        .environmentObject(SettingsStore())
}
