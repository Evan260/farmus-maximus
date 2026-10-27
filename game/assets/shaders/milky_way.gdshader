shader_type canvas_item;
render_mode blend_add;
// The Milky Way on a dark, moonless night: a broad arch of faint light from one side of the sky to the other, warm at
// its heart and bluish at its edges, crowded with tiny stars and split along its middle by a dark rift of dust.
// Worked out per sky pixel, so it keeps the sky's pixel grid.

uniform float amount = 0.0;
// The sprite's size and top left corner in sky pixels.
uniform vec2 area = vec2(1536.0, 400.0);
uniform vec2 origin = vec2(0.0, -120.0);
uniform float clock = 0.0;
// Where the arch meets the hills and how high it climbs.
uniform float horizon = 205.0;
uniform float rise = 185.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float weight = 0.5;
	for (int i = 0; i < 4; i++) {
		total += noise(p) * weight;
		p *= 2.03;
		weight *= 0.5;
	}
	return total;
}

void fragment() {
	vec2 p = floor(origin + UV * area);
	// The arch's middle line, and how far this pixel is from it across the band.
	float centre = horizon - rise * sin(3.14159 * p.x / area.x);
	float across = p.y - centre;
	float width = 34.0 + 10.0 * sin(p.x * 0.009 + 1.3);
	float band = exp(-pow(across / width, 2.0));
	float core = exp(-pow(across / (width * 0.45), 2.0));
	// Clumps of starlight along the band rather than an even smear.
	float clouds = fbm(p * vec2(0.018, 0.03) + vec2(3.1, 7.7));
	float glow = band * (0.35 + 0.9 * clouds) + core * 0.35 * clouds;
	// The dark rift: a wandering lane of dust a little off the middle that swallows the light.
	float lane = across + 6.0 - 7.0 * (fbm(p * vec2(0.012, 0.02) + vec2(11.0, 2.0)) - 0.5) * 2.0;
	glow *= 1.0 - 0.75 * exp(-pow(lane / 5.0, 2.0)) * smoothstep(0.3, 0.6, fbm(p * 0.02 + vec2(5.0, 9.0)));
	vec3 colour = mix(vec3(0.55, 0.62, 0.95), vec3(1.0, 0.9, 0.78), clamp(core * 1.4, 0.0, 1.0));
	// A faint rose tint here and there, like the glowing clouds of gas in long-exposure photographs.
	colour = mix(colour, vec3(0.95, 0.62, 0.78), 0.25 * smoothstep(0.62, 0.8, fbm(p * 0.025 + vec2(17.0, 4.0))) * band);
	vec3 total = colour * glow * 0.42;
	// Tiny stars, far more of them inside the band, the brightest few twinkling.
	float h = hash(p + vec2(41.0, 13.0));
	float crowd = 0.985 - 0.06 * band;
	if (h > crowd) {
		float bright = (h - crowd) / (1.0 - crowd);
		float twinkle = 0.75 + 0.25 * sin(clock * (1.0 + fract(h * 77.0) * 3.0) + h * 200.0);
		total += vec3(0.95, 0.95, 1.0) * (0.25 + 0.6 * bright) * twinkle * (0.4 + band);
	}
	// Low down near the hills the light is lost in the haze.
	total *= smoothstep(horizon - 4.0, horizon - 40.0, p.y);
	COLOR = vec4(total * amount, 1.0);
}
