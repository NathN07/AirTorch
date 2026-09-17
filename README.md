# ✋ AirTouch: macOS Air Gesture Trackpad

AirTouch is a native macOS application that turns your Mac's camera into a virtual air trackpad. By leveraging Apple's native **Vision framework** on Apple Silicon's Neural Engine (ANE), AirTouch tracks hand landmarks with 60 FPS precision, zero external dependencies, and minimal battery overhead.

It features a **non-intrusive floating HUD overlay** (`ignoresMouseEvents = true`) so you can visually see your hand tracking and gestures in real time while your clicks and keystrokes pass directly through to whatever application you are working in..

---

## 🛑 Gesture Lockout & Smart Pause (Cross-Talk Prevention)

To prevent accidental inputs, cursor jumping, or rapid-fire misrecognitions:
1. **Transient Gesture Lockout**: Whenever ANY gesture is executed (swipe, browser back/forward, click), AirTouch **immediately freezes the cursor and locks out all other gestures** while the gesture is active on screen. Return strokes and hand repositioning will never accidentally trigger other gestures.
2. **✌️ Peace Sign Global Pause / Resume**: Flash a **Peace Sign ✌️** (Index + Middle extended in a V-shape, thumb and other fingers curled) for 0.3s to toggle AirTouch **PAUSED / RESUMED**.
   * When paused (`⏸️ Paused`), all cursor movements, clicks, and swipes are completely frozen so you can type, rest, or talk with your hands without any interference. Show ✌️ again to resume (`▶️ Resumed`)!
3. **Strict Pointer Isolation**: The cursor ONLY moves when strictly the index finger is extended in a clear pointing stance. If multiple fingers are visible or transitioning, cursor motion instantly halts.

---

## 🖐️ Complete Gesture Reference

### ⏸️ Pause & Control
* **Peace Sign ✌️ (Hold 0.3s)**: Toggle **Global Pause / Resume**.
* **Open Palm (5 Fingers Spread) ✋**: Quick **Clutch / Temporary Pause** while held.

### 📱 Apps, Spaces & Windows (3 or 4 Fingers)
Extend **3 or 4 fingers** together:
* **Flick Left in air ⏩**: Switch to **Next Fullscreen App / Space** (`Ctrl + →`)
* **Flick Right in air ⏪**: Switch to **Previous Fullscreen App / Space** (`Ctrl + ←`)
* **Flick Up in air 🎛️**: Open **Mission Control** (`Ctrl + ↑`)
* **Flick Down in air 🪟**: Open **App Exposé / Windows** (`Ctrl + ↓`)

### 🌐 Website Navigation (2 Fingers)
Extend **2 fingers** together (Index + Middle):
* **Flick Right in air ⬅️**: Browser **Back** (`Cmd + [`)
* **Flick Left in air ➡️**: Browser **Forward** (`Cmd + ]`)
* **Move Up / Down 📜**: Smooth **2-finger scrolling**

### 🖱️ Mouse Essentials (1 Finger / Pinch)
* **Index Finger Pointing 🎯**: Move cursor smoothly across screens.
* **Index + Thumb Pinch 👆**: Left Click / Tap.
* **Pinch & Hold while moving ✊**: Click & Drag.
* **Middle + Thumb Pinch 🖱️**: Right Click.

---

## 🚀 Quick Start

### 1. Launching AirTouch
```bash
cd /scratch/AirTouch
open AirTouch.app
```

*(If AirTouch is already running, quit it first via the menu bar icon or run `killall AirTouch` then `open AirTouch.app`).*

### 2. Sharing to Another Mac
If you transfer `AirTouch.app` to another Mac via AirDrop or zip, remove the macOS quarantine flag in terminal on the recipient Mac:
```bash
xattr -cr AirTouch.app
```
And grant Camera & Accessibility access in **System Settings > Privacy & Security**.

---

## ⚙️ Menu Bar Options

Click the **✋ AirTouch** icon in the macOS menu bar to:
- **✓ Tracking Enabled**: Quickly pause or resume hand tracking.
- **✓ Show Floating HUD**: Toggle the corner skeleton HUD display.
- **Pointer Sensitivity**: Switch between Low (0.8x), Normal (1.2x), and High (1.8x).
- **Check Permissions...**: Quick link to macOS Privacy & Security settings.
- **Quit AirTouch**: Cleanly shut down the camera session and exit.
