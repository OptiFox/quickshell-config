import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  property var sink: Pipewire.defaultAudioSink
  
  readonly property bool ready: sink && sink.ready
  readonly property bool muted: ready && sink.audio.muted
  readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

  readonly property string icon: {
    if (!ready || muted) return String.fromCodePoint(0xF0581)

    if (vol === 0) return String.fromCodePoint(0xF0581)
    if (vol < 34) return String.fromCodePoint(0xF057F)
    if (vol < 67) return String.fromCodePoint(0xF0580)

    return String.fromCodePoint(0xF057E)
  }

  Text {
    text: root.icon
    color: '#f9e2af'

    font {
      family: "JetBrainsMono Nerd Font Propo"
      pixelSize: 16
    }
  }

  Text {
    text: {
      if (!root.ready) return "-"
      if (root.muted) return "Muted"
      return root.vol + "%"
    }

    color: root.muted ? '#6c7086' : '#cdd6f4'

    font {
      family: "SF Pro Display"
      weight: 500
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted

      onWheel: (wheel) => {
        if (!sink || !sink.audio) return
        const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
        sink.audio.volume = Math.max(0, Math.min(1.0, sink.audio.volume + delta))
      }
    }
  }

  PwObjectTracker {
    objects: [root.sink]
  }
}