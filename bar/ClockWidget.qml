import QtQuick

import ".."

Text {
  text: Time.time

  property var theme: DefaultTheme {}

  color: theme.accentPrimary

  font {
    family: "SF Mono"
    letterSpacing: -1
    pixelSize: 15
    weight: 600
  }
}