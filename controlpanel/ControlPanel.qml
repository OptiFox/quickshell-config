import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Networking
import ".."

// Drop this folder ("controlpanel") next to your existing "bar" and
// "notifications" folders, add `import "controlpanel"` + `ControlPanel{}`
// to shell.qml (see the chat message for the exact diff), and wrap your
// battery/volume/wifi cluster in the bar with a MouseArea that calls
// ControlPanelState.toggle().
//
// Assumptions worth knowing about, in case something needs tweaking:
//  - `topMargin` below is a guess at your bar height (44px). Adjust it to
//    match bar/Bar.qml's implicitHeight so the panel sits flush under it.
//  - UPowerDevice.percentage is assumed to already be on a 0-100 scale
//    (matches upower's own DBus convention). If your battery % looks 100x
//    too small, change `battery.percentage` to `battery.percentage * 100`.
//  - brightnessctl needs the user to be in the `video` group (or a udev
//    rule) to set brightness without sudo on most distros.

Scope {
  id: root

  property QtObject theme: DefaultTheme {}
  // property int topMargin: 44
  property int panelWidth: 380

  // -- shared, non-visual bindings (kept outside Variants so they exist once) --

  PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var battery: UPower.displayDevice

  // Find the Wi-Fi device among the network devices. Most machines have
  // exactly one, so we just grab the first one we see.
  property var wifiDevice: null
  Repeater {
    model: Networking.devices
    delegate: Item {
      required property var modelData
      Component.onCompleted: {
        if (modelData.type === DeviceType.Wifi && root.wifiDevice === null)
          root.wifiDevice = modelData
      }
    }
  }

  // Which wifi network (if any) is currently prompting for a password
  property var pendingPskNetwork: null

  function fmtTime(seconds) {
    if (!seconds || seconds <= 0) return ""
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    if (h > 0) return h + "h " + m + "m"
    return m + "m"
  }

  // -- reusable bits --

  component SectionLabel: Text {
    color: root.theme.textMuted
    font.pixelSize: 11
    font.bold: true
  }

  component SliderBar: Item {
    id: sliderRoot
    property real value: 0 // 0..1
    property color fillColor: root.theme.accentPrimary
    signal moved(real value)
    implicitHeight: 24

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 6
      radius: 3
      color: root.theme.bgSurface
    }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width * Math.max(0, Math.min(1, sliderRoot.value))
      height: 6
      radius: 3
      color: sliderRoot.fillColor
    }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      x: parent.width * Math.max(0, Math.min(1, sliderRoot.value)) - width / 2
      width: 14
      height: 14
      radius: 7
      color: root.theme.textPrimary
    }
    MouseArea {
      anchors.fill: parent
      function apply(mx) {
          const v = Math.max(0, Math.min(1, mx / width))
          sliderRoot.value = v
          sliderRoot.moved(v)
      }
      onPressed: (mouse) => apply(mouse.x)
      onPositionChanged: (mouse) => { if (pressed) apply(mouse.x) }
    }
  }

  component ToggleTile: Rectangle {
    id: tile
    property string label: ""
    property string subtitle: ""
    property bool on: false
    signal toggled()
    signal expandRequested()

    radius: 6
    color: on ? root.theme.accentPrimary : root.theme.bgSurface
    implicitHeight: 60

    Column {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 12
      spacing: 2
      Text {
        text: tile.label
        color: tile.on ? root.theme.bgBase : root.theme.textPrimary
        font.bold: true
        font.pixelSize: 13
      }
      Text {
        text: tile.subtitle
        color: tile.on ? root.theme.bgBase : root.theme.textMuted
        font.pixelSize: 11
      }
    }

    Text {
      text: "\u203a" // chevron, tap to expand the list below
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.rightMargin: 12
      color: tile.on ? root.theme.bgBase : root.theme.textMuted
      font.pixelSize: 16
      rotation: expandArea.containsMouse ? 90 : 0

      MouseArea {
        id: expandArea
        anchors.fill: parent
        anchors.margins: -10
        hoverEnabled: true
        onClicked: tile.expandRequested()
      }
    }

    MouseArea {
      anchors.fill: parent
      anchors.rightMargin: 36 // leave room for the chevron hit area
      onClicked: tile.toggled()
    }
  }

  // -- the actual window --

  PanelWindow {
    id: panelWin
    visible: ControlPanelState.visible
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    // exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      right: true
    }
    margins {
      top: 10
      right: 10
    }

    implicitWidth: root.panelWidth
    implicitHeight: bg.implicitHeight

    onVisibleChanged: {
      if (visible) {
        brightnessQuery.running = true
      } else {
        wifiExpanded = false
        bluetoothExpanded = false
        root.pendingPskNetwork = null
      }
    }

    property bool wifiExpanded: false
    property bool bluetoothExpanded: false

    Rectangle {
      id: bg
      width: parent.width
      implicitHeight: content.implicitHeight + 24
      // radius: 16
      color: root.theme.bgBase
      border.width: 1
      border.color: root.theme.bgBorder

      Column {
        id: content
        width: parent.width - 24
        x: 12
        y: 12
        spacing: 14

        // header
        Row {
          width: parent.width
          Text {
            text: "Control Panel"
            color: root.theme.textPrimary
            font.family: "JetBrainsMono Nerd Font Propo"
            font.bold: true
            font.pixelSize: 15
          }
          Item { width: parent.width - 130; height: 1 }
          Text {
            text: "\u2715"
            color: root.theme.textMuted
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 15
            MouseArea {
              anchors.fill: parent
              anchors.margins: -8
              onClicked: ControlPanelState.close()
            }
          }
        }

        // wifi + bluetooth tiles
        Row {
          width: parent.width
          spacing: 10

          ToggleTile {
            width: (parent.width - 10) / 2
            label: "Wi-Fi"
            subtitle: on ? "On" : "Off"
            on: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            onExpandRequested: {
              panelWin.wifiExpanded = !panelWin.wifiExpanded
              if (root.wifiDevice)
                root.wifiDevice.scannerEnabled = panelWin.wifiExpanded
            }
          }
          ToggleTile {
            width: (parent.width - 10) / 2
            label: "Bluetooth"
            subtitle: on ? "On" : "Off"
            on: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
            onToggled: {
              if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
            onExpandRequested: panelWin.bluetoothExpanded = !panelWin.bluetoothExpanded
          }
        }

        // wifi network list
        Column {
          width: parent.width
          spacing: 4
          visible: panelWin.wifiExpanded
          Repeater {
            model: root.wifiDevice ? root.wifiDevice.networks : null
            delegate: Column {
              required property var modelData
              width: parent.width
              spacing: 2

              Rectangle {
                width: parent.width
                height: 36
                radius: 6
                color: modelData.connected ? root.theme.bgHover : "transparent"
                Row {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 8
                  Text {
                    text: modelData.connected ? "\u25cf" : "\u25cb"
                    color: modelData.connected ? root.theme.accentGreen : root.theme.textMuted
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                  }
                  Text {
                    text: modelData.name
                    color: root.theme.textPrimary
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    if (modelData.connected) return
                    root.pendingPskNetwork = null
                    modelData.connect()
                  }
                }
                Connections {
                  target: modelData
                  function onConnectionFailed(reason) {
                    if (reason === ConnectionFailReason.NoSecrets)
                      root.pendingPskNetwork = modelData
                  }
                }
              }

              // inline password prompt for secured networks
              Row {
                width: parent.width
                visible: root.pendingPskNetwork === modelData
                spacing: 6
                Rectangle {
                  width: parent.width - 70
                  height: 30
                  radius: 6
                  color: root.theme.bgSurface
                  TextInput {
                    id: pskField
                    anchors.fill: parent
                    anchors.margins: 6
                    color: root.theme.textPrimary
                    echoMode: TextInput.Password
                    focus: root.pendingPskNetwork === modelData
                    onAccepted: {
                      modelData.connectWithPsk(pskField.text)
                      root.pendingPskNetwork = null
                      pskField.text = ""
                    }
                  }
                }
                Rectangle {
                  width: 58
                  height: 30
                  radius: 6
                  color: root.theme.accentPrimary
                  Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                    color: root.theme.bgBase
                  }
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      modelData.connectWithPsk(pskField.text)
                      root.pendingPskNetwork = null
                      pskField.text = ""
                    }
                  }
                }
              }
            }
          }
        }

        // bluetooth device list
        Column {
          width: parent.width
          spacing: 4
          visible: panelWin.bluetoothExpanded
          Repeater {
            model: Bluetooth.devices
            delegate: Rectangle {
              required property var modelData
              width: parent.width
              height: 36
              radius: 6
              color: modelData.connected ? root.theme.bgHover : "transparent"
              Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                  text: modelData.connected ? "\u25cf" : "\u25cb"
                  color: modelData.connected ? root.theme.accentGreen : root.theme.textMuted
                  font.family: "JetBrainsMono Nerd Font Propo"
                  font.pixelSize: 10
                }
                Text {
                  text: modelData.name
                  color: root.theme.textPrimary
                  font.family: "JetBrainsMono Nerd Font Propo"
                  font.pixelSize: 12
                }
              }
              MouseArea {
                anchors.fill: parent
                onClicked: modelData.connected = !modelData.connected
              }
            }
          }
        }

        // volume
        Column {
          width: parent.width
          spacing: 6
          SectionLabel { text: "VOLUME"; font.family: "JetBrainsMono Nerd Font Propo" }
          Row {
            width: parent.width
            spacing: 10
            Text {
              text: root.sink && root.sink.audio && root.sink.audio.muted ? 
                String.fromCodePoint(0xF0581) : String.fromCodePoint(0xF057E)
              color: root.theme.textPrimary
              font.family: "JetBrainsMono Nerd Font Propo"
              font.pixelSize: 16
              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
              }
            }
            SliderBar {
              width: parent.width - 60
              value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
              onMoved: (v) => { if (root.sink && root.sink.audio) root.sink.audio.volume = v }
            }
            Text {
              text: root.sink && root.sink.audio ? Math.round(root.sink.audio.volume * 100) + "%" : "--"
              color: root.theme.textMuted
              font.family: "JetBrainsMono Nerd Font Propo"
              font.pixelSize: 11
            }
          }
        }

        // brightness
        Column {
          width: parent.width
          spacing: 6
          SectionLabel { text: "BRIGHTNESS"; font.family: "JetBrainsMono Nerd Font Propo" }
          Row {
            width: parent.width
            spacing: 10
            Text {
              text: "\u2600"
              color: root.theme.textPrimary
              font.family: "JetBrainsMono Nerd Font Propo"
              font.pixelSize: 16
            }
            SliderBar {
              id: brightnessSlider
              width: parent.width - 60
              fillColor: root.theme.accentOrange
              onMoved: (v) => {
                brightnessSet.command = ["brightnessctl", "set", Math.round(v * 100) + "%"]
                brightnessSet.running = true
              }
            }
            Text {
              text: Math.round(brightnessSlider.value * 100) + "%"
              color: root.theme.textMuted
              font.family: "JetBrainsMono Nerd Font Propo"
              font.pixelSize: 11
            }
          }
        }

        // battery
        Row {
          width: parent.width
          spacing: 10
          visible: root.battery && root.battery.isLaptopBattery
          Text {
            text: root.battery && root.battery.state === UPowerDeviceState.Charging ? 
              String.fromCodePoint(0xF0084) : String.fromCodePoint(0xF0079)
            color: root.theme.textPrimary
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 16
          }
          Text {
            text: root.battery ? Math.round(root.battery.percentage * 100) + "%" : "--"
            color: root.theme.textPrimary
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
          }
          Text {
            text: {
              if (!root.battery) return ""
              const charging = root.battery.state === UPowerDeviceState.Charging
              const t = charging ? root.battery.timeToFull : root.battery.timeToEmpty
              const label = root.fmtTime(t)
              return label ? (charging ? "until full \u00b7 " + label : label + " left") : ""
            }
            color: root.theme.textMuted
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
          }
        }
      }
    }

    Process {
      id: brightnessQuery
      command: ["brightnessctl", "-m"]
      stdout: StdioCollector {
        onStreamFinished: {
          const parts = text.trim().split(",")
          if (parts.length >= 4) {
            const pct = parseInt(parts[3].replace("%", ""))
            if (!isNaN(pct)) brightnessSlider.value = pct / 100
          }
        }
      }
    }

    Process {
      id: brightnessSet
    }
  }
}