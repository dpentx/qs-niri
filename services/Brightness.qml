pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property real brightness: 0.5
    property real maxBrightness: 1.0
    
    // Alias for easier access
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)
    
    property string _backlightDevice: ""
    readonly property string backlightPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/brightness` : ""
    readonly property string maxBrightnessPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/max_brightness` : ""
    
    property int currentValue: 0
    property int maxValue: 255
    
    Component.onCompleted: {
        detectBacklightDevice()
        readMaxBrightness()
        readBrightness()
        updateTimer.start()
    }

    function detectBacklightDevice() {
        detectProc.running = true
    }
    
    function readMaxBrightness() {
        if (maxBrightnessPath === "") return
        maxBrightnessProcess.command = ["cat", maxBrightnessPath]
        maxBrightnessProcess.running = true
    }

    function readBrightness() {
        if (backlightPath === "") return
        brightnessProcess.command = ["cat", backlightPath]
        brightnessProcess.running = true
    }
    
    // Optimistic + coalesced like Audio.setVolume: the value moves at once,
    // only the latest target is written, and polls are ignored while busy.
    property real _pendingValue: -1
    readonly property bool _busy: _pendingValue >= 0 || setBrightnessProcess.running || settleTimer.running

    function setBrightness(value) {
        if (backlightPath === "")
            return
        const v = Math.max(0, Math.min(1, value))
        brightness = v
        _pendingValue = v
        settleTimer.restart()
        if (!setBrightnessProcess.running) _flushBrightness()
    }

    function _flushBrightness() {
        if (_pendingValue < 0) return
        const newValue = _pendingValue
        _pendingValue = -1
        // brightnessctl when available, sysfs write as fallback
        const percent = Math.round(newValue * 100)
        const sysfsValue = Math.round(newValue * maxValue)
        const cmd = `brightnessctl -q set ${percent}% || echo ${sysfsValue} | sudo tee "${backlightPath}" >/dev/null`
        setBrightnessProcess.command = ["/bin/sh", "-c", cmd]
        setBrightnessProcess.running = true
    }

    Timer {
        id: settleTimer
        interval: 700
    }

    function increaseBrightness() {
        setBrightness(brightness + 0.05)
    }
    
    function decreaseBrightness() {
        setBrightness(brightness - 0.05)
    }
    
    // Read max brightness
    Process {
        id: detectProc
        command: ["/bin/sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n 1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const dev = text.trim()
                if (dev.length > 0) {
                    root._backlightDevice = dev
                } else {
                    root._backlightDevice = ""
                }

                readMaxBrightness()
                readBrightness()
            }
        }
    }

    Process {
        id: maxBrightnessProcess
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0) {
                    maxValue = value
                }
            }
        }
    }
    
    // Read current brightness
    Process {
        id: brightnessProcess
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && !root._busy) {
                    currentValue = value
                    brightness = maxValue > 0 ? value / maxValue : 0
                }
            }
        }
    }
    
    // Set brightness process
    Process {
        id: setBrightnessProcess
        running: false
        onExited: root._flushBrightness()
    }
    
    // Update timer - optimized interval
    Timer {
        id: updateTimer
        interval: 2000  // Reduced frequency from 1000ms to 2000ms (brightness changes infrequently)
        repeat: true
        triggeredOnStart: true  // Get immediate first read
        onTriggered: readBrightness()
    }
}
