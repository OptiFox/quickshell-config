import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

import ".."

PanelWindow {
  visible: root.centerOpen
  anchors { top: true; right: true }
  margins { top: 10; right: 10 }

  implicitWidth: 380
  implicitHeight: centerCol.implicitHeight + 24
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: root.theme.bgBase
    border {
      width: 1
      color: root.theme.accentPrimary
    }

    ColumnLayout {
      id: centerCol
      anchors.fill: parent
      anchors.margins: 10
      spacing: 8

      RowLayout {
        Layout.fillWidth: true

        Text {
          Layout.fillWidth: true
          text: "Notifications"
          color: root.theme.accentPrimary

          font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 18
            bold: true
          }
        }

        Text {
          text: "Clear"
          visible: history.count > 0
          color: root.theme.accentRed
          font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 16
            bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              for (let i = 0; i < history.count; i++) {
                let item = history.get(i)
                if (item.rawNotif) {
                  item.rawNotif.dismiss()
                }
              }

              history.clear()
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Do Not Disturb"
          Layout.fillWidth: true
          color: root.dndEnabled ? root.theme.accentRed : root.theme.textMuted
          
          font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 16; bold: true }
        }

        Text {
          text: root.dndEnabled ? "ON" : "OFF"
          color: root.dndEnabled ? root.theme.accentRed : root.theme.textMuted
          
          font { family: "JetBrainsMono Nerd Font Propo"; pixelSize: 16; bold: true }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dndEnabled = !root.dndEnabled
          }
        }
      }

      ListView {
        id: notificationList
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        Layout.maximumHeight: 600
        clip: true
        spacing: 12

        visible: history.count > 0

        model: history

        delegate: Rectangle {
          width: ListView.view.width
          implicitHeight: cardLayout.implicitHeight + 16

          color: root.theme.bgHover
          border.color: model.urgency === NotificationUrgency.Critical 
            ? root.theme.accentRed : root.theme.textMuted
          border.width: 1

          // Add Timer to automatically clear notif after some time

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
              let actionInvoked = false
              
              // Ensure the raw object and actions still exist
              if (model.rawNotif && model.rawNotif.actions) {
                for (let i = 0; i < model.rawNotif.actions.length; i++) {
                  if (model.rawNotif.actions[i].identifier === "default") {
                    model.rawNotif.actions[i].invoke()
                    actionInvoked = true
                    break
                  }
                }
              }
              
              // Remove the notification from the center after opening it
              if (actionInvoked) {
                history.remove(index)
                root.centerOpen = false // Close the panel
              }
            }
          }

          ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                Layout.fillWidth: true
                text: model.summary
                color: root.theme.textPrimary
                
                font {
                  family: "JetBrainsMono Nerd Font Propo"
                  pixelSize: 16
                  bold: true
                }
                elide: Text.ElideRight
              }

              Text {
                text: model.time
                color: root.theme.textMuted

                font {
                  family: "JetBrainsMono Nerd Font Propo"
                  pixelSize: 14
                }
              }

              Text {
                text: "X"
                color: root.theme.accentRed

                font {
                  family: "JetBrainsMono Nerd Font Propo"
                  pixelSize: 14
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (model.rawNotif) {
                      model.rawNotif.dismiss()
                    }

                    history.remove(index)
                  }
                }
              }
            }

            Image {
              Layout.fillWidth: true
              Layout.preferredHeight: 120

              sourceSize.width: 800
              sourceSize.height: 240

              fillMode: Image.PreserveAspectCrop
              clip: true
              asynchronous: true

              visible: model.imgSource !== ""
              source: model.imgSource
            }

            Text {
              Layout.fillWidth: true
              visible: model.body !== ""
              text: model.body
              color: root.theme.textSecondary

              font {
                family: "JetBrainsMono Nerd Font Mono"
                pixelSize: 14
              }

              wrapMode: Text.WordWrap
            }

            Text {
              visible: model.appName !== ""
              text: model.appName
              color: root.theme.textMuted

              font {
                family: "JetBrainsMono Nerd Font Mono"
                pixelSize: 14
              }
            }
          }
        }
      }
    }
  }
}