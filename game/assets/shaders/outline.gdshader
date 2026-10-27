shader_type canvas_item;
// A one-pixel outline round a sprite, so a pet lying on a rug of the same colours still stands out from it.

uniform vec4 colour : source_color = vec4(0.16, 0.08, 0.06, 0.7);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.1) {
		float near = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a + texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a + texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
		COLOR = near > 0.1 ? colour : vec4(0.0);
	} else {
		COLOR = c;
	}
}
