import QtQuick
import "../../../components"

// Control Center / dashboard media card: thin wrapper around the shared NowPlayingCard.
NowPlayingCard {
    required property var mpris
    property var pywal // kept for callers; the card reads the palette itself

    player: mpris?.active ?? null
    active: visible
    visible: player !== null
}
