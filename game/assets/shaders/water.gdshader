shader_type canvas_item;
// Still water stirring gently: each row of the pool's surface drifts a pixel to and fro, out of step with its
// neighbours, so the reflections waver; whole pixels only, so the picture stays crisp.

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	float row = floor(UV.y / px.y);
	float shift = floor(sin(row * 0.9 + TIME * 1.6) * 0.5 + sin(row * 0.37 - TIME * 0.9) * 0.6 + 0.5);
	vec4 c = texture(TEXTURE, UV + vec2(shift * px.x, 0.0));
	// The pool's own edge stays put: a pixel borrowed from outside the water is not used.
	COLOR = c.a > 0.5 ? c : texture(TEXTURE, UV);
}
