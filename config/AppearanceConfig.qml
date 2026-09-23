import QtQuick 6.10

QtObject {
    // Single corner-radius scale. (Previously duplicated by a separate
    // `rounding` scale with near-identical values under different names -
    // neither was actually referenced by any component, which just wrote
    // its own literal radius. `radius` is now the one scale; wire new/
    // edited components to it instead of a magic number.)
    readonly property var radius: QtObject {
        property int xs: 6
        property int s: 10
        property int m: 16
        property int l: 22
        property int xl: 32
        property int full: 9999
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
