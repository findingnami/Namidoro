//
//  MenuBarLabelFormatter.swift
//  Namidoro
//

import Foundation

// Pure string formatting for the MenuBarExtra label, pulled out of NamidoroApp (a struct
// App can't host @testable-visible private helpers in a way unit tests can reach) so it has
// its own test coverage independent of the label's SwiftUI rendering.
enum MenuBarLabelFormatter {
    // "\(minutes)m" when no task is selected (or showTask is off), else
    // "\(minutes)m · \(truncated title)" — always a single Text, never two.
    static func labelText(minutes: Int, taskTitle: String?, maxTitleLength: Int, showTask: Bool) -> String {
        guard showTask, let taskTitle, !taskTitle.isEmpty else { return "\(minutes)m" }
        return "\(minutes)m · \(truncatedTitle(taskTitle, maxLength: maxTitleLength))"
    }

    // Truncates to maxLength Characters (grapheme clusters, so multi-scalar emoji and flags
    // count as one each, same as the rest of Swift's String API) and flattens any newlines
    // to spaces first — the menu bar label must never wrap or break across lines.
    static func truncatedTitle(_ title: String, maxLength: Int) -> String {
        let singleLine = title
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        guard singleLine.count > maxLength else { return singleLine }
        return String(singleLine.prefix(maxLength)) + "…"
    }
}
