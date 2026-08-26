import QtQuick 6.10

// OneUI SVG icon — plain, dependency-free rendering.
//
// Icons are produced by scripts/vector-to-svg.py as solid white shapes.
// State (active/inactive) is conveyed via opacity rather than GPU
// recoloring: the decoded OneUI token qs_tile_icon_off_tint_color is
// #80fcfcff — literally 50%-alpha white — so dimming via opacity IS
// OneUI's own convention here, not an approximation. This also means
// zero extra QML modules (no MultiEffect/ColorOverlay), so it can't
// fail to import.
//
// Usage:
//   OneUIIcon {
//       source: "../../../assets/icons/oneui/sec_ic_wifi_signal_3.svg"
//       size: 20
//       opacity: isActive ? 1.0 : 0.5
//   }
Image {
    id: root

    property int size: 20

    implicitWidth: size
    implicitHeight: size
    sourceSize.width: size * 2  // 2x for crisp scaling on hidpi
    sourceSize.height: size * 2
    fillMode: Image.PreserveAspectFit
    smooth: true

    Behavior on opacity { NumberAnimation { duration: 150 } }
}
