import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../components/effects"

Rectangle {
    id: root
    
    required property var systemUsage
    property var pywal
    
    // Color tokens
    readonly property color surfaceColor: pywal ? Qt.lighter(pywal.background, 1.15) : "#1e1e2e"
    readonly property color textColor: pywal ? pywal.foreground : "#e6e6e6"
    readonly property color textDim: pywal ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.5) : "#808080"
    
    Layout.fillWidth: true
    Layout.preferredHeight: 72
    
    radius: 16
    color: surfaceColor
    
    Behavior on color {
        ColorAnimation {
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 0
        
        Item { Layout.fillWidth: true }
        
        StatItem {
            icon: "󰘚"
            label: "CPU"
            value: (root.systemUsage.cpuPerc ?? 0) * 100
            accentColor: root.pywal?.error ?? "#f38ba8"
        }
        
        Item { Layout.fillWidth: true }
        
        // Separator
        Rectangle {
            width: 1
            height: 40
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
        }
        
        Item { Layout.fillWidth: true }
        
        StatItem {
            icon: "󰍛"
            label: "RAM"
            value: (root.systemUsage.memPerc ?? 0) * 100
            accentColor: root.pywal?.warning ?? "#fab387"
        }
        
        Item { Layout.fillWidth: true }
        
        Rectangle {
            width: 1
            height: 40
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
        }
        
        Item { Layout.fillWidth: true }
        
        StatItem {
            icon: "󰋊"
            label: "Disk"
            value: (root.systemUsage.diskPerc ?? 0) * 100
            accentColor: root.pywal?.info ?? "#89b4fa"
        }
        
        Item { Layout.fillWidth: true }
        
        // GPU (if available)
        Rectangle {
            visible: root.systemUsage.hasGpu
            width: 1
            height: 40
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
        }
        
        Item { 
            Layout.fillWidth: true 
            visible: root.systemUsage.hasGpu
        }
        
        StatItem {
            visible: root.systemUsage.hasGpu
            icon: "󰢮"
            label: "GPU"
            value: root.systemUsage.gpuUsage ?? 0
            accentColor: root.pywal?.success ?? "#a6e3a1"
        }
        
        Item { 
            Layout.fillWidth: true 
            visible: root.systemUsage.hasGpu
        }
    }
    
    component StatItem: ColumnLayout {
        property string icon
        property string label
        property real value
        property color accentColor
        
        spacing: 4
        
        // Icon + Value row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            
            Text {
                text: icon
                font.family: "Material Design Icons"
                font.pixelSize: 16
                color: accentColor
            }
            
            Text {
                text: Math.round(value) + "%"
                font.family: "Inter"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: root.textColor
                
                Behavior on text {
                    enabled: false
                }
            }
        }
        
        // Progress bar
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 3
            radius: 1.5
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
            
            Rectangle {
                width: parent.width * Math.min(value / 100, 1)
                height: parent.height
                radius: 1.5
                color: accentColor
                
                Behavior on width {
                    NumberAnimation {
                        duration: Material3Anim.medium2
                        easing.bezierCurve: Material3Anim.emphasizedDecelerate
                    }
                }
            }
        }
        
        // Label
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: label
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.textDim
        }
    }
}
