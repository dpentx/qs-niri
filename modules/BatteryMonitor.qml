import Quickshell
import QtQuick

// BatteryMonitor disabled to avoid automatic power actions.
// To re-enable, replace this file with the previous logic or set enabled = true.
Scope {
    id: root
    property bool enabled: false

    Component.onCompleted: {
        if (!enabled) {
            if (QsLogger) QsLogger.info && QsLogger.info("BatteryMonitor", "Disabled by user: battery/power actions are suppressed.")
        } else {
            if (QsLogger) QsLogger.info && QsLogger.info("BatteryMonitor", "Enabled")
        }
    }
}
