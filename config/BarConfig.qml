import QtQuick 6.10

QtObject {
    readonly property var workspaces: QtObject {
        property int count: 5
        property bool showOccupiedIndicator: true
        property bool showActiveIndicator: true
        property bool unifiedPill: true
        property int pillPadding: 8
        property bool enableClickAnimation: true
        property bool enableSwitchAnimation: true
        property int animationDuration: 200
        property string activeColor: "#BE5052"
        property string occupiedColor: "#9A847D"
        property string emptyColor: "#a3a0a1"
        property string activeTextColor: "#e9e5e6"
        property string inactiveTextColor: "#a3a0a1"
        property string backgroundColor: "#070605"
        property string pillBackgroundColor: "#0a0908"
        property int workspaceSize: 18
        property int spacing: 6
        property int cornerRadius: 10
        property int indicatorSize: 4
    }
    
    readonly property int height: 44
    readonly property int topBarHeight: 30
    readonly property int padding: 4
    readonly property real backgroundOpacity: 0.0
    
    readonly property var islands: QtObject {
        property int borderRadius: 18
        property real surfaceOpacity: 1.0
        property real borderOpacity: 0.12
        property int spacing: 6
    }

    readonly property bool showNavigationButtons: true
    readonly property bool showCaptureButton: true
    readonly property bool showDesktopButton: true
}
