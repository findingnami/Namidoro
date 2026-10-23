//
//  MenuBarLabelFormatterTests.swift
//  NamidoroTests
//

import Testing
@testable import Namidoro

struct MenuBarLabelFormatterTests {

    // MARK: - truncatedTitle

    @Test func titleShorterThanLimitIsUnchanged() {
        let result = MenuBarLabelFormatter.truncatedTitle("Short", maxLength: 10)
        #expect(result == "Short")
    }

    @Test func titleExactlyAtLimitIsUnchanged() {
        let title = String(repeating: "a", count: 10)
        let result = MenuBarLabelFormatter.truncatedTitle(title, maxLength: 10)
        #expect(result == title)
    }

    @Test func titleLongerThanLimitIsTruncatedWithEllipsis() {
        let title = String(repeating: "a", count: 15)
        let result = MenuBarLabelFormatter.truncatedTitle(title, maxLength: 10)
        #expect(result == String(repeating: "a", count: 10) + "…")
    }

    // A family emoji (multiple scalars joined by ZWJs) and a flag (a regional-indicator
    // pair) are each a single extended grapheme cluster — Swift's Character-based counting
    // (and therefore .prefix) should treat each as exactly one character, not one per scalar.
    @Test func emojiAndMultiScalarCharactersCountAsOneCharacterEach() {
        let title = "👨‍👩‍👧‍👦🇯🇵📝 Trip planning"
        #expect(title.prefix(3).count == 3)

        let maxLength = 3
        let expected = String(title.prefix(maxLength)) + "…"
        let result = MenuBarLabelFormatter.truncatedTitle(title, maxLength: maxLength)
        #expect(result == expected)
    }

    @Test func limitChangeMovesTheTruncationPoint() {
        let title = String(repeating: "x", count: 30)
        let short = MenuBarLabelFormatter.truncatedTitle(title, maxLength: 5)
        let long = MenuBarLabelFormatter.truncatedTitle(title, maxLength: 20)
        #expect(short == String(repeating: "x", count: 5) + "…")
        #expect(long == String(repeating: "x", count: 20) + "…")
    }

    @Test func newlinesAreFlattenedToSpacesSoTheLabelNeverWraps() {
        let title = "Line one\nLine two\r\nLine three"
        let result = MenuBarLabelFormatter.truncatedTitle(title, maxLength: 50)
        #expect(!result.contains("\n"))
        #expect(!result.contains("\r"))
        #expect(result == "Line one Line two Line three")
    }

    // MARK: - labelText

    @Test func labelTextShowsOnlyMinutesWhenNoTaskSelected() {
        let result = MenuBarLabelFormatter.labelText(minutes: 2, taskTitle: nil, maxTitleLength: 28, showTask: true)
        #expect(result == "2m")
    }

    @Test func labelTextShowsOnlyMinutesWhenShowTaskIsOff() {
        let result = MenuBarLabelFormatter.labelText(minutes: 2, taskTitle: "Write report", maxTitleLength: 28, showTask: false)
        #expect(result == "2m")
    }

    @Test func labelTextCombinesMinutesAndTruncatedTitle() {
        let result = MenuBarLabelFormatter.labelText(minutes: 2, taskTitle: String(repeating: "a", count: 40), maxTitleLength: 28, showTask: true)
        #expect(result == "2m · " + String(repeating: "a", count: 28) + "…")
    }
}
