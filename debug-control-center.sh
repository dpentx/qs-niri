#!/usr/bin/env bash
# Control Center Debug Test

echo "🔍 Control Center Debug Test"
echo "=============================="
echo ""
echo "This will restart QuickShell with debug logging enabled."
echo "Watch for these messages:"
echo ""
echo "  🎛️ [ControlCenter] Component loaded successfully"
echo "  🔘 [Toggle] Component loaded"
echo "  🔘 [Toggle] controlCenter reference: SET or NULL"
echo ""
echo "When you click the control center icon, watch for:"
echo "  🔘 [Toggle] Clicked!"
echo "  🔘 [Toggle] Toggling shouldShow from..."
echo "  🎛️ [ControlCenter] shouldShow changed to: true"
echo "  🎛️ [ControlCenter] visible changed to: true"
echo ""
echo "Press Ctrl+C to stop watching logs"
echo ""
echo "Restarting QuickShell..."
echo ""

# Kill existing QuickShell
pkill -x quickshell

# Wait a moment
sleep 1

# Start QuickShell and tail logs
quickshell &
QUICKSHELL_PID=$!

# Give it time to start
sleep 2

echo ""
echo "✅ QuickShell started (PID: $QUICKSHELL_PID)"
echo ""
echo "📋 Now watching QuickShell debug logs..."
echo "   Click the control center icon (󰒓) in your bar"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Follow journalctl logs
journalctl --user -f --since "now" | grep --line-buffered -E "Control|Toggle|🎛️|🔘"
