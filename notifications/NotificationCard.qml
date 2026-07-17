import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

import ".."

PanelWindow {
  anchors { top: true; right: true }
  margins { top: 10; right: 10 }

  implicitWidth: 380
  implicitHeight: Math.max(1, column.implicitHeight)
  color: "transparent"

  readonly property real timeout: 5000

  ColumnLayout {
    id: column
    width: parent.width
    spacing: 10

    Repeater {
      model: server.trackedNotifications
      delegate: Rectangle {
        id: card
        required property var modelData

        Timer {
          running: card.modelData.urgency !== NotificationUrgency.Critical
          interval: timeout
          onTriggered: card.modelData.dismiss()
        }

        Layout.fillWidth: true
        Layout.preferredHeight: layout.implicitHeight + 20
        color: root.theme.bgBase
        border {
          width: 2
          color: modelData.urgency === NotificationUrgency.Critical 
            ? root.theme.accentRed : root.theme.accentPurple
        }

        ColumnLayout {
          id: layout
          anchors.fill: parent
          anchors.margins: 10
          spacing: 10

          Image {
            Layout.fillWidth: true
            Layout.preferredHeight: 120

            sourceSize.width: 800
            sourceSize.height: 240

            fillMode: Image.PreserveAspectCrop
            clip: true
            asynchronous: true

            visible: source.toString() !== ""
            source: card.modelData.image || card.modelData.appIcon || ""
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              Layout.fillWidth: true
              text: card.modelData.summary
              color: root.theme.textPrimary

              font {
                family: "JetBrainsMono Nerd Font Propo"
                pixelSize: 16
                bold: true
              }

              elide: Text.ElideRight
            }


            Text {
              Layout.fillWidth: true
              visible: text !== ""
              text: card.modelData.body
              color: root.theme.textSecondary

              font {
                family: "JetBrainsMono Nerd Font Propo"
                pixelSize: 14
              }

              wrapMode: Text.WordWrap
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: card.modelData.dismiss()
        }
      }
    }
  }
}