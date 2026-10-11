import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../services" as QsServices
import "../config" as QsConfig

// OneUI-style settings section header. Modeled on the decoded
// preference_category_material.xml (16dp top margin, muted secondary
// text color, no background).
Text {
    id: root

    readonly property var pywal: QsServices.Pywal

    Layout.fillWidth: true
    Layout.topMargin: 16
    Layout.bottomMargin: 2
    Layout.leftMargin: 4

    font.family: "OneUI Sans"
    font.pixelSize: QsConfig.Appearance.fontSize.l
    font.weight: Font.DemiBold
    color: pywal.onSurfaceMuted
}
