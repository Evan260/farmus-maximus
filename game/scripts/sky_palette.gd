class_name SkyPalette
## The sky's colours through the day: zenith, middle and horizon, the sun's glow, and the light and shade on clouds.

const KEYS := [
	[0.0, {"zenith": Color8(12, 14, 38), "middle": Color8(26, 30, 66), "low": Color8(48, 46, 88), "glow": Color(0, 0, 0, 0), "light": Color(0.42, 0.45, 0.66), "shade": Color(0.16, 0.18, 0.34)}],
	[4.6, {"zenith": Color8(12, 14, 38), "middle": Color8(26, 30, 66), "low": Color8(48, 46, 88), "glow": Color(0, 0, 0, 0), "light": Color(0.42, 0.45, 0.66), "shade": Color(0.16, 0.18, 0.34)}],
	[5.4, {"zenith": Color8(30, 32, 72), "middle": Color8(78, 62, 112), "low": Color8(168, 104, 116), "glow": Color(0.95, 0.55, 0.45, 0.35), "light": Color(0.72, 0.56, 0.66), "shade": Color(0.28, 0.25, 0.44)}],
	[6.4, {"zenith": Color8(66, 84, 150), "middle": Color8(200, 132, 146), "low": Color8(255, 182, 112), "glow": Color(1.0, 0.76, 0.46, 0.85), "light": Color(1.0, 0.82, 0.66), "shade": Color(0.62, 0.48, 0.62)}],
	[8.0, {"zenith": Color8(84, 146, 214), "middle": Color8(148, 196, 234), "low": Color8(232, 228, 204), "glow": Color(1.0, 0.96, 0.84, 0.4), "light": Color(1.0, 1.0, 0.97), "shade": Color(0.7, 0.75, 0.88)}],
	[13.0, {"zenith": Color8(66, 136, 220), "middle": Color8(128, 188, 240), "low": Color8(208, 232, 242), "glow": Color(1.0, 1.0, 0.92, 0.3), "light": Color(1.0, 1.0, 1.0), "shade": Color(0.72, 0.78, 0.9)}],
	[16.5, {"zenith": Color8(82, 136, 206), "middle": Color8(156, 192, 228), "low": Color8(242, 222, 180), "glow": Color(1.0, 0.92, 0.74, 0.45), "light": Color(1.0, 0.97, 0.9), "shade": Color(0.72, 0.73, 0.86)}],
	[18.5, {"zenith": Color8(92, 96, 168), "middle": Color8(232, 146, 122), "low": Color8(255, 198, 112), "glow": Color(1.0, 0.72, 0.42, 0.85), "light": Color(1.0, 0.8, 0.6), "shade": Color(0.7, 0.5, 0.58)}],
	[19.8, {"zenith": Color8(38, 38, 92), "middle": Color8(120, 76, 122), "low": Color8(228, 118, 96), "glow": Color(0.98, 0.5, 0.38, 0.6), "light": Color(0.86, 0.56, 0.56), "shade": Color(0.36, 0.28, 0.46)}],
	[21.4, {"zenith": Color8(12, 14, 38), "middle": Color8(26, 30, 66), "low": Color8(48, 46, 88), "glow": Color(0, 0, 0, 0), "light": Color(0.42, 0.45, 0.66), "shade": Color(0.16, 0.18, 0.34)}],
	[24.0, {"zenith": Color8(12, 14, 38), "middle": Color8(26, 30, 66), "low": Color8(48, 46, 88), "glow": Color(0, 0, 0, 0), "light": Color(0.42, 0.45, 0.66), "shade": Color(0.16, 0.18, 0.34)}],
]
const SUNRISE := 6.0
const SUNSET := 19.8


static func at(hour: float, overcast: bool) -> Dictionary:
	var out := {}
	for k in range(KEYS.size() - 1):
		var a: Array = KEYS[k]
		var b: Array = KEYS[k + 1]
		if hour >= a[0] and hour <= b[0]:
			var w: float = (hour - a[0]) / (b[0] - a[0])
			for key in a[1]:
				out[key] = (a[1][key] as Color).lerp(b[1][key], w)
			break
	if out.is_empty():
		out = (KEYS[0][1] as Dictionary).duplicate()
	if overcast:
		# A grey day: the colours are drained towards a soft grey and the sun's glow fades.
		for key in ["zenith", "middle", "low", "light"]:
			var c: Color = out[key]
			var grey := (c.r + c.g + c.b) / 3.0
			out[key] = c.lerp(Color(grey, grey, grey * 1.04), 0.6).darkened(0.08)
		out["glow"] = Color(out["glow"], out["glow"].a * 0.3)
	return out


## Where the sun stands in a sky this wide, rising on the left and setting on the right; NAN at night.
static func sun_position(hour: float, width: float, horizon: float, height: float) -> Vector2:
	if hour < SUNRISE - 0.3 or hour > SUNSET + 0.3:
		return Vector2(NAN, NAN)
	var t := (hour - SUNRISE) / (SUNSET - SUNRISE)
	return Vector2(lerpf(width * 0.06, width * 0.92, t), horizon - sin(clampf(t, 0.0, 1.0) * PI) * height)
