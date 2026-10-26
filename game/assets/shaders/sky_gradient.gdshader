shader_type canvas_item;
// A pixel-art sky: the gradient from zenith to horizon is cut into flat bands with an ordered dither between them,
// the sun's glow spreads in dithered rings, and stars twinkle at night. Everything is worked out per sky pixel.

uniform vec2 area = vec2(1536.0, 672.0);
uniform vec2 origin = vec2(0.0, -400.0);
uniform float top = -60.0;
uniform float horizon = 205.0;
uniform float bands = 9.0;
uniform vec4 zenith : source_color;
uniform vec4 middle : source_color;
uniform vec4 low : source_color;
uniform vec2 sun = vec2(300.0, 100.0);
uniform vec4 glow : source_color;
uniform float glow_radius = 150.0;
uniform float stars = 0.0;
uniform float time = 0.0;

float bayer2(vec2 a) {
	a = floor(a);
	return fract(a.x / 2.0 + a.y * a.y * 0.75);
}

float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = floor(origin + UV * area);
	float d = bayer4(px);
	float t = clamp((px.y - top) / (horizon - top), 0.0, 1.0);
	float q = clamp(floor(t * bands * 2.0 + d) / (bands * 2.0), 0.0, 1.0);
	vec3 col = q < 0.5 ? mix(zenith.rgb, middle.rgb, q * 2.0) : mix(middle.rgb, low.rgb, (q - 0.5) * 2.0);
	float r = length((px - sun) * vec2(1.0, 1.4)) / glow_radius;
	float g = clamp(1.0 - r, 0.0, 1.0);
	g = floor(g * g * 6.0 + d) / 6.0;
	col = mix(col, glow.rgb, g * glow.a);
	if (stars > 0.0 && t < 0.8) {
		float h = hash(px);
		if (h > 0.9965) {
			float twinkle = 0.55 + 0.45 * sin(time * (0.8 + fract(h * 91.0) * 2.5) + h * 300.0);
			col = mix(col, vec3(0.93, 0.93, 1.0), stars * twinkle * (1.0 - t));
		}
	}
	COLOR = vec4(col, 1.0);
}
