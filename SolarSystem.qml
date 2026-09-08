import QtQuick
import qs.Commons

Item {
  id: root

  property var snapshot: ({ timeMs: 0, jd: 0, utcDate: "", utcTime: "", bodies: [] })
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  implicitWidth: Style.space(340)
  implicitHeight: header.height + width

  readonly property color sunColor: "#f0c419"
  readonly property color orbitColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
  readonly property color titleColor: foreground
  readonly property color dimColor: Color.muted

  readonly property string utcDate: {
    var s = snapshot
    return (s && s.utcDate != null) ? String(s.utcDate) : ""
  }
  readonly property string utcTime: {
    var s = snapshot
    return (s && s.utcTime != null) ? String(s.utcTime) : ""
  }
  readonly property int bodyCount: {
    var s = snapshot
    if (!s) return 0
    var b = s.bodies
    if (!b) return 0
    var n = b.length
    return (typeof n === "number" && n > 0) ? n : 0
  }

  property var stars: []

  Component.onCompleted: {
    var a = 0x5E1A
    function rnd() {
      a |= 0
      a = a + 0x6D2B79F5 | 0
      var t = Math.imul(a ^ a >>> 15, 1 | a)
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t
      return ((t ^ t >>> 14) >>> 0) / 4294967296
    }
    var list = []
    var guard = 0
    while (list.length < 110 && guard < 900) {
      guard++
      var x = rnd()
      var y = rnd()
      var dx = x - 0.5
      var dy = y - 0.5
      if (dx * dx + dy * dy < 0.012)
        continue
      var bright = rnd()
      list.push({
        x: x,
        y: y,
        a: 0.14 + bright * 0.62,
        s: bright > 0.82 ? 2 : 1
      })
    }
    root.stars = list
  }

  onBodyCountChanged: if (map.hoverIndex >= bodyCount) map.hoverIndex = -1

  Item {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: Style.space(26)

    Text {
      anchors.left: parent.left
      anchors.right: timeBox.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: "SOLAR SYSTEM"
      color: root.titleColor
      elide: Text.ElideRight
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
      font.letterSpacing: 1.4
    }

    Item {
      id: timeBox
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(dateText.implicitWidth, timeText.implicitWidth)
      height: dateText.implicitHeight + timeText.implicitHeight

      Text {
        id: dateText
        anchors.top: parent.top
        anchors.right: parent.right
        textFormat: Text.PlainText
        text: root.utcDate
        color: root.dimColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        id: timeText
        anchors.top: dateText.bottom
        anchors.right: parent.right
        textFormat: Text.PlainText
        text: root.utcTime
        color: root.dimColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  Item {
    id: map
    anchors.top: header.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.width
    height: width
    clip: true

    readonly property real sunDiam: Style.space(28)
    // Leave room for Neptune's disk so the outer orbit is not clipped.
    readonly property real outerClear: Style.space(14)
    // equal-spaced rings: r(i) = innerR + i * gap, not true/log scale
    readonly property real innerR: sunDiam * 0.5 + Style.space(18)
    readonly property real outerR: Math.max(innerR, width * 0.5 - outerClear)
    readonly property real ringGap: (outerR - innerR) / 7
    readonly property real cx: width * 0.5
    readonly property real cy: height * 0.5

    property int hoverIndex: -1
    property int pendingHover: -1

    Timer {
      id: hoverDelay
      interval: 80
      onTriggered: map.hoverIndex = map.pendingHover
    }

    function setHover(index, on) {
      if (on) {
        map.pendingHover = index
        if (map.hoverIndex >= 0) {
          hoverDelay.stop()
          map.hoverIndex = index
        } else {
          hoverDelay.restart()
        }
        return
      }
      if (map.hoverIndex === index || map.pendingHover === index) {
        hoverDelay.stop()
        map.hoverIndex = -1
        map.pendingHover = -1
      }
    }

    // Display sizes: sun is the largest body. Giants stay bigger than
    // the terrestrials, but never larger than the sun.
    function bodyPx(sz, ring) {
      var sizes = [6, 9, 9, 8, 16, 14, 11, 11]
      var i = ring
      if (typeof i !== "number" || !isFinite(i) || i < 0) i = 0
      if (i > 7) i = 7
      return Math.max(5, Math.round(sizes[i] * Style.effectiveSpacingScale))
    }

    readonly property var hoverBody: {
      if (hoverIndex < 0) return null
      var s = root.snapshot
      if (!s || !s.bodies) return null
      if (hoverIndex >= s.bodies.length) return null
      var b = s.bodies[hoverIndex]
      return b ? b : null
    }
    readonly property int hoverRing: {
      var b = hoverBody
      if (!b) return 0
      var i = b.ringIndex
      if (typeof i !== "number" || !isFinite(i)) return hoverIndex
      if (i < 0) return 0
      if (i > 7) return 7
      return i
    }
    readonly property real hoverLon: {
      var b = hoverBody
      if (!b) return 0
      var v = b.lonRad
      return (typeof v === "number" && isFinite(v)) ? v : 0
    }
    readonly property real hoverOrbit: innerR + hoverRing * ringGap
    readonly property real hoverSx: cx + hoverOrbit * Math.cos(hoverLon)
    readonly property real hoverSy: cy - hoverOrbit * Math.sin(hoverLon)
    readonly property real hoverDiam: {
      var b = hoverBody
      return map.bodyPx(b ? b.size : 5, hoverRing)
    }
    readonly property string hoverName: {
      var b = hoverBody
      return (b && b.name) ? String(b.name) : ""
    }
    readonly property string hoverAu: {
      var b = hoverBody
      var au = b ? b.rAU : NaN
      return (typeof au === "number" && isFinite(au)) ? (au.toFixed(2) + " AU") : ""
    }

    Repeater {
      model: root.stars
      Rectangle {
        required property var modelData
        width: Math.max(1, modelData.s || 1)
        height: width
        x: Math.round(modelData.x * map.width)
        y: Math.round(modelData.y * map.height)
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, modelData.a)
      }
    }

    Repeater {
      model: 8
      Rectangle {
        required property int index
        readonly property real ringR: map.innerR + index * map.ringGap
        width: ringR * 2
        height: width
        radius: width / 2
        anchors.centerIn: parent
        color: "transparent"
        border.width: 1
        border.color: root.orbitColor
        antialiasing: true
      }
    }

    Repeater {
      model: root.bodyCount
      Item {
        id: planet
        required property int index

        readonly property var body: {
          var s = root.snapshot
          if (!s || !s.bodies) return null
          return s.bodies[index]
        }
        readonly property int ringIndex: {
          var b = body
          if (!b) return index
          var i = b.ringIndex
          if (typeof i !== "number" || !isFinite(i)) return index
          if (i < 0) return 0
          if (i > 7) return 7
          return i
        }
        readonly property real lonRad: {
          var b = body
          if (!b) return 0
          var v = b.lonRad
          return (typeof v === "number" && isFinite(v)) ? v : 0
        }
        readonly property real diam: map.bodyPx(body ? body.size : 5, ringIndex)
        readonly property color planetColor: (body && body.color) ? body.color : "#888888"
        readonly property bool hasRings: !!(body && body.hasRings)
        readonly property real orbitR: map.innerR + ringIndex * map.ringGap
        readonly property real sx: map.cx + orbitR * Math.cos(lonRad)
        // 0° at +X, CCW; screen Y grows down, so sy = cy - r sin(lon)
        readonly property real sy: map.cy - orbitR * Math.sin(lonRad)

        visible: body != null
        x: sx - width / 2
        y: sy - height / 2
        width: diam
        height: diam
        opacity: (map.hoverIndex < 0 || map.hoverIndex === index) ? 1 : 0.5
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        Rectangle {
          visible: planet.hasRings
          width: planet.diam * 1.55
          height: Math.max(2, planet.diam * 0.22)
          radius: height / 2
          rotation: -24
          anchors.centerIn: parent
          color: Qt.rgba(planet.planetColor.r, planet.planetColor.g, planet.planetColor.b, 0.75)
          antialiasing: true
        }

        Rectangle {
          width: planet.diam
          height: planet.diam
          radius: width / 2
          anchors.centerIn: parent
          color: planet.planetColor
          antialiasing: true
        }

        MouseArea {
          anchors.centerIn: parent
          width: Math.max(planet.diam + Style.space(10), Style.space(16))
          height: width
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          onContainsMouseChanged: map.setHover(planet.index, containsMouse)
        }
      }
    }

    Rectangle {
      id: sun
      anchors.centerIn: parent
      width: map.sunDiam
      height: width
      radius: width / 2
      color: root.sunColor
      antialiasing: true
      z: 2
    }
  }

  Rectangle {
    id: tooltip
    visible: map.hoverIndex >= 0 && (map.hoverName.length > 0 || map.hoverAu.length > 0)
    z: 30
    width: tipRow.implicitWidth + Style.space(10)
    height: tipRow.implicitHeight + Style.space(6)
    radius: Style.space(4)
    color: Color.background
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)

    readonly property real gap: Style.space(8)
    readonly property real inset: Style.space(4)
    readonly property real localX: map.cx + (map.hoverOrbit + map.hoverDiam * 0.5 + gap + width * 0.5) * Math.cos(map.hoverLon)
    readonly property real localY: map.cy - (map.hoverOrbit + map.hoverDiam * 0.5 + gap + height * 0.5) * Math.sin(map.hoverLon)
    readonly property bool flipOut: {
      var x0 = map.x + localX - width * 0.5
      var y0 = map.y + localY - height * 0.5
      return x0 < inset || y0 < inset || x0 + width > root.width - inset || y0 + height > root.height - inset
    }

    x: {
      var lx = tooltip.flipOut
        ? map.cx + (map.hoverOrbit - map.hoverDiam * 0.5 - gap - width * 0.5) * Math.cos(map.hoverLon) - width * 0.5
        : tooltip.localX - width * 0.5
      return Math.max(inset, Math.min(root.width - width - inset, map.x + lx))
    }
    y: {
      var ly = tooltip.flipOut
        ? map.cy - (map.hoverOrbit - map.hoverDiam * 0.5 - gap - height * 0.5) * Math.sin(map.hoverLon) - height * 0.5
        : tooltip.localY - height * 0.5
      return Math.max(inset, Math.min(root.height - height - inset, map.y + ly))
    }

    Row {
      id: tipRow
      anchors.centerIn: parent
      spacing: Style.space(6)

      Text {
        textFormat: Text.PlainText
        text: map.hoverName
        visible: map.hoverName.length > 0
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
      Text {
        textFormat: Text.PlainText
        text: map.hoverAu
        visible: map.hoverAu.length > 0
        color: root.dimColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
