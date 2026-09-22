import "effects"
import QtQuick 6.10

// Reusable "standard" transition preset. Previously pointed at
// Appearance.anim, a broken/duplicated token path (see config/Appearance.qml)
// and was never actually instantiated anywhere in the shell. Now wired to
// OneUIMotion, the shell's single motion-token source, so it's correct if
// something starts using it.
NumberAnimation {
    duration: OneUIMotion.medium1
    easing.type: Easing.BezierSpline
    easing.bezierCurve: OneUIMotion.standard
}
