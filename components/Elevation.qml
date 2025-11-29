// Elevation.qml - Material 3 Elevation Shadow System
// Provides consistent shadow effects across the UI
// Based on Material Design 3 elevation tokens

import QtQuick 6.10
import QtQuick.Effects

Item {
    id: root
    
    // Elevation level (0-5)
    // 0: No shadow
    // 1: Low (cards, list items)
    // 2: Medium (FAB, raised buttons)
    // 3: High (menus, dialogs)
    // 4: Higher (modals, overlays)
    // 5: Maximum (navigation drawers)
    property int level: 1
    
    // Shadow color (typically dark with opacity)
    property color shadowColor: Qt.rgba(0, 0, 0, 0.25)
    
    // Target item to apply shadow to (optional - uses parent if not set)
    property Item target: parent
    
    // Radius matching target (for proper shadow shape)
    property real radius: target?.radius ?? 0
    
    // Elevation DP values per level
    readonly property var elevationDp: [0, 1, 3, 6, 8, 12]
    
    // Current elevation in dp
    readonly property real dp: elevationDp[Math.min(Math.max(0, level), 5)]
    
    // Computed shadow properties based on Material 3 guidelines
    readonly property real blur: Math.pow(dp * 5, 0.7)
    readonly property real spread: -dp * 0.3 + Math.pow(dp * 0.1, 2)
    readonly property real offsetY: dp / 2
    
    anchors.fill: target
    z: -1
    
    // Primary shadow (key light - sharper, offset)
    Rectangle {
        id: keyShadow
        anchors.fill: parent
        anchors.topMargin: root.offsetY
        radius: root.radius
        color: "transparent"
        visible: root.level > 0
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(
                root.shadowColor.r,
                root.shadowColor.g,
                root.shadowColor.b,
                root.shadowColor.a * 0.6
            )
            shadowBlur: root.blur * 0.6
            shadowVerticalOffset: root.offsetY
            shadowHorizontalOffset: 0
            shadowScale: 1.0 + (root.spread * 0.01)
        }
    }
    
    // Ambient shadow (softer, no offset)
    Rectangle {
        id: ambientShadow
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: root.level > 0
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(
                root.shadowColor.r,
                root.shadowColor.g,
                root.shadowColor.b,
                root.shadowColor.a * 0.4
            )
            shadowBlur: root.blur
            shadowVerticalOffset: root.dp * 0.25
            shadowHorizontalOffset: 0
            shadowScale: 1.0 + (root.spread * 0.02)
        }
    }
    
    // Animate elevation changes smoothly
    Behavior on level {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
}
