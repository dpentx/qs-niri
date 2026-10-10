import QtQuick 6.10

QtObject {
    // Single corner-radius scale (QuickShell adaptation of One UI's rounded
    // geometry; the numbers are tuned for a desktop shell, not official
    // Samsung values). Five steps instead of the ~25 ad-hoc literals the
    // modules used to carry. Pick by component role, not by eyeballing:
    //   xs  - chips, small indicators, inner thumbnails
    //   s   - list rows, small buttons, text fields
    //   m   - cards, grouped rows, popup sections
    //   l   - tiles, panels, popups
    //   xl  - full-width sheets / large modal cards
    //   full - pills and circles (or use `height / 2` for a true pill)
    // Radii of 5 and below (progress bars, sliders, handles) stay literal:
    // they are shape details of a tiny element, not a surface corner.
    readonly property var radius: QtObject {
        property int xs: 4
        property int s: 8
        property int m: 12
        property int l: 16
        property int xl: 22
        property int full: 9999
    }

    // Hairline widths. One UI surfaces are mostly borderless; use `thin`
    // only where a surface must separate from an equally dark neighbour.
    readonly property var border: QtObject {
        property int none: 0
        property int thin: 1
        property int focus: 2
    }

    // Control sizing. Pointer targets stay comfortable on desktop without
    // turning the shell into an enlarged phone UI.
    readonly property var size: QtObject {
        property int controlS: 32     // compact bar / icon buttons
        property int controlM: 40     // default buttons and list rows
        property int controlL: 48     // primary actions
        property int iconS: 16
        property int iconM: 20
        property int iconL: 24
    }

    readonly property var spacing: QtObject {
        property int tiny: 4
        property int small: 8
        property int medium: 12
        property int large: 16
        property int huge: 24
    }

    readonly property var margins: QtObject {
        property int xs: 6
        property int s: 10
        property int m: 14
        property int l: 20
        property int xl: 28
    }

    readonly property var padding: QtObject {
        property int tiny: 4
        property int small: 8
        property int medium: 12
        property int large: 16
        property int huge: 22
    }

    readonly property var font: QtObject {
        property string family: "OneUI Sans"
        property int small: 10
        property int medium: 12
        property int large: 14
        property int huge: 16
    }

    // Typography scale (One UI sizing)
    readonly property var typography: QtObject {
        property string family: "OneUI Sans"
        
        readonly property var displayLarge: QtObject { property int size: 57; property int weight: Font.Normal }
        readonly property var displayMedium: QtObject { property int size: 45; property int weight: Font.Normal }
        readonly property var displaySmall: QtObject { property int size: 36; property int weight: Font.Normal }
        
        readonly property var headlineLarge: QtObject { property int size: 32; property int weight: Font.Normal }
        readonly property var headlineMedium: QtObject { property int size: 28; property int weight: Font.Normal }
        readonly property var headlineSmall: QtObject { property int size: 24; property int weight: Font.Normal }
        
        readonly property var titleLarge: QtObject { property int size: 22; property int weight: Font.Normal }
        readonly property var titleMedium: QtObject { property int size: 16; property int weight: Font.Medium }
        readonly property var titleSmall: QtObject { property int size: 14; property int weight: Font.Medium }
        
        readonly property var labelLarge: QtObject { property int size: 14; property int weight: Font.Medium }
        readonly property var labelMedium: QtObject { property int size: 12; property int weight: Font.Medium }
        readonly property var labelSmall: QtObject { property int size: 11; property int weight: Font.Medium }
        
        readonly property var bodyLarge: QtObject { property int size: 16; property int weight: Font.Normal }
        readonly property var bodyMedium: QtObject { property int size: 14; property int weight: Font.Normal }
        readonly property var bodySmall: QtObject { property int size: 12; property int weight: Font.Normal }
    }

    // Animation durations/curves live in components/effects/OneUIMotion.qml —
    // this used to duplicate that set under different names (fast/normal/
    // medium/slow vs. short1..long4) and was only read by the dead
    // components/Anim.qml, which is now wired to OneUIMotion directly.

    readonly property var transparency: QtObject {
        property real full: 1.0
        property real high: 0.92
        property real medium: 0.68
        property real low: 0.42
        property real minimal: 0.14
    }
}
