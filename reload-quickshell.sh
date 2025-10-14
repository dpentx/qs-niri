#!/bin/bash
# Quick reload script for QuickShell

echo "🔄 Reloading QuickShell..."

# Kill existing instance
pkill -9 quickshell
sleep 1

# Start new instance
quickshell &
NEW_PID=$!

sleep 2

if pgrep -x quickshell > /dev/null; then
    echo "✅ QuickShell reloaded successfully (PID: $NEW_PID)"
    echo ""
    echo "📋 To see the changes:"
    echo "  1. Click the Control Center icon in your bar (top-right)"
    echo "  2. Check Performance tab - should be much more compact (3 columns)"
    echo "  3. Check Settings tab - Bluetooth device name should be beside icon"
    echo "  4. Check Notifications tab - closed notifications should persist"
    echo "  5. Check Settings tab - Volume should show percentage without NaN"
else
    echo "❌ Failed to start QuickShell"
    echo "Try running: quickshell"
fi
