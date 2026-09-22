pragma Singleton

import Quickshell

Singleton {
    // Directly expose the design-token scale from Config.appearanceTokens
    // (AppearanceConfig.qml). This was previously pointed at Config.appearance,
    // a much smaller object that only holds fontFamily/materialIconFont —
    // every property below was silently undefined. Fixed to reference the
    // actual token set so this singleton (and components/Anim.qml, its only
    // consumer) resolve correctly.
    readonly property var rounding: Config.appearanceTokens.rounding
    readonly property var radius: Config.appearanceTokens.radius
    readonly property var spacing: Config.appearanceTokens.spacing
    readonly property var margins: Config.appearanceTokens.margins
    readonly property var padding: Config.appearanceTokens.padding
    readonly property var font: Config.appearanceTokens.font
    readonly property var typography: Config.appearanceTokens.typography
    readonly property var transparency: Config.appearanceTokens.transparency
    // Motion tokens now live in components/effects/OneUIMotion.qml, not here.
}
