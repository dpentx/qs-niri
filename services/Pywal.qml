pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "../config" as QsConfig
import "." as QsServices

Singleton {
    id: root
    
    // Pywal color properties with defaults as proper colors
    // OneUI-themed defaults (overridden if a real pywal colors.json is loaded)
    property color background: "#000000"   // sec_panel_background_color
    property color foreground: "#fcfcff"   // near-white, matches qs_tile_round_background_on hue
    property color cursor: "#fcfcff"
    
    // Individual color properties for easy access
    property color color0: "#000000"
    property color color1: "#ff453a"       // error red (kept close to AOSP default, OneUI uses similar)
    property color color2: "#37B679"       // Green for connected states
    property color color3: "#FF9F00"       // Orange for warnings
    property color color4: "#598fff"       // sec_qs_switch_on_background_color — OneUI accent blue
    property color color5: "#8fa8d6"       // muted blue-gray secondary accent
    property color color6: "#a6b8e0"       // tertiary, same family as accent
    property color color7: "#fcfcff"
    property color color8: "#8e8e93"       // OneUI-ish neutral gray for outlines/muted text
    property color color9: "#ff453a"
    property color color10: "#37B679"
    property color color11: "#BE5052"
    property color color12: "#598fff"
    property color color13: "#8fa8d6"
    property color color14: "#a6b8e0"
    property color color15: "#fcfcff"
    
    // === Semantic Color Tokens ===
    // Use these instead of hardcoded colors for consistency
    
    // Primary accent color (derived from pywal)
    readonly property color primary: color4
    readonly property color primaryContainer: Qt.rgba(color4.r, color4.g, color4.b, 0.2)
    readonly property color onPrimary: foreground
    
    // Secondary accent
    readonly property color secondary: color5
    readonly property color secondaryContainer: Qt.rgba(color5.r, color5.g, color5.b, 0.2)
    
    // Tertiary accent
    readonly property color tertiary: color6
    readonly property color tertiaryContainer: Qt.rgba(color6.r, color6.g, color6.b, 0.2)
    
    // Surface colors — OneUI is flat and near-black; Qt.lighter() is a no-op on
    // pure black (0 * factor = 0), so surface steps are explicit near-black
    // tones instead of computed from `background`.
    readonly property color surface: "#0a0a0a"
    readonly property color surfaceDim: "#000000"
    readonly property color surfaceBright: "#1c1c1e"
    readonly property color surfaceContainer: "#121212"
    readonly property color surfaceContainerLow: "#0a0a0a"
    readonly property color surfaceContainerHigh: "#1a1a1a"
    readonly property color surfaceContainerHighest: "#202022"
    readonly property color onSurface: foreground
    readonly property color onSurfaceVariant: color8
    readonly property color onSurfaceMuted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.68)

    // Compatibility aliases kept for existing components now mapped to solid surfaces
    readonly property color glassLow: surfaceContainerLow
    readonly property color glassHigh: surfaceContainerHigh
    readonly property color glassHighest: surfaceContainerHighest
    readonly property color glassBorder: outlineVariant
    readonly property color glassBorderStrong: Qt.rgba(primary.r, primary.g, primary.b, 0.28)
    
    // Outline colors
    readonly property color outline: color8
    readonly property color outlineVariant: Qt.rgba(color8.r, color8.g, color8.b, 0.5)
    
    // State colors
    readonly property color success: color2      // Green
    readonly property color onSuccess: background
    readonly property color warning: color3      // Orange
    readonly property color onWarning: background
    readonly property color error: color1        // Red
    readonly property color onError: foreground
    readonly property color info: color4         // Blue-ish accent
    
    // Interactive state overlays
    readonly property color stateLayerLight: Qt.rgba(foreground.r, foreground.g, foreground.b, 1)
    readonly property color stateLayerDark: Qt.rgba(background.r, background.g, background.b, 1)
    
    // Inverse colors (for contrast situations)
    readonly property color inverseSurface: foreground
    readonly property color inverseOnSurface: background
    readonly property color inversePrimary: Qt.lighter(primary, 1.5)
    
    // Scrim (overlay for modals)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.5)
    
    // Shadow color
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.3)
    
    function loadColors(text: string): void {
        try {
            const data = JSON.parse(text);
            if (data.special) {
                root.background = data.special.background || root.background;
                root.foreground = data.special.foreground || root.foreground;
                root.cursor = data.special.cursor || root.cursor;
            }
            if (data.colors) {
                // Load individual colors
                if (data.colors.color0) root.color0 = data.colors.color0;
                if (data.colors.color1) root.color1 = data.colors.color1;
                if (data.colors.color2) root.color2 = data.colors.color2;
                if (data.colors.color3) root.color3 = data.colors.color3;
                if (data.colors.color4) root.color4 = data.colors.color4;
                if (data.colors.color5) root.color5 = data.colors.color5;
                if (data.colors.color6) root.color6 = data.colors.color6;
                if (data.colors.color7) root.color7 = data.colors.color7;
                if (data.colors.color8) root.color8 = data.colors.color8;
                if (data.colors.color9) root.color9 = data.colors.color9;
                if (data.colors.color10) root.color10 = data.colors.color10;
                if (data.colors.color11) root.color11 = data.colors.color11;
                if (data.colors.color12) root.color12 = data.colors.color12;
                if (data.colors.color13) root.color13 = data.colors.color13;
                if (data.colors.color14) root.color14 = data.colors.color14;
                if (data.colors.color15) root.color15 = data.colors.color15;
            }
            QsServices.Logger.debug("Pywal", "colors.json loaded")
        } catch (e) {
            QsServices.Logger.error("Pywal", "Failed to parse colors.json", e?.message ?? e)
        }
    }
    
    // Load colors from pywal cache
    FileView {
        id: pywalFile
        path: QsConfig.Config.paths.pywalColors
        watchChanges: true
        onLoaded: root.loadColors(text())
        onFileChanged: root.loadColors(text())
        onLoadFailed: err => QsServices.Logger.warn("Pywal", `colors.json not loaded: ${FileViewError.toString(err)}`)
    }
}
