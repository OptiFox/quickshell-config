pragma Singleton
import QtQuick

// Shared singleton so the bar (wherever your battery/volume/wifi cluster lives)
// and the ControlPanel window can talk to each other without a direct reference.
//
// Usage from your bar:
//   import "../controlpanel"   // adjust relative path to wherever bar/ sits vs controlpanel/
//   MouseArea {
//       anchors.fill: yourStatusCluster
//       onClicked: ControlPanelState.toggle()
//   }
QtObject {
  property bool visible: false

  function toggle() {
    visible = !visible
  }

  function close() {
    visible = false
  }

  function open() {
    visible = true
  }
}
