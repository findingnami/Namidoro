//
//  BreakOverlayWindow.swift
//  Namidoro
//

import AppKit

// A borderless window returns false from canBecomeKey by default, which means it never
// receives keyDown events no matter how it's ordered front. Overriding that is what lets
// Escape on the break overlay reach keyDown below at all.
final class BreakOverlayWindow: NSWindow {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 53 else { // Escape
            super.keyDown(with: event)
            return
        }
        onEscape?()
    }
}
