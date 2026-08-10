pragma Singleton
import QtQuick

QtObject {
  readonly property color bgBase: "#202020" //or #000000
  readonly property color grayAccent: "#8f8f8f" //or #909090
  readonly property color darkerGrayAccent: "#595554"
  readonly property color redAccent: "#FF2A2A" //or #ff0000
  readonly property color whiteAccent: "white"

  readonly property color textPrimary: "white"

  // === Notification urgency accents ===
  // DANGER intentionally reuses redAccent rather than a separate token —
  // "most severe" naturally aligns with the red identity already used
  // everywhere else in the shell.
  readonly property color nominalAccent: "#3DDBD9"
  readonly property color cautionAccent: "#F2B33D"
  readonly property color dangerAccent: redAccent

}
