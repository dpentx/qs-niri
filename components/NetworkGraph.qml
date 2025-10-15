// NetworkGraph.qml - Mini line graph for network traffic
import QtQuick 6.10

Canvas {
    id: canvas
    
    property var dataPoints: []  // Array of {download, upload} values
    property int maxPoints: 30   // 30 points = 60 seconds at 2s interval
    property color downloadColor: "#a6e3a1"
    property color uploadColor: "#89b4fa"
    property real maxValue: 1024 * 1024  // 1 MB/s default max
    
    onDataPointsChanged: requestPaint()
    
    onPaint: {
        const ctx = getContext("2d")
        const w = width
        const h = height
        
        // Clear canvas
        ctx.clearRect(0, 0, w, h)
        
        if (dataPoints.length < 2) return
        
        // Calculate max for scaling
        let localMax = maxValue
        dataPoints.forEach(point => {
            localMax = Math.max(localMax, point.download, point.upload)
        })
        
        const pointSpacing = w / (maxPoints - 1)
        const scale = h / localMax
        
        // Draw download line (green)
        ctx.beginPath()
        ctx.strokeStyle = downloadColor
        ctx.lineWidth = 2
        ctx.lineJoin = "round"
        
        dataPoints.forEach((point, i) => {
            const x = i * pointSpacing
            const y = h - (point.download * scale)
            
            if (i === 0) {
                ctx.moveTo(x, y)
            } else {
                ctx.lineTo(x, y)
            }
        })
        ctx.stroke()
        
        // Draw upload line (blue)
        ctx.beginPath()
        ctx.strokeStyle = uploadColor
        ctx.lineWidth = 2
        ctx.lineJoin = "round"
        
        dataPoints.forEach((point, i) => {
            const x = i * pointSpacing
            const y = h - (point.upload * scale)
            
            if (i === 0) {
                ctx.moveTo(x, y)
            } else {
                ctx.lineTo(x, y)
            }
        })
        ctx.stroke()
    }
    
    function addDataPoint(download, upload) {
        dataPoints.push({download: download, upload: upload})
        if (dataPoints.length > maxPoints) {
            dataPoints.shift()  // Remove oldest point
        }
        dataPointsChanged()
    }
    
    function clear() {
        dataPoints = []
        requestPaint()
    }
}
