shader_type canvas_item;
// Breaks a picture of the old screen away in square blocks scattered at random, so the new screen shows through.

uniform float progress = 0.0;
uniform float cell = 6.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	if (hash(floor(FRAGCOORD.xy / cell)) < progress) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}
