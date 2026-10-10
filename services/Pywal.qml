pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "../config" as QsConfig
import "." as QsServices

Singleton {
    id: root
    
    // Pywal color properties with defaults as proper colors
    // Catppuccin Mocha defaults (overridden if a real pywal colors.json is loaded)
    property color background: "#1e1e2e"   // base
    property color foreground: "#cdd6f4"   // text
    property color cursor: "#f5e0dc"       // rosewater

    property color color0: "#45475a"       // surface1
    property color color1: "#f38ba8"       // red
    property color color2: "#a6e3a1"       // green
    property color color3: "#f9e2af"       // yellow
    property color color4: "#89b4fa"       // blue (primary accent)
    property color color5: "#f5c2e7"       // pink
    property color color6: "#94e2d5"       // teal
    property color color7: "#bac2de"       // subtext1
    property color color8: "#7f849c"       // overlay1 (muted text / outlines)
    property color color9: "#f38ba8"
    property color color10: "#a6e3a1"
    property color color11: "#fab387"      // peach
    property color color12: "#89b4fa"
    property color color13: "#cba6f7"      // mauve
    property color color14: "#74c7ec"      // sapphire
    property color color15: "#a6adc8"      // subtext0

    // === Semantic Color Tokens ===
    // Use these instead of hardcoded colors for consistency
    
    // Relative luminance (WCAG) used to pick a readable foreground for a
    // coloured fill. Black wins over white once luminance passes ~0.179,
    // which is where both reach the same contrast ratio.
    function _luminance(c): real {
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }
    function readableOn(c): color {
        return _luminance(c) > 0.179 ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1)
    }

    // Primary accent color (derived from pywal)
    readonly property color primary: color4
    readonly property color primaryContainer: Qt.rgba(color4.r, color4.g, color4.b, 0.2)
    readonly property color onPrimary: readableOn(primary)
    
    // Secondary accent
    readonly property color secondary: color5
    readonly property color secondaryContainer: Qt.rgba(color5.r, color5.g, color5.b, 0.2)
    
    // Tertiary accent
    readonly property color tertiary: color6
    readonly property color tertiaryContainer: Qt.rgba(color6.r, color6.g, color6.b, 0.2)
    
    // Surface colors — translucent tones stepped from background toward
    // foreground, so the wallpaper shows through every panel. Alpha rises with
    // the elevation step to keep nested cards readable.
    function _tone(t: real, a: real): color {
        return Qt.rgba(background.r + (foreground.r - background.r) * t,
                       background.g + (foreground.g - background.g) * t,
                       background.b + (foreground.b - background.b) * t, a)
    }
    readonly property color surface: _tone(0.03, 0.55)
    readonly property color surfaceDim: _tone(0.0, 0.50)
    readonly property color surfaceBright: _tone(0.18, 0.62)
    readonly property color surfaceContainer: _tone(0.05, 0.55)
    readonly property color surfaceContainerLow: _tone(0.02, 0.50)
    readonly property color surfaceContainerHigh: _tone(0.10, 0.55)
    readonly property color surfaceContainerHighest: _tone(0.15, 0.58)
    readonly property color onSurface: foreground
    readonly property color onSurfaceVariant: color8
    readonly property color onSurfaceMuted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.68)

    // Compatibility aliases kept for existing components now mapped to solid surfaces
    readonly property color glassLow: surfaceContainerLow
    readonly property color glassHigh: surfaceContainerHigh
    readonly property color glassHighest: surfaceContainerHighest
    readonly property color glassBorder: outlineVariant
    readonly property color glassBorderStrong: Qt.rgba(primary.r, primary.g, primary.b, 0.28)
    
    // === One UI role tokens (QuickShell adaptation, not official values) ===
    // Transient surfaces (popups, panels hosted in the bar) sit one step above
    // the flat black shell; the control center itself stays on panelBackground.
    readonly property color panelBackground: _tone(0.0, 0.55)
    readonly property color popupSurface: _tone(0.05, 0.60)
    readonly property color divider: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12)
    readonly property color selectedContainer: Qt.rgba(color4.r, color4.g, color4.b, 0.2)

    // Quick-settings tile roles: "on" is a light fill with a dark glyph,
    // "off" is a dim fill with a muted glyph. Derived from foreground /
    // background so a light pywal scheme still gets matching contrast.
    readonly property color tileOn: foreground
    readonly property color tileGlyphOn: Qt.rgba(background.r, background.g, background.b, 0.85)
    readonly property color tileOff: Qt.rgba(0, 0, 0, 0.25)
    readonly property color tileGlyphOff: Qt.rgba(foreground.r * 0.78 + background.r * 0.22, foreground.g * 0.78 + background.g * 0.22, foreground.b * 0.78 + background.b * 0.22, 1)  // opaque: muted glyph without relying on alpha

    // Bar pills: translucent scrim so glyphs stay legible on any wallpaper,
    // one step lighter on hover.
    readonly property color barPill: Qt.rgba(background.r, background.g, background.b, 0.28)
    readonly property color barPillHover: Qt.rgba(background.r * 0.6 + foreground.r * 0.4, background.g * 0.6 + foreground.g * 0.4, background.b * 0.6 + foreground.b * 0.4, 0.46)

    // Switch roles
    readonly property color switchTrackOff: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.3)
    readonly property color switchThumb: foreground

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
