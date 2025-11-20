import QtQuick 6.10

QtObject {
    readonly property var rounding: QtObject {
        property int small: 4
        property int medium: 8
        property int large: 12
        property int extraLarge: 16
        property int full: 9999
    }

    // Standardized radius (Material 3)
    readonly property var radius: QtObject {
        property int xs: 4
        property int s: 8
        property int m: 12
        property int l: 16
        property int xl: 28
        property int full: 9999
    }

    readonly property var spacing: QtObject {
        property int tiny: 2
        property int small: 4
        property int medium: 8
        property int large: 12
        property int huge: 16
    }

    readonly property var margins: QtObject {
        property int xs: 4
        property int s: 8
        property int m: 12
        property int l: 16
        property int xl: 24
    }

    readonly property var padding: QtObject {
        property int tiny: 2
        property int small: 4
        property int medium: 8
        property int large: 12
        property int huge: 16
    }

    readonly property var font: QtObject {
        property string family: "Inter"
        property int small: 10
        property int medium: 12
        property int large: 14
        property int huge: 16
    }

    // Material 3 Typography Scale
    readonly property var typography: QtObject {
        property string family: "Inter"
        
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

    readonly property var anim: QtObject {
        readonly property var durations: QtObject {
            property int instant: 0
            property int fast: 150
            property int normal: 200
            property int medium: 250
            property int slow: 350
            property int slower: 500
        }

        readonly property var curves: QtObject {
            // Standard Material Design easing curves
            property var standard: [0.2, 0.0, 0, 1.0]
            property var standardDecel: [0.0, 0.0, 0, 1.0]
            property var standardAccel: [0.3, 0.0, 1, 1.0]
            property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0]
            property var emphasizedAccel: [0.3, 0.0, 0.8, 0.15]
        }
        
        readonly property var easing: QtObject {
            property int standard: Easing.OutCubic
            property int emphasized: Easing.OutBack
            property int sharp: Easing.InOutQuad
            property int smooth: Easing.InOutCubic
        }
    }

    readonly property var transparency: QtObject {
        property real full: 1.0
        property real high: 0.87
        property real medium: 0.60
        property real low: 0.38
        property real minimal: 0.12
    }
}
