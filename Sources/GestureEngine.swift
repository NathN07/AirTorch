import Foundation
import CoreGraphics
import AppKit

public enum AirGestureType: String {
    case none = "Searching..."
    case paused = "⏸️ Paused (Clutch)"
    case togglePaused = "⏸️ Paused (Show ✌️ to Resume)"
    case resumed = "▶️ AirTouch Resumed"
    case pointer = "🎯 Pointer Hover"
    case click = "👆 Left Click"
    case dragging = "✊ Dragging"
    case rightClick = "🖱️ Right Click"
    case scrolling = "📜 Scrolling"
    case switchWindow = "🪟 Switch Window (Cmd+`)"
    case missionControl = "🎛️ Mission Control"
    case swipeNextApp = "⏩ Next App / Space"
    case swipePrevApp = "⏪ Prev App / Space"
    case browserBack = "⬅️ Browser Back"
    case browserForward = "➡️ Browser Forward"
}

public protocol GestureEngineDelegate: AnyObject {
    func gestureEngine(_ engine: GestureEngine, didDetectGesture gesture: AirGestureType, at point: CGPoint?, landmarks: HandLandmarks)
}

public final class GestureEngine {
    public weak var delegate: GestureEngineDelegate?
    
    public var isEnabled: Bool = true
    public var isGloballyPaused: Bool = false
    public var sensitivity: CGFloat = 1.2
    
    // Lockout & Settling
    private var gestureLockoutUntil: Date = Date.distantPast
    private var activeDisplayedGesture: AirGestureType?
    
    // Peace sign (✌️) toggle state
    private var peaceSignStartTime: Date?
    private var lastPeaceToggleTime: Date = Date.distantPast
    
    // Smoothing & state
    private var smoothedScreenPoint: CGPoint?
    
    // Pinch click & drag state
    private var pinchAnchorPoint: CGPoint?
    private var pinchStartTime: Date?
    private var isPinchDragging: Bool = false
    
    // Right click state
    private var isRightPinching: Bool = false
    
    // Scrolling state
    private var lastScrollNormY: CGFloat?
    
    // 3-Finger Swipe State (Windows / Spaces / Mission Control)
    private var threeFingerAnchor: CGPoint?
    private var threeFingerAnchorTime: Date?
    private var lastThreeFingerSwipeTime: Date = Date.distantPast
    
    // 2-Finger Horizontal Flick State (Browser Back / Forward)
    private var twoFingerAnchor: CGPoint?
    private var twoFingerAnchorTime: Date?
    private var lastTwoFingerSwipeTime: Date = Date.distantPast
    
    // Active area margins
    private let marginX: CGFloat = 0.12
    private let marginY: CGFloat = 0.12
    
    public init() {}
    
    public func process(landmarks: HandLandmarks) {
        guard isEnabled else { return }
        
        guard let wrist = landmarks.wrist?.point,
              let indexTip = landmarks.indexTip?.point,
              let thumbTip = landmarks.thumbTip?.point else {
            resetAnchors()
            notify(gesture: isGloballyPaused ? .togglePaused : .none, at: nil, landmarks: landmarks)
            return
        }
        
        let indexPIP = landmarks.indexPIP?.point ?? wrist
        let middleTip = landmarks.middleTip?.point
        let middlePIP = landmarks.middlePIP?.point ?? wrist
        let ringTip = landmarks.ringTip?.point
        let ringPIP = landmarks.ringPIP?.point ?? wrist
        let littleTip = landmarks.littleTip?.point
        let littlePIP = landmarks.littlePIP?.point ?? wrist
        
        let handScale = max(0.12, dist(wrist, landmarks.middleMCP?.point ?? indexPIP))
        
        let isIndexExt = dist(indexTip, wrist) > dist(indexPIP, wrist) * 1.10 && dist(indexTip, wrist) > 0.13
        let isMiddleExt = middleTip != nil && dist(middleTip!, wrist) > dist(middlePIP, wrist) * 1.10 && dist(middleTip!, wrist) > 0.13
        let isRingExt = ringTip != nil && dist(ringTip!, wrist) > dist(ringPIP, wrist) * 1.10 && dist(ringTip!, wrist) > 0.12
        let isLittleExt = littleTip != nil && dist(littleTip!, wrist) > dist(littlePIP, wrist) * 1.10 && dist(littleTip!, wrist) > 0.10
        let isThumbExt = dist(thumbTip, wrist) > 0.14
        
        let now = Date()
        
        // 1. Peace Sign (✌️) to Toggle Global Pause / Resume
        if isIndexExt && isMiddleExt && !isRingExt && !isLittleExt,
           let middleTip = middleTip, dist(indexTip, middleTip) > 0.055 {
            
            if now.timeIntervalSince(lastPeaceToggleTime) > 1.2 {
                if let start = peaceSignStartTime {
                    if now.timeIntervalSince(start) > 0.30 {
                        isGloballyPaused.toggle()
                        lastPeaceToggleTime = now
                        peaceSignStartTime = nil
                        let toggleGesture: AirGestureType = isGloballyPaused ? .togglePaused : .resumed
                        lockout(for: 0.85, gesture: toggleGesture)
                        notify(gesture: toggleGesture, at: smoothedScreenPoint, landmarks: landmarks)
                        return
                    }
                } else {
                    peaceSignStartTime = now
                }
            }
        } else {
            peaceSignStartTime = nil
        }
        
        // 2. If globally paused, freeze all actions
        if isGloballyPaused {
            releasePinchIfNeeded()
            resetAnchors()
            notify(gesture: .togglePaused, at: smoothedScreenPoint, landmarks: landmarks)
            return
        }
        
        // 3. Temporary Pause / Clutch: Open 5-Finger Palm (✋ Stop Sign)
        if isIndexExt && isMiddleExt && isRingExt && isLittleExt && isThumbExt {
            releasePinchIfNeeded()
            resetAnchors()
            lastScrollNormY = nil
            notify(gesture: .paused, at: smoothedScreenPoint, landmarks: landmarks)
            return
        }
        
        // 4. Gesture Lockout Window
        if now < gestureLockoutUntil {
            releasePinchIfNeeded()
            resetAnchors()
            notify(gesture: activeDisplayedGesture ?? .none, at: smoothedScreenPoint, landmarks: landmarks)
            return
        }
        
        // 5. 3- or 4-Finger Gestures (Switch Window / Mission Control / Spaces)
        let extendedFingerCount = (isIndexExt ? 1 : 0) + (isMiddleExt ? 1 : 0) + (isRingExt ? 1 : 0) + (isLittleExt ? 1 : 0)
        if extendedFingerCount >= 3 && middleTip != nil {
            releasePinchIfNeeded()
            twoFingerAnchor = nil
            lastScrollNormY = nil
            
            let refRingX = ringTip?.x ?? middleTip!.x
            let refRingY = ringTip?.y ?? middleTip!.y
            let centroidNormX = (indexTip.x + middleTip!.x + refRingX) / 3.0
            let centroidNormY = (indexTip.y + middleTip!.y + refRingY) / 3.0
            let mirroredX = 1.0 - centroidNormX
            let currentCentroid = CGPoint(x: mirroredX, y: centroidNormY)
            
            if now.timeIntervalSince(lastThreeFingerSwipeTime) > 0.40 {
                if let anchor = threeFingerAnchor, let anchorTime = threeFingerAnchorTime {
                    let elapsed = now.timeIntervalSince(anchorTime)
                    let deltaX = currentCentroid.x - anchor.x
                    let deltaY = currentCentroid.y - anchor.y
                    
                    if elapsed <= 0.45 {
                        // Vertical Flicks
                        if abs(deltaY) > 0.045 && abs(deltaY) > abs(deltaX) * 0.85 {
                            if deltaY > 0 {
                                SystemEventManager.shared.missionControl()
                                lockout(for: 0.65, gesture: .missionControl)
                            } else {
                                SystemEventManager.shared.cycleAppWindows()
                                lockout(for: 0.65, gesture: .switchWindow)
                            }
                            lastThreeFingerSwipeTime = now
                            threeFingerAnchor = nil
                            notify(gesture: activeDisplayedGesture ?? .switchWindow, at: smoothedScreenPoint, landmarks: landmarks)
                            return
                        }
                        // Horizontal Flicks
                        else if abs(deltaX) > 0.045 && abs(deltaX) > abs(deltaY) * 0.85 {
                            if deltaX > 0 {
                                SystemEventManager.shared.prevSpace()
                                lockout(for: 0.65, gesture: .swipePrevApp)
                            } else {
                                SystemEventManager.shared.nextSpace()
                                lockout(for: 0.65, gesture: .swipeNextApp)
                            }
                            lastThreeFingerSwipeTime = now
                            threeFingerAnchor = nil
                            notify(gesture: activeDisplayedGesture ?? .swipeNextApp, at: smoothedScreenPoint, landmarks: landmarks)
                            return
                        }
                    } else {
                        threeFingerAnchor = currentCentroid
                        threeFingerAnchorTime = now
                    }
                } else {
                    threeFingerAnchor = currentCentroid
                    threeFingerAnchorTime = now
                }
            }
            
            notify(gesture: .none, at: smoothedScreenPoint, landmarks: landmarks)
            return
        } else {
            threeFingerAnchor = nil
        }
        
        // 6. 2-Finger Gestures (Scroll & Browser Back/Forward)
        if isIndexExt && isMiddleExt && !isRingExt && !isLittleExt,
           let middleTip = middleTip, dist(indexTip, middleTip) <= 0.080 {
            
            releasePinchIfNeeded()
            let avgNormX = (indexTip.x + middleTip.x) / 2.0
            let avgMirroredX = 1.0 - avgNormX
            let avgNormY = (indexTip.y + middleTip.y) / 2.0
            let currentPt = CGPoint(x: avgMirroredX, y: avgNormY)
            
            // Horizontal Browser Flick
            if now.timeIntervalSince(lastTwoFingerSwipeTime) > 0.50 {
                if let anchor = twoFingerAnchor, let anchorTime = twoFingerAnchorTime {
                    let elapsed = now.timeIntervalSince(anchorTime)
                    let deltaX = currentPt.x - anchor.x
                    let deltaY = currentPt.y - anchor.y
                    
                    if elapsed <= 0.35 && abs(deltaX) > 0.050 && abs(deltaX) > abs(deltaY) * 1.2 {
                        if deltaX > 0 {
                            SystemEventManager.shared.browserBack()
                            lockout(for: 0.60, gesture: .browserBack)
                        } else {
                            SystemEventManager.shared.browserForward()
                            lockout(for: 0.60, gesture: .browserForward)
                        }
                        lastTwoFingerSwipeTime = now
                        twoFingerAnchor = nil
                        lastScrollNormY = nil
                        notify(gesture: activeDisplayedGesture ?? .browserBack, at: smoothedScreenPoint, landmarks: landmarks)
                        return
                    } else if elapsed > 0.35 {
                        twoFingerAnchor = currentPt
                        twoFingerAnchorTime = now
                    }
                } else {
                    twoFingerAnchor = currentPt
                    twoFingerAnchorTime = now
                }
            }
            
            // Vertical Scroll
            if let lastY = lastScrollNormY {
                let deltaNormY = avgNormY - lastY
                if abs(deltaNormY) > 0.0025 {
                    let scrollAmount = Int32(deltaNormY * 700.0 * sensitivity)
                    SystemEventManager.shared.scroll(deltaY: scrollAmount)
                }
            }
            lastScrollNormY = avgNormY
            notify(gesture: .scrolling, at: smoothedScreenPoint, landmarks: landmarks)
            return
        } else {
            twoFingerAnchor = nil
            lastScrollNormY = nil
        }
        
        // 7. Compute screen coordinates from index fingertip
        let screenPoint = mapToScreen(normPoint: indexTip)
        let smoothedPoint = smooth(newPoint: screenPoint)
        smoothedScreenPoint = smoothedPoint
        
        // Dynamic pinch thresholds
        let effectivePinchDown = max(0.082, handScale * 0.46)
        let effectivePinchUp   = max(0.108, handScale * 0.60)
        let effectiveRightPinch = max(0.084, handScale * 0.48)
        
        // 8. Right-Click Touch (Middle + Thumb Pinch)
        if let middleTip = middleTip {
            let rightDist = dist(middleTip, thumbTip)
            if rightDist < effectiveRightPinch && pinchStartTime == nil {
                if !isRightPinching {
                    isRightPinching = true
                    SystemEventManager.shared.rightClick(at: smoothedPoint)
                    lockout(for: 0.40, gesture: .rightClick)
                    notify(gesture: .rightClick, at: smoothedPoint, landmarks: landmarks)
                    return
                }
            } else if rightDist > effectiveRightPinch + 0.03 {
                isRightPinching = false
            }
        }
        
        // 9. Left-Click & Drag (Index + Thumb Pinch)
        let pinchDistance = dist(indexTip, thumbTip)
        
        // Pinch Active: fingers touching
        if pinchDistance < effectivePinchDown {
            if pinchStartTime == nil {
                pinchStartTime = now
                pinchAnchorPoint = smoothedPoint
                notify(gesture: .click, at: smoothedPoint, landmarks: landmarks)
                return
            } else {
                let elapsed = now.timeIntervalSince(pinchStartTime!)
                let anchor = pinchAnchorPoint ?? smoothedPoint
                let moveDist = hypot(smoothedPoint.x - anchor.x, smoothedPoint.y - anchor.y)
                
                // If user deliberately drags hand while pinched -> Drag mode!
                if moveDist > 25.0 && elapsed > 0.20 {
                    if !isPinchDragging {
                        isPinchDragging = true
                        SystemEventManager.shared.leftDown(at: anchor)
                    }
                    SystemEventManager.shared.leftDrag(to: smoothedPoint)
                    notify(gesture: .dragging, at: smoothedPoint, landmarks: landmarks)
                    return
                } else {
                    // Hold pointer steady on target button while pinched
                    notify(gesture: .click, at: anchor, landmarks: landmarks)
                    return
                }
            }
        }
        // Pinch Released: fingers opened
        else if pinchDistance > effectivePinchUp && pinchStartTime != nil {
            let anchor = pinchAnchorPoint ?? smoothedPoint
            pinchStartTime = nil
            pinchAnchorPoint = nil
            
            if isPinchDragging {
                isPinchDragging = false
                SystemEventManager.shared.leftUp(at: smoothedPoint)
                lockout(for: 0.15, gesture: .pointer)
                notify(gesture: .pointer, at: smoothedPoint, landmarks: landmarks)
                return
            } else {
                // INSTANT GUARANTEED NATIVE CLICK AT ANCHOR!
                SystemEventManager.shared.leftClick(at: anchor)
                lockout(for: 0.25, gesture: .click)
                notify(gesture: .click, at: anchor, landmarks: landmarks)
                return
            }
        }
        
        // 10. Pointer Movement:
        if isIndexExt && !isRingExt && !isLittleExt {
            SystemEventManager.shared.moveMouse(to: smoothedPoint)
            notify(gesture: .pointer, at: smoothedPoint, landmarks: landmarks)
        } else {
            notify(gesture: .none, at: smoothedPoint, landmarks: landmarks)
        }
    }
    
    private func lockout(for duration: TimeInterval, gesture: AirGestureType) {
        activeDisplayedGesture = gesture
        gestureLockoutUntil = Date().addingTimeInterval(duration)
        resetAnchors()
    }
    
    private func notify(gesture: AirGestureType, at point: CGPoint?, landmarks: HandLandmarks) {
        delegate?.gestureEngine(self, didDetectGesture: gesture, at: point, landmarks: landmarks)
    }
    
    private func releasePinchIfNeeded() {
        if isPinchDragging {
            isPinchDragging = false
            if let pt = smoothedScreenPoint {
                SystemEventManager.shared.leftUp(at: pt)
            }
        }
        pinchStartTime = nil
        pinchAnchorPoint = nil
    }
    
    private func resetAnchors() {
        threeFingerAnchor = nil
        twoFingerAnchor = nil
    }
    
    private func mapToScreen(normPoint: CGPoint) -> CGPoint {
        let screenRect = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        
        let mirroredX = 1.0 - normPoint.x
        let clampedX = max(marginX, min(1.0 - marginX, mirroredX))
        let clampedY = max(marginY, min(1.0 - marginY, normPoint.y))
        
        let relX = (clampedX - marginX) / (1.0 - 2.0 * marginX)
        let relY = (clampedY - marginY) / (1.0 - 2.0 * marginY)
        
        let screenX = screenRect.origin.x + relX * screenRect.width
        let screenY = screenRect.origin.y + (1.0 - relY) * screenRect.height
        
        return CGPoint(x: screenX, y: screenY)
    }
    
    private func smooth(newPoint: CGPoint) -> CGPoint {
        guard let prev = smoothedScreenPoint else {
            return newPoint
        }
        
        let delta = hypot(newPoint.x - prev.x, newPoint.y - prev.y)
        let alpha: CGFloat
        if delta < 3.0 {
            alpha = 0.20
        } else if delta > 40.0 {
            alpha = 0.85
        } else {
            let t = (delta - 3.0) / (40.0 - 3.0)
            alpha = 0.20 + t * (0.85 - 0.20)
        }
        
        let smoothX = prev.x * (1.0 - alpha) + newPoint.x * alpha
        let smoothY = prev.y * (1.0 - alpha) + newPoint.y * alpha
        return CGPoint(x: smoothX, y: smoothY)
    }
    
    private func dist(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }
}
