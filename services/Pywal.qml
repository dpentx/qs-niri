pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

Singleton {
    id: root
    
    // Pywal color properties with defaults as proper colors
    property color background: "#070605"
    property color foreground: "#e9e5e6"
    property color cursor: "#e9e5e6"
    
    // Individual color properties for easy access
    property color color0: "#070605"
    property color color1: "#DE1222"
    property color color2: "#37B679"  // Green for connected states
    property color color3: "#FF9F00"  // Orange for warnings
    property color color4: "#CE6649"
    property color color5: "#9A847D"
    property color color6: "#B39FA7"
    property color color7: "#e9e5e6"
    property color color8: "#a3a0a1"
    property color color9: "#DE1222"
    property color color10: "#37B679"
    property color color11: "#BE5052"
    property color color12: "#CE6649"
    property color color13: "#9A847D"
    property color color14: "#B39FA7"
    property color color15: "#e9e5e6"
    
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
            console.log("Pywal colors loaded successfully");
        } catch (e) {
            console.error("Failed to parse pywal colors:", e);
        }
    }
    
    // Load colors from pywal cache
    FileView {
        id: pywalFile
        path: "/home/tripathiji/.cache/wal/colors.json"
        watchChanges: true
        onLoaded: root.loadColors(text())
        onFileChanged: root.loadColors(text())
    }
}
