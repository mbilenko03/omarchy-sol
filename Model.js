var BODY_IDS = ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]

var DEG2RAD = Math.PI / 180
var TWO_PI = 2 * Math.PI
var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var META = [
  { id: "mercury", name: "Mercury", color: "#c8c8c8", size: 5, hasRings: false, ringIndex: 0 },
  { id: "venus", name: "Venus", color: "#e6c34a", size: 7, hasRings: false, ringIndex: 1 },
  { id: "earth", name: "Earth", color: "#3d8bfd", size: 7, hasRings: false, ringIndex: 2 },
  { id: "mars", name: "Mars", color: "#e24a32", size: 6, hasRings: false, ringIndex: 3 },
  { id: "jupiter", name: "Jupiter", color: "#d4a05a", size: 13, hasRings: false, ringIndex: 4 },
  { id: "saturn", name: "Saturn", color: "#e4d08a", size: 12, hasRings: true, ringIndex: 5 },
  { id: "uranus", name: "Uranus", color: "#7ecad4", size: 10, hasRings: false, ringIndex: 6 },
  { id: "neptune", name: "Neptune", color: "#4d6fe8", size: 10, hasRings: false, ringIndex: 7 }
]

// Standish Table 1 (1800–2050): a AU, e rad; I L ϖ Ω deg. Row 2 is EM Bary → earth.
// Per body: a0, adot, e0, edot, I0, Idot, L0, Ldot, varpi0, varpidot, Omega0, Omegadot
var ELEM = [
  [0.38709927, 0.00000037, 0.20563593, 0.00001906, 7.00497902, -0.00594749, 252.25032350, 149472.67411175, 77.45779628, 0.16047689, 48.33076593, -0.12534081],
  [0.72333566, 0.00000390, 0.00677672, -0.00004107, 3.39467605, -0.00078890, 181.97909950, 58517.81538729, 131.60246718, 0.00268329, 76.67984255, -0.27769418],
  [1.00000261, 0.00000562, 0.01671123, -0.00004392, -0.00001531, -0.01294668, 100.46457166, 35999.37244981, 102.93768193, 0.32327364, 0.0, 0.0],
  [1.52371034, 0.00001847, 0.09339410, 0.00007882, 1.84969142, -0.00813131, -4.55343205, 19140.30268499, -23.94362959, 0.44441088, 49.55953891, -0.29257343],
  [5.20288700, -0.00011607, 0.04838624, -0.00013253, 1.30439695, -0.00183714, 34.39644051, 3034.74612775, 14.72847983, 0.21252668, 100.47390909, 0.20469106],
  [9.53667594, -0.00125060, 0.05386179, -0.00050991, 2.48599187, 0.00193609, 49.95424423, 1222.49362201, 92.59887831, -0.41897216, 113.66242448, -0.28867794],
  [19.18916464, -0.00196176, 0.04725744, -0.00004397, 0.77263783, -0.00242939, 313.23810451, 428.48202785, 170.95427630, 0.40805281, 74.01692503, 0.04240589],
  [30.06992276, 0.00026291, 0.00859048, 0.00005105, 1.77004347, 0.00035372, -55.12002969, 218.45945325, 44.96476227, -0.32241464, 131.78422574, -0.00508664]
]

function bodyMeta() {
  return META
}

function pad2(n) {
  return (n < 10 ? "0" : "") + n
}

function wrapPi(M) {
  M = M % TWO_PI
  if (M > Math.PI) M -= TWO_PI
  else if (M < -Math.PI) M += TWO_PI
  return M
}

function keplerE(M, e) {
  var E = M + e * Math.sin(M)
  for (var i = 0; i < 8; i++) {
    var dE = (M - (E - e * Math.sin(E))) / (1 - e * Math.cos(E))
    E += dE
    if (Math.abs(dE) < 1e-10) break
  }
  return E
}

function positionsAt(ms) {
  var jd = ms / 86400000 + 2440587.5
  var T = (jd - 2451545.0) / 36525
  var d = new Date(ms)
  var bodies = new Array(8)

  for (var i = 0; i < 8; i++) {
    var el = ELEM[i]
    var a = el[0] + el[1] * T
    var e = el[2] + el[3] * T
    var I = (el[4] + el[5] * T) * DEG2RAD
    var L = (el[6] + el[7] * T) * DEG2RAD
    var varpi = (el[8] + el[9] * T) * DEG2RAD
    var Omega = (el[10] + el[11] * T) * DEG2RAD
    var omega = varpi - Omega
    var M = wrapPi(L - varpi)
    var E = keplerE(M, e)
    var xP = a * (Math.cos(E) - e)
    var yP = a * Math.sqrt(Math.max(0, 1 - e * e)) * Math.sin(E)
    var cosw = Math.cos(omega)
    var sinw = Math.sin(omega)
    var cosO = Math.cos(Omega)
    var sinO = Math.sin(Omega)
    var cosI = Math.cos(I)
    var sinI = Math.sin(I)
    var x = (cosw * cosO - sinw * sinO * cosI) * xP + (-sinw * cosO - cosw * sinO * cosI) * yP
    var y = (cosw * sinO + sinw * cosO * cosI) * xP + (-sinw * sinO + cosw * cosO * cosI) * yP
    var z = sinw * sinI * xP + cosw * sinI * yP
    var xy = Math.sqrt(x * x + y * y)
    var rAU = Math.sqrt(x * x + y * y + z * z)
    var m = META[i]
    bodies[i] = {
      id: m.id,
      name: m.name,
      xAU: x,
      yAU: y,
      zAU: z,
      rAU: rAU,
      lonRad: Math.atan2(y, x),
      latRad: Math.atan2(z, xy),
      color: m.color,
      size: m.size,
      hasRings: m.hasRings,
      ringIndex: m.ringIndex
    }
  }

  return {
    timeMs: ms,
    jd: jd,
    utcDate: MONTHS[d.getUTCMonth()] + " " + d.getUTCDate() + ", " + d.getUTCFullYear(),
    utcTime: pad2(d.getUTCHours()) + ":" + pad2(d.getUTCMinutes()) + " UTC",
    bodies: bodies
  }
}

function positionsNow() {
  return positionsAt(Date.now())
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = { BODY_IDS: BODY_IDS, bodyMeta: bodyMeta, positionsAt: positionsAt, positionsNow: positionsNow }
}
