import QtQuick

Canvas {
    id: root
    property var points: []
    property color strokeColor: "#4da3ff"
    property real lineWidth: 1.5

    renderTarget: Canvas.FramebufferObject
    renderStrategy: Canvas.Cooperative

    onPointsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        if (!points || points.length < 2) return;

        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = lineWidth;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();

        var n = points.length;
        var step = width / (n - 1);
        for (var i = 0; i < n; i++) {
            var v = Math.max(2, Math.min(98, Number(points[i]) || 0));
            var x = i * step;
            var y = height - (v / 100.0) * (height - 4) - 2;
            if (i === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }
        ctx.stroke();
    }
}
