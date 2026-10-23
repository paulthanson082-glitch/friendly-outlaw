#!/bin/bash
# Deploy to Bengal Max Android Device
# Usage: ./scripts/deploy_to_bengal.sh [--build | --install | --logs | --clear]

set -e

# Load environment variables
if [ -f .env.local ]; then
    export $(cat .env.local | xargs)
else
    echo "❌ Error: .env.local not found"
    echo "   Run: cp .env.local.example .env.local"
    echo "   Then fill in your Bengal Max device credentials"
    exit 1
fi

# Device serial (fallback to connected device if not specified)
DEVICE=${DEVICE_SERIAL:-}
if [ -z "$DEVICE" ]; then
    DEVICE=$(adb devices | grep -v "List" | grep "device$" | head -1 | awk '{print $1}')
fi

if [ -z "$DEVICE" ]; then
    echo "❌ Error: No device found. Connect Bengal Max and try again."
    echo "   adb devices"
    exit 1
fi

echo "📱 Target Device: $DEVICE"

# Commands
case "${1:-install}" in
    build)
        echo "🔨 Building APK for Bengal Max..."
        cd mobile
        npm run build:android
        echo "✅ Build complete: mobile/build/outputs/apk/debug/app-debug.apk"
        ;;

    install)
        echo "📦 Installing app on Bengal Max..."
        if [ ! -f "mobile/build/outputs/apk/debug/app-debug.apk" ]; then
            echo "⚠️  APK not found. Building first..."
            npm run build:android
        fi
        adb -s "$DEVICE" install -r mobile/build/outputs/apk/debug/app-debug.apk
        echo "✅ Installation complete"
        ;;

    logs)
        echo "📋 Streaming logs from Bengal Max (Press Ctrl+C to stop)..."
        adb -s "$DEVICE" logcat -v threadtime | grep -E "WritersApp|Jules|Error" || true
        ;;

    clear)
        echo "🧹 Clearing app data..."
        adb -s "$DEVICE" shell pm clear "$APP_PACKAGE_NAME"
        echo "✅ App data cleared"
        ;;

    screenshot)
        echo "📸 Taking screenshot..."
        TIMESTAMP=$(date +%s)
        adb -s "$DEVICE" shell screencap -p /sdcard/screenshot_"$TIMESTAMP".png
        adb -s "$DEVICE" pull /sdcard/screenshot_"$TIMESTAMP".png ./screenshot_"$TIMESTAMP".png
        echo "✅ Screenshot saved: screenshot_$TIMESTAMP.png"
        ;;

    test)
        echo "🧪 Running tests on Bengal Max..."
        adb -s "$DEVICE" shell am instrument -w "$APP_PACKAGE_NAME.test/androidx.test.runner.AndroidJUnitRunner"
        ;;

    help|--help|-h)
        echo "Deploy to Bengal Max - Android PCD Commands"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  build       Build APK from source"
        echo "  install     Build and install APK (default)"
        echo "  logs        Stream device logs"
        echo "  clear       Clear app data"
        echo "  screenshot  Capture screenshot"
        echo "  test        Run app tests"
        echo "  help        Show this message"
        echo ""
        echo "Setup:"
        echo "  1. cp .env.local.example .env.local"
        echo "  2. Edit .env.local with your device info"
        echo "  3. Connect Bengal Max device"
        echo "  4. ./scripts/deploy_to_bengal.sh install"
        ;;

    *)
        echo "❌ Unknown command: $1"
        echo "   Try: $0 --help"
        exit 1
        ;;
esac
