import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

Item {
    readonly property var pywal: QsServices.Pywal
    readonly property var sysUsage: QsServices.SystemUsage
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        Text {
            text: "System Performance"
            font.family: "Inter"
            font.pixelSize: 16
            font.weight: Font.Bold
            color: pywal.foreground
        }
        
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: 12
            columnSpacing: 12
            
            // CPU Usage
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                radius: 10
                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    
                    Text {
                        text: "CPU"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: pywal.foreground
                    }
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Canvas {
                            id: cpuChart
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.85
                            height: width
                            
                            property real percentage: sysUsage.cpuPerc * 100
                            property real animatedPercentage: 0
                            
                            Behavior on animatedPercentage {
                                NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                            }
                            
                            onPercentageChanged: animatedPercentage = percentage
                            Component.onCompleted: animatedPercentage = percentage
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = Math.min(width, height) / 2 - 5
                                
                                // Background circle
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                ctx.fillStyle = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
                                ctx.fill()
                                
                                // Usage arc
                                var angle = (animatedPercentage / 100) * 2 * Math.PI
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + angle)
                                ctx.closePath()
                                
                                // Color based on usage
                                if (animatedPercentage < 50) {
                                    ctx.fillStyle = Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.8)
                                } else if (animatedPercentage < 80) {
                                    ctx.fillStyle = Qt.rgba(pywal.color3.r, pywal.color3.g, pywal.color3.b, 0.8)
                                } else {
                                    ctx.fillStyle = Qt.rgba(pywal.color1.r, pywal.color1.g, pywal.color1.b, 0.8)
                                }
                                ctx.fill()
                                
                                // Inner circle (donut)
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius * 0.6, 0, 2 * Math.PI)
                                ctx.fillStyle = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                                ctx.fill()
                            }
                            
                            onAnimatedPercentageChanged: requestPaint()
                        }
                        
                        Text {
                            anchors.centerIn: cpuChart
                            text: Math.round(sysUsage.cpuPerc * 100) + "%"
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: pywal.foreground
                        }
                    }
                }
            }
            
            // Memory Usage
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                radius: 10
                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    
                    Text {
                        text: "Memory"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: pywal.foreground
                    }
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Canvas {
                            id: memChart
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.85
                            height: width
                            
                            property real percentage: sysUsage.memPerc * 100
                            property real animatedPercentage: 0
                            
                            Behavior on animatedPercentage {
                                NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                            }
                            
                            onPercentageChanged: animatedPercentage = percentage
                            Component.onCompleted: animatedPercentage = percentage
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = Math.min(width, height) / 2 - 5
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                ctx.fillStyle = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
                                ctx.fill()
                                
                                var angle = (animatedPercentage / 100) * 2 * Math.PI
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + angle)
                                ctx.closePath()
                                
                                if (animatedPercentage < 50) {
                                    ctx.fillStyle = Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.8)
                                } else if (animatedPercentage < 80) {
                                    ctx.fillStyle = Qt.rgba(pywal.color3.r, pywal.color3.g, pywal.color3.b, 0.8)
                                } else {
                                    ctx.fillStyle = Qt.rgba(pywal.color1.r, pywal.color1.g, pywal.color1.b, 0.8)
                                }
                                ctx.fill()
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius * 0.6, 0, 2 * Math.PI)
                                ctx.fillStyle = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                                ctx.fill()
                            }
                            
                            onAnimatedPercentageChanged: requestPaint()
                        }
                        
                        Text {
                            anchors.centerIn: memChart
                            text: Math.round(sysUsage.memPerc * 100) + "%"
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: pywal.foreground
                        }
                    }
                }
            }
            
            // Disk Usage
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                radius: 10
                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    
                    Text {
                        text: "Disk"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: pywal.foreground
                    }
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Canvas {
                            id: diskChart
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.85
                            height: width
                            
                            property real percentage: sysUsage.diskPerc * 100
                            property real animatedPercentage: 0
                            
                            Behavior on animatedPercentage {
                                NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                            }
                            
                            onPercentageChanged: animatedPercentage = percentage
                            Component.onCompleted: animatedPercentage = percentage
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = Math.min(width, height) / 2 - 5
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                ctx.fillStyle = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)
                                ctx.fill()
                                
                                var angle = (animatedPercentage / 100) * 2 * Math.PI
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + angle)
                                ctx.closePath()
                                
                                if (animatedPercentage < 50) {
                                    ctx.fillStyle = Qt.rgba(pywal.color2.r, pywal.color2.g, pywal.color2.b, 0.8)
                                } else if (animatedPercentage < 80) {
                                    ctx.fillStyle = Qt.rgba(pywal.color3.r, pywal.color3.g, pywal.color3.b, 0.8)
                                } else {
                                    ctx.fillStyle = Qt.rgba(pywal.color1.r, pywal.color1.g, pywal.color1.b, 0.8)
                                }
                                ctx.fill()
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius * 0.6, 0, 2 * Math.PI)
                                ctx.fillStyle = Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                                ctx.fill()
                            }
                            
                            onAnimatedPercentageChanged: requestPaint()
                        }
                        
                        Text {
                            anchors.centerIn: diskChart
                            text: Math.round(sysUsage.diskPerc * 100) + "%"
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: pywal.foreground
                        }
                    }
                }
            }
            
            // Legend
            Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 3
                Layout.preferredHeight: 60
                radius: 10
                color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.05)
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 16
                    
                    RowLayout {
                        spacing: 6
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 2
                            color: pywal.color2
                        }
                        Text {
                            text: "Good (< 50%)"
                            font.family: "Inter"
                            font.pixelSize: 10
                            color: pywal.foreground
                        }
                    }
                    
                    RowLayout {
                        spacing: 6
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 2
                            color: pywal.color3
                        }
                        Text {
                            text: "Moderate (50-80%)"
                            font.family: "Inter"
                            font.pixelSize: 10
                            color: pywal.foreground
                        }
                    }
                    
                    RowLayout {
                        spacing: 6
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 2
                            color: pywal.color1
                        }
                        Text {
                            text: "High (> 80%)"
                            font.family: "Inter"
                            font.pixelSize: 10
                            color: pywal.foreground
                        }
                    }
                }
                }
            }
        }
    }
}
