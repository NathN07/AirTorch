import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

public final class SystemEventManager {
    public static let shared = SystemEventManager()
    
    private init() {}
    
    public static func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    public static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    public func moveMouse(to screenPoint: CGPoint) {
        CGWarpMouseCursorPosition(screenPoint)
        if let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: screenPoint, mouseButton: .left) {
            event.post(tap: .cgSessionEventTap)
        }
    }
    
    public func leftClick(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        if let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left) {
            down.setIntegerValueField(.mouseEventClickState, value: 1)
            down.post(tap: .cgSessionEventTap)
            down.post(tap: .cghidEventTap)
        }
        usleep(35000) // 35ms pause for OS event queue processing
        if let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
            up.setIntegerValueField(.mouseEventClickState, value: 1)
            up.post(tap: .cgSessionEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
    
    public func leftDown(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        if let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left) {
            event.setIntegerValueField(.mouseEventClickState, value: 1)
            event.post(tap: .cgSessionEventTap)
            event.post(tap: .cghidEventTap)
        }
    }
    
    public func leftUp(at point: CGPoint) {
        if let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
            event.setIntegerValueField(.mouseEventClickState, value: 1)
            event.post(tap: .cgSessionEventTap)
            event.post(tap: .cghidEventTap)
        }
    }
    
    public func leftDrag(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        if let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: point, mouseButton: .left) {
            event.setIntegerValueField(.mouseEventClickState, value: 1)
            event.post(tap: .cgSessionEventTap)
            event.post(tap: .cghidEventTap)
        }
    }
    
    public func rightClick(at point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        if let down = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: point, mouseButton: .right) {
            down.setIntegerValueField(.mouseEventClickState, value: 1)
            down.post(tap: .cgSessionEventTap)
            down.post(tap: .cghidEventTap)
        }
        usleep(35000)
        if let up = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: point, mouseButton: .right) {
            up.setIntegerValueField(.mouseEventClickState, value: 1)
            up.post(tap: .cgSessionEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
    
    public func scroll(deltaY: Int32, deltaX: Int32 = 0) {
        if let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0) {
            event.post(tap: .cgSessionEventTap)
        }
    }
    
    // MARK: - Keyboard Shortcuts & Mission Control
    public func triggerShortcut(virtualKey: CGKeyCode, flags: CGEventFlags) {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: virtualKey, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: virtualKey, keyDown: false) else {
            return
        }
        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cgSessionEventTap)
        keyDown.post(tap: .cghidEventTap)
        usleep(35000)
        keyUp.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
    
    /// Switch Window: cycle through open windows of active application (Cmd + `)
    public func cycleAppWindows() {
        triggerShortcut(virtualKey: 50, flags: .maskCommand)
    }
    
    /// Switch to Next Application (Cmd + Tab)
    public func switchAppForward() {
        triggerShortcut(virtualKey: 48, flags: .maskCommand)
    }
    
    /// Open Mission Control to view all open windows across all apps
    public func missionControl() {
        let url = URL(fileURLWithPath: "/System/Applications/Mission Control.app")
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        } else {
            triggerShortcut(virtualKey: 126, flags: .maskControl)
        }
    }
    
    /// Switch to next Space / Fullscreen App (Ctrl + Right Arrow)
    public func nextSpace() {
        triggerShortcut(virtualKey: 124, flags: .maskControl)
    }
    
    /// Switch to previous Space / Fullscreen App (Ctrl + Left Arrow)
    public func prevSpace() {
        triggerShortcut(virtualKey: 123, flags: .maskControl)
    }
    
    /// Browser Navigation: Back (Cmd + [)
    public func browserBack() {
        triggerShortcut(virtualKey: 33, flags: .maskCommand)
    }
    
    /// Browser Navigation: Forward (Cmd + ])
    public func browserForward() {
        triggerShortcut(virtualKey: 30, flags: .maskCommand)
    }
}
