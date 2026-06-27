import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import ".."

RowLayout {
  spacing: 6

  Repeater {
    model: Hyprland.workspaces

    Rectangle {
      id: wsButton

      property var theme: DefaultTheme {}
      
      required property var modelData
      property bool urgentBlink: false

      Accessible.role: Accessible.Button
      Accessible.name: "Workspace " + modelData.id + (modelData.focused ? ", active" : "") + (modelData.urgent ? ", urgent" : "")

      implicitWidth: modelData.focused ? label.implicitHeight * 3 : label.implicitWidth + 14
      implicitHeight: 22
      radius: 6

      color: modelData.focused ? theme.bgOverlay 
           : modelData.urgent && urgentBlink ? theme.accentRed : theme.bgHover

      Behavior on implicitWidth {
        PropertyAnimation { duration: 150 }
      }

      Behavior on color {
        ColorAnimation { duration: 150 }
      }

      SequentialAnimation {
        loops: Animation.Infinite
        running: wsButton.modelData.urgent && !wsButton.modelData.focused

        PropertyAction { target: wsButton; property: "urgentBlink"; value: true }
        PauseAnimation { duration: 500 }
        PropertyAction { target: wsButton; property: "urgentBlink"; value: false }
        PauseAnimation { duration: 500 }

        onStopped: wsButton.urgentBlink = false
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.modelData.id
        color: wsButton.modelData.focused ? theme.accentPrimary :  theme.textPrimary

        font {
          family: "SF Mono"
          pixelSize: 14
          weight: 500
          bold: wsButton.modelData.focused
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: wsButton.modelData.activate()
      }
    }
  }
}
