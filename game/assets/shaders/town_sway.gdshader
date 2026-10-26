shader_type canvas_item;
// The cypresses in the town picture lean with the wind by a pixel or so at their tops. The mask marks each tree's
// pixels in red and how far up the tree they are in green; where a top moves off, the sky behind shows through.

uniform sampler2D mask : filter_nearest;
uniform float clock = 0.0;
uniform float strength = 1.0;

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE;
	vec4 here = texture(mask, UV);
	float gust = sin(clock * 1.1 + UV.x * 9.0) * 0.7 + sin(clock * 2.3 + UV.x * 23.0) * 0.3;
	float shift = round(gust * here.g * 1.6 * strength);
	vec2 from = UV - vec2(shift * texel.x, 0.0);
	vec4 there = texture(mask, from);
	if (there.r > 0.5) {
		COLOR = texture(TEXTURE, from);
	} else if (here.r > 0.5) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, UV);
	}
}
