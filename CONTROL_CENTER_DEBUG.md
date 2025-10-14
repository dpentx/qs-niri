# Control Center Debugging Guide

## Problem
Control Center still not opening after fixes.

## Debug Logging Added

I've added comprehensive debug logging to trace the issue:

### In ControlCenterWindow.qml:
- ✅ Logs when component loads: `🎛️ [ControlCenter] Component loaded successfully`
- ✅ Logs when shouldShow changes: `🎛️ [ControlCenter] shouldShow changed to: true/false`
- ✅ Logs when visible changes: `🎛️ [ControlCenter] visible changed to: true/false`
- ✅ Logs when clicking outside to close

### In ControlCenterToggle.qml:
- ✅ Logs when component loads
- ✅ Logs when controlCenter reference is set/null
- ✅ Logs every click on the toggle button
- ✅ Logs the shouldShow toggle action

## How to Debug

### Option 1: Watch Terminal Output
1. Restart QuickShell in a terminal:
   ```bash
   pkill -x quickshell && quickshell
   ```

2. Look for these startup messages:
   ```
   🎛️ [ControlCenter] Component loaded successfully
   🔘 [Toggle] Component loaded, controlCenter: SET or NULL
   ```

3. Click the control center icon (󰒓) in your bar

4. You should see:
   ```
   🔘 [Toggle] Clicked! controlCenter: SET
   🔘 [Toggle] Toggling shouldShow from false to true
   🎛️ [ControlCenter] shouldShow changed to: true
   🎛️ [ControlCenter] visible changed to: true
   ```

### Option 2: Use the Debug Script
```bash
cd ~/.config/quickshell
./debug-control-center.sh
```

This will restart QuickShell and watch for Control Center logs.

## What the Logs Tell Us

### If you see "controlCenter: NULL":
**Problem**: The toggle button isn't receiving the Control Center reference.
**Fix**: Issue in BarWrapper.qml binding.

### If you see "controlCenter: SET" but no shouldShow change:
**Problem**: The property binding isn't working.
**Fix**: Issue with property propagation.

### If shouldShow changes but visible doesn't:
**Problem**: The visibility condition isn't working.
**Fix**: Check the `visible: shouldShow || dashboardContainer.opacity > 0` logic.

### If everything logs correctly but panel doesn't show:
**Problem**: The panel might be rendering off-screen or behind other windows.
**Fix**: Check PanelWindow layer/positioning.

## Quick Test Commands

```bash
# Restart QuickShell in terminal
pkill -x quickshell && quickshell

# Or if running via systemd
systemctl --user restart quickshell

# Watch logs in real-time
journalctl --user -u quickshell -f | grep -E "Control|Toggle|🎛️|🔘"
```

## Expected Flow

1. **Startup**: 
   - Control Center PanelWindow loads
   - Toggle button loads and gets reference
   
2. **Click Toggle**:
   - Toggle detects click
   - Sets shouldShow = true on Control Center
   - Control Center visibility changes to true
   - Dashboard container animates in (scale + opacity)
   
3. **Click Outside**:
   - MouseArea detects click
   - Sets shouldShow = false
   - Dashboard container animates out
   - After animation, visible becomes false

## Fixes Applied So Far

1. ✅ Fixed duplicate content corruption (happened twice)
2. ✅ Changed `width`/`height` to `implicitWidth`/`implicitHeight`
3. ✅ Fixed visibility logic: `visible: shouldShow || dashboardContainer.opacity > 0`
4. ✅ Added comprehensive debug logging
5. ✅ Verified no syntax errors

## Next Steps

Run QuickShell with debug output and share what you see in the terminal when you click the control center icon. This will tell us exactly where the issue is!
