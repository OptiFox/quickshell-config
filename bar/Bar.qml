import Quickshell
import QtQuick
import QtQuick.Layouts

import ".."

Scope {
  Variants {
    id: root
    model: Quickshell.screens

    property var theme: DefaultTheme {}

    PanelWindow {
      color: root.theme.bgBase

      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 40

      Workspaces {
        anchors.centerIn: parent
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14  
        spacing: 8

        WindowTitle {}

        Item {
          Layout.fillWidth: true
        }

        SysTray {}

        Separator {}

        RowLayout {
          spacing: 8

          Battery {}
          Volume {}
          Network {}
        }

        Separator {}

        ClockWidget {}
      }
    }
  }
}