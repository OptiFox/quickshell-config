import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import ".."

RowLayout {
  property string activeWindow: "Window"
  property var theme: DefaultTheme {}

  Process {
    id: windowProc

    command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
    stdout: SplitParser {
      onRead: data => {
      if (data && data.trim()) {
        activeWindow = data.trim()
      }
    }
  }

    Component.onCompleted: running = true
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      windowProc.running = true
    }
  }

  Text {
    text: activeWindow
    color: theme.textPrimary

    font {
      family: "SF Pro Display"
      pixelSize: 16
      bold: true
    }

    Layout.fillWidth: true
    Layout.maximumWidth: 400

    elide: Text.ElideRight
    maximumLineCount: 1
  }
}


