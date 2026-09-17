#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="AirTouch"
APP_BUNDLE="${APP_NAME}.app"
CACHE_DIR=".cache"

echo "==> Preparing build environment..."
rm -rf "$APP_BUNDLE" "$CACHE_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "==> Compiling AirTouch Swift application..."
swiftc \
    -O \
    -module-cache-path "$CACHE_DIR" \
    -framework Foundation \
    -framework AppKit \
    -framework AVFoundation \
    -framework Vision \
    -framework CoreGraphics \
    -framework CoreMedia \
    -framework ApplicationServices \
    Sources/SystemEventManager.swift \
    Sources/HandTracker.swift \
    Sources/GestureEngine.swift \
    Sources/CameraManager.swift \
    Sources/OverlayWindowController.swift \
    Sources/AppDelegate.swift \
    Sources/main.swift \
    -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "==> Copying Info.plist..."
cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"

echo "==> Code signing application bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> SUCCESS: ${APP_BUNDLE} built successfully!"
