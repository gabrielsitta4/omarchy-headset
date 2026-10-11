import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "local.headset"
  ipcTarget: "local.headset"

  readonly property string scriptDir: Quickshell.env("HOME") + "/.config/omarchy/bar/scripts"
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/headset"
  readonly property var sidetoneLevels: [
    { label: "Off", value: 0 },
    { label: "Low", value: 32 },
    { label: "Medium", value: 64 },
    { label: "High", value: 128 }
  ]

  property var battery: null

  readonly property bool online: battery !== null
  readonly property bool charging: online && battery.status === "BATTERY_CHARGING"
  readonly property int level: online ? battery.level : -1
  readonly property int sidetone: parseInt(sidetoneFile.text())
  readonly property bool lightOn: lightFile.text().trim() !== "0"

  readonly property var mic: {
    var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (node && node.audio && !node.isSink && !node.isStream && String(node.name).indexOf("G733") !== -1) return node
    }
    return null
  }
  readonly property bool micMuted: mic && mic.audio ? mic.audio.muted : false
  readonly property real micVolume: mic && mic.audio ? mic.audio.volume : 0

  function updateBattery(raw) {
    var next = null
    try { next = JSON.parse(String(raw || "").trim()) } catch (e) {}
    battery = next && typeof next.level === "number" ? next : null
  }

  function timeLeft() {
    var minutes = online ? battery.time_to_empty_min : undefined
    if (charging || typeof minutes !== "number" || minutes < 0) return "—"
    return Math.floor(minutes / 60) + "h " + (minutes % 60) + "m"
  }

  function setHeadset(key, value) {
    if (setProc.running) return
    setProc.command = [scriptDir + "/headset-set", key, String(value)]
    setProc.running = true
  }

  function toggleMicMute() {
    if (mic && mic.audio) mic.audio.muted = !mic.audio.muted
  }

  function setMicVolume(v) {
    if (mic && mic.audio) mic.audio.volume = Math.max(0, Math.min(1, v))
  }

  onOnlineChanged: if (!online) close()

  visible: online
  implicitWidth: online ? button.implicitWidth : 0
  implicitHeight: online ? button.implicitHeight : 0

  PwObjectTracker { objects: root.mic ? [root.mic] : [] }

  FileView {
    id: sidetoneFile
    path: root.stateDir + "/sidetone"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  FileView {
    id: lightFile
    path: root.stateDir + "/light"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  Process {
    id: batteryProc
    command: [root.scriptDir + "/headset-battery"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateBattery(text) }
  }

  Process {
    id: setProc
    onExited: {
      sidetoneFile.reload()
      lightFile.reload()
      pollTimer.restart()
    }
  }

  Timer {
    id: pollTimer
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!batteryProc.running && !setProc.running) batteryProc.running = true
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.charging ? "󰋋 󱐋" : "󰋋 " + root.level + "%"
    fontSize: 12
    horizontalMargin: 7.5
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened && root.online
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroPercent.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: "󰋋"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: heroPercent.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              textFormat: Text.PlainText
              text: "G733"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.charging ? "CHARGING" : "TIME LEFT " + root.timeLeft().toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: heroPercent
            textFormat: Text.PlainText
            text: root.level >= 0 ? root.level + "%" : "—"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Item {
          width: parent.width
          implicitHeight: Style.space(8)

          Rectangle {
            id: barTrack
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
          }

          Rectangle {
            anchors.left: barTrack.left
            anchors.verticalCenter: barTrack.verticalCenter
            height: barTrack.height
            radius: barTrack.radius
            color: root.bar.foreground
            width: Math.max(barTrack.height, barTrack.width * Math.max(0, root.level) / 100)
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "SIDETONE"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            id: sidetoneRow
            width: parent.width
            spacing: Style.space(6)

            readonly property real cellWidth: (width - spacing * (root.sidetoneLevels.length - 1)) / root.sidetoneLevels.length

            Repeater {
              model: root.sidetoneLevels
              Button {
                required property var modelData
                width: sidetoneRow.cellWidth
                text: modelData.label
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: root.sidetone === modelData.value
                onClicked: root.setHeadset("sidetone", modelData.value)
              }
            }
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        Item {
          width: parent.width
          implicitHeight: lightSwitch.implicitHeight

          PanelSectionHeader {
            text: "LIGHTS"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          ToggleSwitch {
            id: lightSwitch
            checked: root.lightOn
            foreground: root.bar.foreground
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onToggled: root.setHeadset("light", root.lightOn ? 0 : 1)
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(10)
          visible: !!root.mic

          Item {
            width: parent.width
            implicitHeight: micSwitch.implicitHeight

            PanelSectionHeader {
              text: "MICROPHONE"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            ToggleSwitch {
              id: micSwitch
              checked: !root.micMuted
              foreground: root.bar.foreground
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              onToggled: root.toggleMicMute()
            }
          }

          Item {
            width: parent.width
            implicitHeight: Math.max(micSlider.implicitHeight, micPercent.implicitHeight)

            PanelSlider {
              id: micSlider
              bar: root.bar
              anchors.left: parent.left
              anchors.right: micPercent.left
              anchors.rightMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              minimum: 0
              maximum: 1
              step: 0.05
              value: root.micVolume
              opacity: root.micMuted ? 0.5 : 1.0
              onMoved: function(v) { root.setMicVolume(v) }
              onRightClicked: root.toggleMicMute()
            }

            Text {
              id: micPercent
              textFormat: Text.PlainText
              text: Math.round((micSlider.dragging ? micSlider.liveValue : root.micVolume) * 100) + "%"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              width: Style.space(40)
              horizontalAlignment: Text.AlignRight
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              opacity: root.micMuted ? 0.5 : 1.0
            }
          }
        }
      }
    }
  }
}
