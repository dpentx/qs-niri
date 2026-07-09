// Material3Anim.qml - Material Design 3 Expressive Motion System
// Based on Material 3 2024 motion guidelines
// Clean, smooth, professional animations

pragma Singleton
import QtQuick

QtObject {
    id: root
    
    // === Duration Tokens (milliseconds) ===
    readonly property int short1: 50
    readonly property int short2: 100
    readonly property int short3: 150
    readonly property int short4: 200
    
    readonly property int medium1: 250
    readonly property int medium2: 300
    readonly property int medium3: 350
    readonly property int medium4: 400
    
    readonly property int long1: 450
    readonly property int long2: 500
    readonly property int long3: 550
    readonly property int long4: 600
    
    readonly property int extraLong1: 700
    readonly property int extraLong2: 800
    readonly property int extraLong3: 900
    readonly property int extraLong4: 1000
    
    // === Material 3 Easing Curves ===
    // Emphasized - For important UI state changes
    readonly property var emphasized: [0.2, 0.0, 0, 1.0]
    
    // Emphasized Decelerate - Entrance animations (objects entering screen)
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1.0]
    
    // Emphasized Accelerate - Exit animations (objects leaving screen)
    readonly property var emphasizedAccelerate: [0.3, 0.0, 0.8, 0.15]
    
    // Standard - Normal UI transitions
    readonly property var standard: [0.2, 0.0, 0, 1.0]
    
    // Standard Decelerate - Incoming elements
    readonly property var standardDecelerate: [0.0, 0.0, 0, 1.0]
    
    // Standard Accelerate - Outgoing elements
    readonly property var standardAccelerate: [0.3, 0.0, 1.0, 1.0]
    
    // === Material 3 Expressive Curves (2024) ===
    // For playful, bouncy interactions
    readonly property var expressiveDecelerate: [0.0, 0.0, 0.0, 1.0]
    readonly property var expressiveAccelerate: [0.4, 0.0, 1.0, 1.0]
    readonly property var expressiveSpatial: [0.3, 0.0, 0.0, 1.0]
    
    // Spring-like overshoot for toggles and buttons
    readonly property var springBounce: [0.34, 1.56, 0.64, 1.0]
    readonly property var springGentle: [0.22, 1.0, 0.36, 1.0]
    
    // === Opacity Tokens for State Layers ===
    readonly property real hoverOpacity: 0.08
    readonly property real focusOpacity: 0.12
    readonly property real pressedOpacity: 0.12
    readonly property real draggedOpacity: 0.16
    readonly property real disabledOpacity: 0.38
    readonly property real disabledContainerOpacity: 0.12
    
    // === Scale Tokens for Micro-interactions ===
    readonly property real pressedScale: 0.96
    readonly property real hoverScale: 1.02
    readonly property real bouncePeakScale: 1.08
}
