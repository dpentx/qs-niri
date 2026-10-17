pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "../config" as QsConfig
import "." as QsServices

// Screenshot/Screen Recording Service
Singleton {
    id: root
    
    property bool isRecording: false
    property real recordStart: 0   // Date.now() when the current recording began
    property string lastScreenshotPath: ""
    property string lastRecordingPath: ""
    property string screenshotsDir: QsConfig.Config.paths.screenshotsDir

    property string _slurpGeometry: ""
    
    Component.onCompleted: {
        // Create screenshots directory if it doesn't exist
        mkdirProc.running = true
    }
    
    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.screenshotsDir]
    }
    
    function takeScreenshot(mode: string) {
        // mode: "screen", "window", "region"
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
        const filename = `screenshot-${timestamp}.png`
        const filepath = `${screenshotsDir}/${filename}`
        
        if (mode === "region") {
            // For region selection, use slurp to get geometry then grim to capture
            slurpProc.exec(["slurp"])
        } else if (mode === "screen") {
            // Capture entire screen
            screenshotProc.exec(["grim", filepath])
            root.lastScreenshotPath = filepath
        } else if (mode === "window") {
            // niri captures the focused window itself (saved to niri's screenshot-path and copied)
            Quickshell.execDetached(["niri", "msg", "action", "screenshot-window"])
        }
    }
    
    // Get region geometry with slurp
    Process {
        id: slurpProc
        stdout: StdioCollector {
            onStreamFinished: root._slurpGeometry = text.trim()
        }
        onExited: code => {
            const geometry = root._slurpGeometry
            root._slurpGeometry = ""
            if (code === 0 && geometry !== "") {
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
                const filename = `screenshot-${timestamp}.png`
                const filepath = `${root.screenshotsDir}/${filename}`

                QsServices.Logger.debug("Screenshot", `Capturing region: ${geometry}`)
                screenshotProc.exec(["grim", "-g", geometry, filepath])
                root.lastScreenshotPath = filepath
            } else if (code !== 0) {
                QsServices.Logger.error("Screenshot", `slurp failed with code: ${code}`)
            }
        }
    }
    
    
    Process {
        id: screenshotProc
        onExited: code => {
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Saved: ${root.lastScreenshotPath}`)
                
                // Copy to clipboard using wl-copy with shell redirection
                clipboardProc.exec(["sh", "-c", `wl-copy < "${root.lastScreenshotPath}"`])
                
                notifyProc.exec([
                    "notify-send",
                    "-i", root.lastScreenshotPath,
                    "Screenshot captured",
                    `Saved and copied to clipboard`
                ])
            } else {
                QsServices.Logger.error("Screenshot", `Failed with code: ${code}`)
            }
        }
    }
    
    Process {
        id: clipboardProc
    }
    
    Process {
        id: notifyProc
    }
    
    function toggleRecording() {
        if (isRecording) {
            stopRecording()
        } else {
            startRecording()
        }
    }

    function startRecording() {
        if (isRecording) return

        // "-w focused" needs a manually-specified "-s WxH" (gsr doesn't
        // know the resolution up front for that mode). Recording an actual
        // monitor by name avoids that entirely since gsr already knows
        // that monitor's resolution — so look the name up first.
        listMonitorsProc.running = true
    }

    Process {
        id: listMonitorsProc
        command: ["gpu-screen-recorder", "--list-monitors"]
        stdout: StdioCollector {
            id: monitorListOutput
            onStreamFinished: {
                // Typical `--list-monitors` output is lines like:
                //   eDP-1 1920x1080
                //   DP-1 2560x1440
                // Take the first monitor listed as the recording target.
                const firstLine = text.split("\n").map(l => l.trim()).find(l => l.length > 0)
                const monitorName = firstLine ? firstLine.split(/\s+/)[0] : ""

                if (!monitorName) {
                    QsServices.Logger.error("Screenshot", `Could not determine a monitor to record from --list-monitors output: ${text}`)
                    notifyProc.exec([
                        "notify-send",
                        "-u", "critical",
                        "Screen recording failed",
                        "Could not detect a monitor to record (gpu-screen-recorder --list-monitors returned nothing usable)"
                    ])
                    return
                }

                const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
                const filename = `recording-${timestamp}.mp4`
                const filepath = `${screenshotsDir}/${filename}`
                root.lastRecordingPath = filepath

                recordProc.exec([
                    "gpu-screen-recorder",
                    "-w", monitorName,
                    "-f", "60",
                    "-a", "default_output",
                    "-o", filepath
                ])

                // Optional separate overlay shell; only started if it still exists.
                overlayProc.exec(["sh", "-c", `d="${Quickshell.env("HOME")}/.config/quickshell-local/scripts/gsr-overlay"; [ -e "$d" ] && exec quickshell -p "$d"; exit 0`])

                root.recordStart = Date.now()
                root.isRecording = true
                QsServices.Logger.info("Screenshot", `Recording started on monitor ${monitorName}`)
            }
        }
    }
    
    Process {
        id: overlayProc
    }
    
    Process {
        id: recordProc
        stderr: StdioCollector {
            id: recordStderr
        }
        onExited: code => {
            root.isRecording = false
            root.recordStart = 0
            overlayProc.running = false
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Recording saved: ${root.lastRecordingPath}`)
                notifyProc.exec([
                    "notify-send",
                    "-i", "video-x-generic",
                    "Screen recording saved",
                    root.lastRecordingPath
                ])
            } else {
                QsServices.Logger.error("Screenshot", `gpu-screen-recorder exited with code ${code}: ${recordStderr.text}`)
                notifyProc.exec([
                    "notify-send",
                    "-u", "critical",
                    "-i", "video-x-generic",
                    "Screen recording failed",
                    `gpu-screen-recorder exited with code ${code}: ${recordStderr.text.trim().split("\n").slice(-2).join(" ")}`
                ])
            }
        }
    }
    
    function stopRecording() {
        if (!isRecording) return
        
        stopRecordProc.running = true
        // isRecording will be set to false when the recording process finishes
    }
    
    Process {
        id: stopRecordProc
        command: ["pkill", "-SIGINT", "-f", "gpu-screen-recorder"]
    }
    
    function openScreenshotsFolder() {
        openProc.exec(["xdg-open", screenshotsDir])
    }
    
    Process {
        id: openProc
    }
    
    function copyLastScreenshot() {
        if (!lastScreenshotPath) return

        copyProc.exec(["sh", "-c", `wl-copy < "${lastScreenshotPath}"`])
    }
    
    Process {
        id: copyProc
    }
    
    function deleteLastScreenshot() {
        if (!lastScreenshotPath) return
        
        deleteProc.exec(["rm", lastScreenshotPath])
    }
    
    Process {
        id: deleteProc
        onExited: code => {
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Deleted: ${root.lastScreenshotPath}`)
                root.lastScreenshotPath = ""
            }
        }
    }
}
