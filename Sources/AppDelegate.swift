import Foundation
import AppKit
import CoreMedia

public final class AppDelegate: NSObject, NSApplicationDelegate, CameraManagerDelegate, GestureEngineDelegate {
    private var statusItem: NSStatusItem!
    private var activeMenuItem: NSMenuItem!
    private var hudMenuItem: NSMenuItem!
    
    private let cameraManager = CameraManager()
    private let handTracker = HandTracker()
    private let gestureEngine = GestureEngine()
    private var overlayController: OverlayWindowController!
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Overlay HUD
        overlayController = OverlayWindowController()
        
        // Setup Menu Bar Item
        setupStatusBar()
        
        // Wire delegates
        cameraManager.delegate = self
        gestureEngine.delegate = self
        
        // Check Accessibility Permission
        let hasAccessibility = SystemEventManager.isAccessibilityTrusted()
        if !hasAccessibility {
            SystemEventManager.requestAccessibilityPermission()
            promptForAccessibility()
        }
        
        // Start Camera
        cameraManager.startSession()
        print("[AirTouch] Application initialized and running.")
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✋ AirTouch"
        }
        
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "AirTouch Air Trackpad v1.0", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        activeMenuItem = NSMenuItem(title: "✓ Tracking Enabled", action: #selector(toggleTracking), keyEquivalent: "t")
        activeMenuItem.target = self
        menu.addItem(activeMenuItem)
        
        hudMenuItem = NSMenuItem(title: "✓ Show Floating HUD", action: #selector(toggleHUD), keyEquivalent: "h")
        hudMenuItem.target = self
        menu.addItem(hudMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Sensitivity Submenu
        let sensitivityMenu = NSMenu()
        let lowItem = NSMenuItem(title: "Low (0.8x)", action: #selector(setSensitivityLow), keyEquivalent: "")
        lowItem.target = self
        let normItem = NSMenuItem(title: "✓ Normal (1.2x)", action: #selector(setSensitivityNorm), keyEquivalent: "")
        normItem.target = self
        let highItem = NSMenuItem(title: "High (1.8x)", action: #selector(setSensitivityHigh), keyEquivalent: "")
        highItem.target = self
        
        sensitivityMenu.addItem(lowItem)
        sensitivityMenu.addItem(normItem)
        sensitivityMenu.addItem(highItem)
        
        let sensitivityItem = NSMenuItem(title: "Pointer Sensitivity", action: nil, keyEquivalent: "")
        sensitivityItem.submenu = sensitivityMenu
        menu.addItem(sensitivityItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let permItem = NSMenuItem(title: "Check Permissions...", action: #selector(openSystemPermissions), keyEquivalent: "p")
        permItem.target = self
        menu.addItem(permItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit AirTouch", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func toggleTracking() {
        gestureEngine.isEnabled.toggle()
        activeMenuItem.title = gestureEngine.isEnabled ? "✓ Tracking Enabled" : "Tracking Disabled"
    }
    
    @objc private func toggleHUD() {
        overlayController.isVisible.toggle()
        hudMenuItem.title = overlayController.isVisible ? "✓ Show Floating HUD" : "Show Floating HUD"
    }
    
    @objc private func setSensitivityLow() {
        gestureEngine.sensitivity = 0.8
        updateSensitivityChecks(selected: 0)
    }
    
    @objc private func setSensitivityNorm() {
        gestureEngine.sensitivity = 1.2
        updateSensitivityChecks(selected: 1)
    }
    
    @objc private func setSensitivityHigh() {
        gestureEngine.sensitivity = 1.8
        updateSensitivityChecks(selected: 2)
    }
    
    private func updateSensitivityChecks(selected: Int) {
        guard let submenu = statusItem.menu?.items.first(where: { $0.title == "Pointer Sensitivity" })?.submenu else { return }
        for (idx, item) in submenu.items.enumerated() {
            let baseTitle = item.title.replacingOccurrences(of: "✓ ", with: "")
            item.title = (idx == selected) ? "✓ \(baseTitle)" : baseTitle
        }
    }
    
    @objc private func openSystemPermissions() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func promptForAccessibility() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "AirTouch needs Accessibility permission to control mouse movement, clicks, and scrolling on macOS.\n\nPlease enable AirTouch in System Settings > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")
            
            if alert.runModal() == .alertFirstButtonReturn {
                self.openSystemPermissions()
            }
        }
    }
    
    @objc private func quitApp() {
        cameraManager.stopSession()
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - CameraManagerDelegate
    public func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        if let landmarks = handTracker.processFrame(sampleBuffer) {
            gestureEngine.process(landmarks: landmarks)
        } else {
            overlayController.update(gesture: .none, landmarks: HandLandmarks())
        }
    }
    
    // MARK: - GestureEngineDelegate
    public func gestureEngine(_ engine: GestureEngine, didDetectGesture gesture: AirGestureType, at point: CGPoint?, landmarks: HandLandmarks) {
        overlayController.update(gesture: gesture, landmarks: landmarks)
    }
}
