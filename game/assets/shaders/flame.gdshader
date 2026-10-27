shader_type canvas_item;
// Flames that lick and flicker: each flame pixel takes its colour from a pixel nearby that wanders up and sideways
// over time, in whole pixels so the picture stays crisp; logs, stone and ash stay where they are.

// How far the flames wander, in pixels; small for a lamp, larger for a fire.
uniform float reach = 2.0;
uniform float speed = 1.0;

bool is_flame(vec4 c) {
	float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	// Strongly orange, or the white-hot core; pale stone and firelit brick are not flame.
	return c.a > 0.1 && ((c.r - c.b > 0.55 && lum > 0.5) || (lum > 0.88 && c.b < 0.75));
}

float wave(float x, float t) {
	return sin(x + t) * 0.6 + sin(x * 2.3 - t * 1.7) * 0.4;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec2 cell = floor(UV / px);
	float t = TIME * speed;
	// Rows sway sideways, and the whole flame climbs a pixel or two and drops back.
	float dx = floor(wave(cell.y * 0.7, t * 7.0) * reach + 0.5);
	float dy = floor((0.5 + 0.5 * wave(cell.x * 0.5, t * 5.0)) * reach + 0.5);
	vec4 moved = texture(TEXTURE, UV + vec2(dx, dy) * px);
	if (is_flame(c) || is_flame(moved)) {
		// Above the flame's top a borrowed pixel may be empty; flame pixels whose source is not flame die away.
		COLOR = is_flame(moved) ? moved : vec4(c.rgb * 0.55, c.a);
		COLOR.rgb *= 0.9 + 0.2 * (0.5 + 0.5 * sin(t * 11.0 + cell.x * 0.3 + cell.y * 0.2));
	} else {
		COLOR = c;
	}
}
