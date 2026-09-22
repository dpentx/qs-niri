// OneUIMotion.qml - Single motion-token source for the shell.
//
// QuickShell adaptation of Samsung One UI's motion language: motion explains
// state change, it doesn't decorate it. Curves stay calm and short; nothing
// here should read as bouncy or "expressive". This replaces the old
// Material3Anim.qml - duration/curve math is universal so values are kept,
// but Material-branded and unused "expressive" tokens have been removed.
//
// Previously AppearanceConfig.anim duplicated a second, differently-named
// set of the same concepts. This is now the one source components should
// import; AppearanceConfig.anim is kept only for values not covered here
// (see config/AppearanceConfig.qml).

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

    // === Easing Curves ===
    // Emphasized - for state changes the user should clearly notice
    // (panel open/close, toggle flips)
    readonly property var emphasized: [0.2, 0.0, 0, 1.0]

    // Emphasized Decelerate - entrance (a surface arriving on screen)
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1.0]

    // Emphasized Accelerate - exit (a surface leaving screen)
    readonly property var emphasizedAccelerate: [0.3, 0.0, 0.8, 0.15]

    // Standard - ordinary UI transitions (hover, color, small moves)
    readonly property var standard: [0.2, 0.0, 0, 1.0]

    // Standard Decelerate - incoming elements
    readonly property var standardDecelerate: [0.0, 0.0, 0, 1.0]

    // Standard Accelerate - outgoing elements
    readonly property var standardAccelerate: [0.3, 0.0, 1.0, 1.0]

    // Restrained settle for toggles/switches: a hint of overshoot, not a
    // bounce. (Old value [0.34, 1.56, 0.64, 1.0] overshot to 156% - too
    // playful for One UI's calmer feel; this settles at ~112%.)
    readonly property var springBounce: [0.3, 1.12, 0.6, 1.0]

    // Gentle, no-overshoot settle for larger surfaces
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
}
