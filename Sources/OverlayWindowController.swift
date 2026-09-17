import Foundation
import AppKit
import CoreGraphics

public final class OverlayHUDView: NSView {
    public var currentGesture: AirGestureType = .none {
        didSet {
            needsDisplay = true
        }
    }
    
    public var handLandmarks: HandLandmarks? {
        didSet {
            needsDisplay = true
        }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw HUD Card background (Glassmorphic dark rounded rectangle)
        let cardRect = bounds.insetBy(dx: 6, dy: 6)
        let path = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)
        
        context.saveGState()
        NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 0.82).setFill()
        path.fill()
        
        // Border
        NSColor(calibratedWhite: 1.0, alpha: 0.18).setStroke()
        path.lineWidth = 1.2
        path.stroke()
        context.restoreGState()
        
        // Title Header
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor(calibratedWhite: 0.7, alpha: 1.0)
        ]
        let title = "AIRTOUCH HUD" as NSString
        title.draw(at: NSPoint(x: cardRect.minX + 14, y: cardRect.maxY - 24), withAttributes: titleAttributes)
        
        // Status indicator dot
        let dotColor: NSColor
        switch currentGesture {
        case .pointer: dotColor = .systemCyan
        case .click: dotColor = .systemGreen
        case .dragging: dotColor = .systemYellow
        case .rightClick: dotColor = .systemPurple
        case .scrolling: dotColor = .systemBlue
        case .paused, .togglePaused: dotColor = .systemOrange
        case .resumed: dotColor = .systemGreen
        case .swipeNextApp, .swipePrevApp: dotColor = .systemIndigo
        case .switchWindow, .missionControl: dotColor = .systemTeal
        case .browserBack, .browserForward: dotColor = .systemMint
        case .none: dotColor = .systemGray
        }
        
        let dotRect = NSRect(x: cardRect.maxX - 24, y: cardRect.maxY - 22, width: 8, height: 8)
        dotColor.setFill()
        NSBezierPath(ovalIn: dotRect).fill()
        
        // Draw Skeletal Hand
        let previewRect = NSRect(
            x: cardRect.minX + 16,
            y: cardRect.minY + 38,
            width: cardRect.width - 32,
            height: cardRect.height - 70
        )
        
        if let landmarks = handLandmarks, landmarks.wrist != nil {
            drawHandSkeleton(landmarks: landmarks, in: previewRect, context: context)
        } else {
            // Draw placeholder text when hand not detected
            let hint = "Wave hand facing camera" as NSString
            let hintAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor(calibratedWhite: 0.5, alpha: 0.8)
            ]
            let hintSize = hint.size(withAttributes: hintAttrs)
            hint.draw(
                at: NSPoint(x: previewRect.midX - hintSize.width / 2, y: previewRect.midY - hintSize.height / 2),
                withAttributes: hintAttrs
            )
        }
        
        // Draw Gesture Badge Pill
        drawGestureBadge(gesture: currentGesture, in: cardRect, context: context)
    }
    
    private func drawGestureBadge(gesture: AirGestureType, in cardRect: NSRect, context: CGContext) {
        let badgeRect = NSRect(x: cardRect.minX + 12, y: cardRect.minY + 8, width: cardRect.width - 24, height: 24)
        let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 12, yRadius: 12)
        
        let badgeBgColor: NSColor
        let textColor: NSColor
        switch gesture {
        case .pointer:
            badgeBgColor = NSColor.systemCyan.withAlphaComponent(0.25)
            textColor = .systemCyan
        case .click:
            badgeBgColor = NSColor.systemGreen.withAlphaComponent(0.28)
            textColor = .systemGreen
        case .dragging:
            badgeBgColor = NSColor.systemYellow.withAlphaComponent(0.25)
            textColor = .systemYellow
        case .rightClick:
            badgeBgColor = NSColor.systemPurple.withAlphaComponent(0.28)
            textColor = .systemPurple
        case .scrolling:
            badgeBgColor = NSColor.systemBlue.withAlphaComponent(0.25)
            textColor = .systemBlue
        case .paused, .togglePaused:
            badgeBgColor = NSColor.systemOrange.withAlphaComponent(0.28)
            textColor = .systemOrange
        case .resumed:
            badgeBgColor = NSColor.systemGreen.withAlphaComponent(0.28)
            textColor = .systemGreen
        case .swipeNextApp, .swipePrevApp:
            badgeBgColor = NSColor.systemIndigo.withAlphaComponent(0.32)
            textColor = .systemIndigo
        case .switchWindow, .missionControl:
            badgeBgColor = NSColor.systemTeal.withAlphaComponent(0.32)
            textColor = .systemTeal
        case .browserBack, .browserForward:
            badgeBgColor = NSColor.systemMint.withAlphaComponent(0.32)
            textColor = .systemMint
        case .none:
            badgeBgColor = NSColor.systemGray.withAlphaComponent(0.18)
            textColor = NSColor(calibratedWhite: 0.6, alpha: 1.0)
        }
        
        badgeBgColor.setFill()
        badgePath.fill()
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: textColor
        ]
        let label = gesture.rawValue as NSString
        let labelSize = label.size(withAttributes: labelAttrs)
        label.draw(
            at: NSPoint(x: badgeRect.midX - labelSize.width / 2, y: badgeRect.midY - labelSize.height / 2 + 1),
            withAttributes: labelAttrs
        )
    }
    
    private func drawHandSkeleton(landmarks: HandLandmarks, in rect: NSRect, context: CGContext) {
        func toPoint(_ joint: HandJoint?) -> CGPoint? {
            guard let pt = joint?.point else { return nil }
            let px = rect.minX + (1.0 - pt.x) * rect.width
            let py = rect.minY + pt.y * rect.height
            return CGPoint(x: px, y: py)
        }
        
        let wrist = toPoint(landmarks.wrist)
        let thumbCMC = toPoint(landmarks.thumbCMC)
        let thumbMP = toPoint(landmarks.thumbMP)
        let thumbIP = toPoint(landmarks.thumbIP)
        let thumbTip = toPoint(landmarks.thumbTip)
        
        let indexMCP = toPoint(landmarks.indexMCP)
        let indexPIP = toPoint(landmarks.indexPIP)
        let indexDIP = toPoint(landmarks.indexDIP)
        let indexTip = toPoint(landmarks.indexTip)
        
        let middleMCP = toPoint(landmarks.middleMCP)
        let middlePIP = toPoint(landmarks.middlePIP)
        let middleDIP = toPoint(landmarks.middleDIP)
        let middleTip = toPoint(landmarks.middleTip)
        
        let ringMCP = toPoint(landmarks.ringMCP)
        let ringPIP = toPoint(landmarks.ringPIP)
        let ringDIP = toPoint(landmarks.ringDIP)
        let ringTip = toPoint(landmarks.ringTip)
        
        let littleMCP = toPoint(landmarks.littleMCP)
        let littlePIP = toPoint(landmarks.littlePIP)
        let littleDIP = toPoint(landmarks.littleDIP)
        let littleTip = toPoint(landmarks.littleTip)
        
        let fingerChains: [[CGPoint?]] = [
            [wrist, thumbCMC, thumbMP, thumbIP, thumbTip],
            [wrist, indexMCP, indexPIP, indexDIP, indexTip],
            [wrist, middleMCP, middlePIP, middleDIP, middleTip],
            [wrist, ringMCP, ringPIP, ringDIP, ringTip],
            [wrist, littleMCP, littlePIP, littleDIP, littleTip],
            [thumbCMC, indexMCP, middleMCP, ringMCP, littleMCP]
        ]
        
        context.saveGState()
        context.setLineWidth(2.0)
        context.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.45).cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for chain in fingerChains {
            let validPoints = chain.compactMap { $0 }
            guard validPoints.count > 1 else { continue }
            context.beginPath()
            context.move(to: validPoints[0])
            for i in 1..<validPoints.count {
                context.addLine(to: validPoints[i])
            }
            context.strokePath()
        }
        
        let allJoints: [(CGPoint?, NSColor, CGFloat)] = [
            (thumbTip, .systemOrange, 4.0),
            (indexTip, .systemCyan, 5.0),
            (middleTip, .systemTeal, 4.0),
            (ringTip, .systemPink, 3.5),
            (littleTip, .systemPurple, 3.5),
            (wrist, .white, 4.0),
            (indexPIP, .white, 2.5),
            (middlePIP, .white, 2.5),
            (ringPIP, .white, 2.5),
            (littlePIP, .white, 2.5)
        ]
        
        for (jointPt, color, radius) in allJoints {
            guard let pt = jointPt else { continue }
            let dotRect = CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2)
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: dotRect)
        }
        
        context.restoreGState()
    }
}

public final class OverlayWindowController: NSObject {
    private var window: NSWindow?
    private var hudView: OverlayHUDView?
    
    public var isVisible: Bool = true {
        didSet {
            if isVisible {
                window?.orderFront(nil)
            } else {
                window?.orderOut(nil)
            }
        }
    }
    
    public override init() {
        super.init()
        setupWindow()
    }
    
    private func setupWindow() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 250
        let height: CGFloat = 190
        let padding: CGFloat = 20
        
        let windowRect = NSRect(
            x: screenRect.maxX - width - padding,
            y: screenRect.minY + padding,
            width: width,
            height: height
        )
        
        let win = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        win.hasShadow = true
        
        let view = OverlayHUDView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        win.contentView = view
        
        self.window = win
        self.hudView = view
        
        win.orderFront(nil)
    }
    
    public func update(gesture: AirGestureType, landmarks: HandLandmarks) {
        DispatchQueue.main.async { [weak self] in
            self?.hudView?.currentGesture = gesture
            self?.hudView?.handLandmarks = landmarks
        }
    }
}
