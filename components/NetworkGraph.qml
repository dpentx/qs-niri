// NetworkGraph.qml - Mini line graph for network traffic
// Enhanced with Material 3 styling, antialiasing, and gradient fills
import QtQuick 6.10
import "../services" as QsServices

Canvas {
    id: canvas
    
    property var dataPoints: []  // Array of {download, upload} values
    property int maxPoints: 30   // 30 points = 60 seconds at 2s interval
    
    // Use Pywal semantic colors by default
    readonly property var pywal: QsServices.Pywal
    property color downloadColor: pywal.success
    property color uploadColor: pywal.info
    property color gridColor: Qt.rgba(pywal.outline.r, pywal.outline.g, pywal.outline.b, 0.2)
    property color backgroundColor: "transparent"
    
    property real maxValue: 1024 * 1024  // 1 MB/s default max
    
    // Visual options
    property bool showGrid: true
    property bool showGradientFill: true
    property int gridLines: 3
    property real lineWidth: 2
    property real gradientOpacity: 0.15
    
    // Enable antialiasing
    antialiasing: true
    renderStrategy: Canvas.Threaded
    
    onDataPointsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    
    onPaint: {
        const ctx = getContext("2d")
        const w = width
        const h = height
        
        // Clear canvas
        ctx.clearRect(0, 0, w, h)
        
        // Background
        if (backgroundColor !== "transparent") {
            ctx.fillStyle = backgroundColor
            ctx.fillRect(0, 0, w, h)
        }
        
        // Draw grid lines
        if (showGrid && gridLines > 0) {
            ctx.beginPath()
            ctx.strokeStyle = gridColor
            ctx.lineWidth = 1
            ctx.setLineDash([2, 4])
            
            for (let i = 1; i <= gridLines; i++) {
                const y = (h / (gridLines + 1)) * i
                ctx.moveTo(0, y)
                ctx.lineTo(w, y)
            }
            ctx.stroke()
            ctx.setLineDash([])
        }
        
        if (dataPoints.length < 2) return
        
        // Calculate max for scaling with some headroom
        let localMax = maxValue
        dataPoints.forEach(point => {
            localMax = Math.max(localMax, point.download * 1.1, point.upload * 1.1)
        })
        
        const pointSpacing = w / (maxPoints - 1)
        const scale = (h - 4) / localMax  // 4px padding
        const startIndex = Math.max(0, maxPoints - dataPoints.length)
        
        // Helper function to draw line with optional gradient fill
        function drawLine(dataKey, color) {
            const points = []
            
            // Collect points
            dataPoints.forEach((point, i) => {
                const x = (startIndex + i) * pointSpacing
                const y = h - 2 - (point[dataKey] * scale)
                points.push({x, y})
            })
            
            if (points.length < 2) return
            
            // Draw gradient fill under the line
            if (showGradientFill) {
                ctx.beginPath()
                ctx.moveTo(points[0].x, h)
                
                points.forEach(p => ctx.lineTo(p.x, p.y))
                
                ctx.lineTo(points[points.length - 1].x, h)
                ctx.closePath()
                
                const gradient = ctx.createLinearGradient(0, 0, 0, h)
                gradient.addColorStop(0, Qt.rgba(color.r, color.g, color.b, gradientOpacity))
                gradient.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0))
                ctx.fillStyle = gradient
                ctx.fill()
            }
            
            // Draw the line with smooth curves
            ctx.beginPath()
            ctx.strokeStyle = color
            ctx.lineWidth = lineWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            
            // Use bezier curves for smooth lines
            ctx.moveTo(points[0].x, points[0].y)
            
            for (let i = 1; i < points.length; i++) {
                const prev = points[i - 1]
                const curr = points[i]
                const next = points[Math.min(i + 1, points.length - 1)]
                
                // Calculate control points for smooth curve
                const cpx = (prev.x + curr.x) / 2
                const cpy1 = prev.y
                const cpy2 = curr.y
                
                ctx.quadraticCurveTo(cpx, cpy1, curr.x, curr.y)
            }
            
            ctx.stroke()
        }
        
        // Draw upload first (underneath)
        drawLine("upload", uploadColor)
        
        // Draw download on top
        drawLine("download", downloadColor)
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
