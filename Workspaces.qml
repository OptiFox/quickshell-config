import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 6

  Repeater {
    model: 9;

    Rectangle {
      id: wsButton
      required property int index

      property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

      implicitWidth: isActive ? label.implicitHeight * 3 : label.implicitWidth + 14
      implicitHeight: 22
      radius: 6

      color: isActive ? '#11111b' : (ws ? '#181825' : "transparent")

      Behavior on implicitWidth {
        PropertyAnimation { duration: 150 }
      }

      Behavior on color {
        ColorAnimation { duration: 150 }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.index + 1
        color: wsButton.isActive ? '#89b4fa' : (wsButton.ws ? '#cdd6f4' : '#6c7086')

        font {
          family: "SF Mono"
          pixelSize: 14
          weight: 500
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })") for lua
        onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
      }
    }
  }
}