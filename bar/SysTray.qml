import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Rectangle {
  implicitHeight: 30
  implicitWidth: trayIcons.implicitWidth + 4
  radius: 6
  color: '#181825'

  RowLayout {
    id: trayIcons
    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: SystemTray.items

      MouseArea {
        id: trayDelegate
        required property SystemTrayItem modelData

        Accessible.role: Accessible.Button
        Accessible.name: modelData.tooltipTitle || modelData.title || "System tray item"

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: (mouse) => {
          if (mouse.button === Qt.LeftButton) {
            modelData.activate()
          } else if (mouse.button === Qt.RightButton) {
            if (modelData.hasMenu) {
              menuAnchor.open()
            }
          } else if (mouse.button === Qt.MiddleButton) {
            modelData.secondaryActivate()
          }
        }

        IconImage {
          anchors.centerIn: parent
          source: trayDelegate.modelData.icon
          implicitSize: 16
        }

        QsMenuAnchor {
          id: menuAnchor
          menu: trayDelegate.modelData.menu

          anchor.window: trayDelegate.QsWindow.window
          anchor.adjustment: PopupAdjustment.Flip
          anchor.onAnchoring: {
            const window = trayDelegate.QsWindow.window;
            const widgetRect = window.contentItem.mapFromItem(
              trayDelegate, 0, trayDelegate.height,
              trayDelegate.width, trayDelegate.height);
            menuAnchor.anchor.rect = widgetRect;
          }
        }
      }
    }
  }
}