# 1366x768 + Performans + Yeni Özellikler

Bu klasördeki dosyaları kendi `~/.config/quickshell/` içine, aynı yol
yapısıyla kopyala (üzerine yaz). Ayrıca aşağıdaki KÜÇÜK düzenlemeleri
elle mevcut dosyalarına uygulaman gerekiyor (tam dosya vermek anlamsız
olacak kadar büyükler).

---

## 1) config/Config.qml — boyutlar küçültüldü

`dashboard` ve `controlCenter` bloklarını şu şekilde değiştir:

```qml
readonly property var dashboard: ({
    enabled: data.dashboard?.enabled ?? true,
    width: data.dashboard?.width ?? 620,
    height: data.dashboard?.height ?? 460,
    margin: data.dashboard?.margin ?? 12
})

readonly property var controlCenter: ({
    width: 340,
    maxHeight: 600,
    padding: 14,
    spacing: 10,
    margin: 4,
    cornerRadius: 20
})
```

---

## 2) modules/controlcenter/ControlCenterWindow.qml

`implicitWidth` ve `implicitHeight` satırlarını bul, değiştir:

```qml
implicitWidth: 340
implicitHeight: Math.min(620, screen.height - 24)
```

---

## 3) config/BarConfig.qml

`workspaces.count` değerini düşür (1366px'te 8 workspace pill'i sığmaz):

```qml
property int count: 5
```

---

## 4) shell.json

Launcher genişliğini düşür:

```json
"launcher": {
  "enabled": true,
  "width": 480,
  ...
}
```

---

## 5) services/Audio.qml — polling'i yavaşlat

```qml
Timer {
    interval: 1000   // 250 -> 1000
    running: true
    repeat: true
    onTriggered: {
        if (!getSink.running) getSink.running = true
        if (!getSource.running) getSource.running = true
    }
}
```

---

## 6) components/AuroraSurface.qml — shadow'ları hafiflet

`Elevation` bloğunu bul ve seviyeleri düşür (Niri'de shadow rendering CPU
yiyor):

```qml
Elevation {
    level: root.highlighted ? root.elevation : (root.hovered ? root.elevation : Math.max(0, root.elevation - 2))
    target: surface
    radius: surface.radius
    shadowColor: Qt.rgba(root.shadowColor.r, root.shadowColor.g, root.shadowColor.b, root.highlighted ? 0.18 : 0.12)
}
```

İstersen tamamen kapatmak için `Bar.qml` içindeki tüm `elevation: 3/4`
değerlerini `elevation: 1` yap.

---

## 7) modules/controlcenter/components/MediaCard.qml — blur'u düşür

```qml
MultiEffect {
    anchors.fill: parent
    source: bgImage
    blurEnabled: true
    blur: 1.0
    blurMax: 16        // 48 -> 16
    saturation: 0.4
    brightness: -0.35
    ...
}
```

---

## 8) modules/bar/components/Workspaces.qml — TAM DOSYA DEĞİŞTİ

Bu repodaki dosyanın üzerine yazılacak şekilde verildi (event-stream
tabanlı, 800ms polling yerine niri'nin canlı event stream'ini dinler —
en büyük CPU kazancı budur).

---

## YENİ EKLENEN DOSYALAR

### modules/bar/components/CapsLock.qml
Caps Lock aktifken bar'da küçük bir gösterge çıkar.

### modules/bar/components/KeyboardLayout.qml
Niri'nin aktif klavye düzenini (örn. "TR"/"US") gösterir, tıklayınca
`niri msg action switch-layout` ile değiştirir.

### modules/controlcenter/components/FocusTimer.qml
Basit pomodoro/focus sayacı — Control Center'a eklenebilir. Mevcut
`services/Settings.qml` içindeki `focusModeEnabled` / `focusModeMinutesLeft`
ile entegre.

### services/DiskIO.qml
Disk okuma/yazma hızını (MB/s) takip eden servis. `NetworkGraph.qml`
component'i ile aynı şekilde grafik çizdirilebilir.

`services/qmldir` dosyasına şu satırı ekle:

```
singleton DiskIO DiskIO.qml
```

---

## TRAY İKONLARI

Sistem tepsisi zaten `modules/bar/components/SystemTray.qml` dosyasında
mevcut ve `Bar.qml` içinde `powerPill`e bağlı — ama küçük ikonlar
stilsiz/çıplak duruyordu. Yenisi: hover efekti, arkaplan, ve
24px yerine 22px ikon boyutuyla pille daha uyumlu. Aşağıdaki dosyayla
değiştir.

---

## Entegrasyon — Bar.qml'e yeni widget'ları eklemek

`modules/bar/Bar.qml` içinde `connectivityContent` Row'una (Network +
Bluetooth yanına) KeyboardLayout ve CapsLock eklemek için, ilgili Row
içine şu Loader'ları ekle:

```qml
Loader {
    anchors.verticalCenter: parent.verticalCenter
    asynchronous: true
    source: "components/KeyboardLayout.qml"
}

Loader {
    anchors.verticalCenter: parent.verticalCenter
    asynchronous: true
    source: "components/CapsLock.qml"
}
```

FocusTimer'ı Control Center'a eklemek için
`ControlCenterWindow.qml` içindeki `contentColumn`'a (Sliders bölümünden
sonra) ekle:

```qml
FocusTimer {
    Layout.fillWidth: true
    pywal: root.pywal
}
```

ve `modules/controlcenter/components/qmldir`'e şu satırı ekle:

```
FocusTimer 1.0 FocusTimer.qml
```
