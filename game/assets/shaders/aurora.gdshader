shader_type canvas_item;
render_mode blend_add;
// The northern lights: a few rippling curtains, bright green along their lower hem, fading upward through teal into
// violet, with faint vertical rays that shimmer. Worked out per sky pixel so it keeps the sky's pixel grid, but with
// soft fades between the pixels rather than hard edges.

uniform float amount = 0.0;
// The sprite's size and top left corner in sky pixels.
uniform vec2 area = vec2(1536.0, 400.0);
uniform vec2 origin = vec2(0.0, -120.0);
uniform float motion = 1.0;

float hash(float n) {
	return fract(sin(n * 91.3458) * 47453.5453);
}

float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

// One curtain: its lower hem waves across the sky and drifts slowly sideways.
float curtain(vec2 p, float seed, float hem, float height, float t) {
	float wave = hem + 18.0 * sin(p.x * 0.011 + seed * 2.1 + t * 0.07) + 9.0 * sin(p.x * 0.027 - seed + t * 0.11) + 4.0 * sin(p.x * 0.06 + t * 0.2 + seed * 3.0);
	float above = wave - p.y;
	// A broad glowing ribbon just above the hem, a soft spill of light below it, and a long fade upward.
	float ribbon = exp(-pow((above - 7.0) / 9.0, 2.0));
	float spill = exp(min(above, 0.0) * 0.4);
	float body = exp(-max(above, 0.0) / height) * spill;
	// Rays: thin vertical streaks that brighten and dim along the curtain.
	float rays = 0.55 + 0.45 * noise(p.x * 0.35 + seed * 13.0 + t * 0.6) * noise(p.x * 0.09 - t * 0.25 + seed);
	// Some stretches of the curtain are strong and others nearly gone, and this shifts over the night.
	float patch = smoothstep(0.25, 0.75, noise(p.x * 0.006 + seed * 5.0 + t * 0.03));
	return (ribbon * 0.9 + body * 0.55) * rays * patch;
}

void fragment() {
	vec2 p = floor(origin + UV * area);
	float t = TIME * motion;
	vec3 total = vec3(0.0);
	for (int i = 0; i < 3; i++) {
		float seed = float(i) * 1.7 + 0.4;
		float hem = 110.0 - float(i) * 28.0;
		float height = 34.0 + float(i) * 10.0;
		float c = curtain(p, seed, hem, height, t);
		// How far above the hem this pixel is, from 0 at the hem to 1 high up, picks the colour.
		float up = clamp((hem - p.y) / (height * 2.4), 0.0, 1.0);
		vec3 green = vec3(0.32, 1.0, 0.62);
		vec3 teal = vec3(0.2, 0.75, 0.85);
		vec3 violet = vec3(0.62, 0.36, 0.92);
		vec3 colour = mix(mix(green, teal, smoothstep(0.1, 0.45, up)), violet, smoothstep(0.45, 0.95, up));
		total += colour * c * (1.0 - float(i) * 0.22);
	}
	// Low down near the hills the light is lost in the haze.
	total *= smoothstep(196.0, 150.0, p.y);
	COLOR = vec4(total * amount * 0.7, 1.0);
}
