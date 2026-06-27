import QtQuick

QtObject {
  readonly property color bgBase: "#1e1e2e"
  readonly property color bgSurface: "#313244"
  readonly property color bgOverlay: "#11111b"
  readonly property color bgHover: "#181825"
  readonly property color bgSelected: "#b4befe"
  readonly property color bgBorder: "#7f849c"

  readonly property color textPrimary: "#cdd6f4"
  readonly property color textSecondary: "#bac2de"
  readonly property color textMuted: "#6c7086"

  readonly property color accentPrimary: "#89b4fa"
  readonly property color accentCyan: "#74c7ec"
  readonly property color accentGreen: "#a6e3a1"
  readonly property color accentOrange: "#fab387"
  readonly property color accentRed: "#f38ba8"
  readonly property color accentPurple: "#c6a0f6"
  readonly property color accentYellow: "#eed49f"

  readonly property color urgencyLow: textMuted
  readonly property color urgencyNormal: accentPrimary
  readonly property color urgencyCritical: accentRed
  readonly property color batteryGood: accentGreen
  readonly property color batteryWarning: accentOrange
  readonly property color batteryCritical: accentRed

}