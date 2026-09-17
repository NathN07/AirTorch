# ✋ AirTouch: macOS Air Gesture Trackpad  

AirTouch is a native macOS application that turns your Mac's camera into a virtual air trackpad. By leveraging Apple's native **Vision framework** on Apple Silicon's Neural Engine (ANE), AirTouch tracks hand landmarks with 60 FPS precision, zero external dependencies, and minimal battery overhead.

It features a **non‑intrusive floating HUD overlay** (`ignoresMouseEvents = true`) so you can visually see your hand tracking and gestures in real time while your clicks and keystrokes pass directly through to whatever application you are working in.

---

## 🛑 Gesture Lockout & Smart Pause (Cross‑Talk Prevention)

To prevent accidental inputs, cursor jumping, or rapid‑fire misrecognitions:

1. **Transient Gesture Lockout** – Whenever **any** gesture is executed (swipe, browser back/forward, click), AirTouch **immediately freezes the cursor and locks out all other gestures** while the gesture is active on screen. Return strokes and hand repositioning will never accidentally trigger other gestures.  
2. **✌️ Peace Sign Global Pause / Resume** – Flash a **Peace Sign ✌️** (Index + Middle extended in a V‑shape, thumb and other fingers curled) for ~0.3 s to toggle AirTouch **PAUSED / RESUMED**.  
   *When paused (`⏸️ Paused`), all cursor movements, clicks, and swipes are completely frozen so you can type, rest, or talk with your hands without any interference. Show ✌️ again to resume (`▶️ Resumed`).*  
3. **Strict Pointer Isolation** – The cursor **only moves** when strictly the index finger is extended in a clear pointing stance. If multiple fingers are visible or transitioning, cursor motion instantly halts.

---

## 🖐️ Complete Gesture Reference  

### ⏸️ Pause & Control  

| Gesture | Action |
|---------|--------|
| **Peace Sign ✌️ (hold 0.3 s)** | Toggle **Global Pause / Resume** |
| **Open Palm (5 fingers spread) ✋** | **Clutch / Temporary Pause** while held |

### 📱 Apps, Spaces & Windows (3 or 4 fingers)  

| Gesture | macOS Shortcut |
|---------|----------------|
| **Flick Left** | `Ctrl + →` (next full‑screen app / space) |
| **Flick Right** | `Ctrl + ←` (previous full‑screen app / space) |
| **Flick Up** | `Ctrl + ↑` (Mission Control) |
| **Flick Down** | `Ctrl + ↓` (App Exposé / windows) |

### 🌐 Website Navigation (2 fingers)  

| Gesture | macOS Shortcut |
|---------|----------------|
| **Flick Right** | `⌘ + [` (Browser Back) |
| **Flick Left** | `⌘ + ]` (Browser Forward) |
| **Move Up / Down** | Smooth vertical scrolling |

### 🖱️ Mouse Essentials (1 finger / pinch)  

| Gesture | Action |
|---------|--------|
| **Index Finger Pointing** | Move cursor smoothly |
| **Index + Thumb Pinch** | Left click / tap |
| **Pinch & Hold while moving** | Click & drag |
| **Middle + Thumb Pinch** | Right click |

---

## 🚀 Quick‑Start (Zero‑Setup)  

If you just want to try AirTouch **right now**, **no building, no terminal, no extra tools** are required.

1. **Download the latest pre‑built release** – go to the **Releases** page and download `AirTouch‑vX.Y.Z.zip` (replace `X.Y.Z` with the current version):  
   <https://github.com/your-username/AirTouch/releases/latest>  

2. **Unzip** the file – you’ll get an `AirTouch.app` bundle.

3. **Launch the app** – double‑click `AirTouch.app`.

4. **Grant Accessibility permission** (macOS asks automatically):  

   * macOS will show: “AirTouch would like to control this computer using accessibility features.”  
   * Click **Open System Settings → Privacy & Security → Accessibility**, press **+**, locate the extracted `AirTouch.app`, and tick its checkbox.  

5. The translucent HUD appears in the top‑right corner; start gesturing!  

That’s all – you’re ready to control your Mac with your hands. 🎉  

> **Note:** The permission only needs to be granted once per binary. If you later rebuild the app, repeat step 4.

---

## 📦 Other Installation Options  

| Method | One‑liner | Who it’s for |
|--------|-----------|--------------|
| **Homebrew (cask)** | `brew install --cask airtouch` | Users who already use Homebrew and want a one‑command install. |
| **Clone & Build** | See **Development** section below | Developers who want to modify the source or run the latest unreleased code. |

All three options produce the same signed `AirTouch.app`; the only difference is how you obtain it.

---

## 🛠️ Development (Build from source)

```bash
# 1️⃣ Clone the repo
git clone https://github.com/your-username/AirTouch.git
cd AirTouch

# 2️⃣ Install Xcode command‑line tools (once)
xcode-select --install

# 3️⃣ Build the app
chmod +x build.sh          # only needed the first time
./build.sh                 # produces AirTouch.app in the repo root
