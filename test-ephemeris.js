#!/usr/bin/env node

var Model = require("./Model.js")

function fail(msg) {
  console.error("FAIL: " + msg)
  process.exit(1)
}

function assert(cond, msg) {
  if (!cond) fail(msg)
}

var RANGES = {
  mercury: [0.30, 0.47],
  venus: [0.71, 0.73],
  earth: [0.98, 1.02],
  mars: [1.38, 1.67],
  jupiter: [4.95, 5.46],
  saturn: [9.0, 10.1],
  uranus: [18.2, 20.1],
  neptune: [29.8, 30.4]
}

var ms2026 = Date.UTC(2026, 8, 8)
var snap = Model.positionsAt(ms2026)

assert(Array.isArray(snap.bodies) && snap.bodies.length === 8, "expected 8 bodies, got " + (snap.bodies && snap.bodies.length))
assert(Model.BODY_IDS.length === 8, "BODY_IDS length")
for (var i = 0; i < 8; i++) {
  assert(snap.bodies[i].id === Model.BODY_IDS[i], "body " + i + " id " + snap.bodies[i].id + " != " + Model.BODY_IDS[i])
}
console.log("OK 8 bodies in BODY_IDS order")

for (var i = 0; i < 8; i++) {
  var b = snap.bodies[i]
  var hyp = Math.sqrt(b.xAU * b.xAU + b.yAU * b.yAU + b.zAU * b.zAU)
  assert(Math.abs(b.rAU - hyp) <= 1e-12, b.id + " rAU " + b.rAU + " != hypot " + hyp)
}
console.log("OK rAU equals hypot(x,y,z) within 1e-12")

for (var i = 0; i < 8; i++) {
  var b = snap.bodies[i]
  var lim = RANGES[b.id]
  var loOk = b.id === "mercury" ? b.rAU > lim[0] : b.rAU >= lim[0]
  var hiOk = b.id === "mercury" ? b.rAU < lim[1] : b.rAU <= lim[1]
  assert(loOk && hiOk, b.id + " rAU " + b.rAU + " outside " + lim[0] + "–" + lim[1] + " at 2026-09-08")
}
console.log("OK rAU ranges at Date.UTC(2026, 8, 8)")

var j2000 = Model.positionsAt(Date.UTC(2000, 0, 1, 12))
var earthJ2000 = null
for (var i = 0; i < 8; i++) {
  if (j2000.bodies[i].id === "earth") earthJ2000 = j2000.bodies[i]
}
assert(earthJ2000, "missing earth at J2000")
assert(Math.abs(earthJ2000.rAU - 0.983) <= 0.004, "J2000 Earth rAU " + earthJ2000.rAU + " not within 0.983 ± 0.004")
console.log("OK J2000 Earth rAU " + earthJ2000.rAU)

for (var i = 0; i < 8; i++) {
  var b = snap.bodies[i]
  var lon = Math.atan2(b.yAU, b.xAU)
  assert(Math.abs(b.lonRad - lon) <= 1e-12, b.id + " lonRad " + b.lonRad + " != atan2 " + lon)
}
console.log("OK lonRad = atan2(yAU, xAU) within 1e-12")

var snap2 = Model.positionsAt(ms2026)
for (var i = 0; i < 8; i++) {
  assert(snap.bodies[i].xAU === snap2.bodies[i].xAU, snap.bodies[i].id + " xAU not deterministic")
}
console.log("OK positionsAt deterministic")

var t0 = Date.now()
for (var n = 0; n < 5000; n++) Model.positionsAt(ms2026)
var elapsed = Date.now() - t0
console.log("OK 5000 calls in " + elapsed + "ms")
if (elapsed > 500) fail("5000 calls took " + elapsed + "ms (> 500ms)")

var fmt = Model.positionsAt(Date.UTC(2024, 10, 10, 14, 27, 0))
assert(fmt.utcDate === "Nov 10, 2024", "utcDate got " + JSON.stringify(fmt.utcDate))
assert(fmt.utcTime === "14:27 UTC", "utcTime got " + JSON.stringify(fmt.utcTime))
console.log("OK utcDate/utcTime")

var earth2026 = null
for (var i = 0; i < 8; i++) {
  if (snap.bodies[i].id === "earth") earth2026 = snap.bodies[i]
}
console.log("Earth J2000        rAU=" + earthJ2000.rAU + " lonRad=" + earthJ2000.lonRad)
console.log("Earth 2026-09-08Z  rAU=" + earth2026.rAU + " lonRad=" + earth2026.lonRad)
console.log("ALL OK")
