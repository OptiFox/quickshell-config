import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
  property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null

  readonly property real signal: active ? active.signalStrength : 0

  readonly property string icon: {
    if (!Networking.wifiEnabled) return String.fromCodePoint(0xF05AA)
    if (!active) return String.fromCodePoint(0xF092D)

    let tier = signal >= 0.75 ? 4
             : signal >= 0.50 ? 3
             : signal >= 0.25 ? 2
             : 1

    return String.fromCodePoint(0xF091F + (tier - 1) * 3)
  }

  Text {
    text: root.icon
    color: Networking.wifiEnabled ? '#cba6f7' : '#6c7086'

    font {
      family: "JetBrainsMono Nerd Font Propo"
      pixelSize: 13
    }
  }

  Text {
    text:  {
      if (!Networking.wifiEnabled) return "Off"
      if (!root.active) return "Disconnected"

      return root.active.name
    }

    color: '#cdd6f4'

    font {
      family: "SF Pro Display"
      weight: 500
    }
  }
}