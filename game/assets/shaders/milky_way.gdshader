shader_type canvas_item;
render_mode blend_add;
// The Milky Way on a dark, moonless night, as it looks rising over a landscape: its glowing golden heart just above
// the hills, climbing the sky as a leaning column that narrows, cools to violet and fades as it goes, with rose-red
// clouds of glowing gas, dark rifts of dust and a crowd of coloured stars. Worked out per sky pixel, so it keeps the
// sky's pixel grid.

uniform float amount = 0.0;
// The sprite's size and top left corner in sky pixels.
uniform vec2 area = vec2(1536.0, 400.0);
uniform vec2 origin = vec2(0.0, -120.0);
uniform float clock = 0.0;
// Where the column rises from the hills, how high it climbs and how far it leans to the right as it goes up.
uniform float horizon = 205.0;
uniform float base_x = 190.0;
uniform float height = 260.0;
uniform float lean = 0.42;

// A hash built from fractions rather than a sine, which on some graphics cards repeats in visible stripes.
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
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
	for (int i = 0; i < 5; i++) {
		total += noise(p) * weight;
		p = p * 2.07 + vec2(13.1, 7.3);
		weight *= 0.5;
	}
	return total;
}

void fragment() {
	vec2 p = floor(origin + UV * area);
	// Distance up the column from where it leaves the hills, and sideways from its middle line.
	vec2 axis = normalize(vec2(lean, -1.0));
	vec2 q = p - vec2(base_x, horizon + 10.0);
	float up = dot(q, axis);
	float across = dot(q, vec2(-axis.y, axis.x));
	float rel = clamp(up / height, 0.0, 1.0);
	// The heart sits low, just above the hills; higher up the column narrows and fades into the night.
	float swell = exp(-pow((rel - 0.12) / 0.16, 2.0));
	float fade = smoothstep(-0.05, 0.08, rel) * (1.0 - smoothstep(0.55, 1.0, rel));
	float width = (84.0 - 50.0 * rel + 30.0 * swell) * (1.0 + 0.12 * sin(up * 0.05));
	float band = exp(-pow(across / width, 2.0)) * fade;
	float inner = exp(-pow(across / (width * 0.42), 2.0)) * fade;
	// Patterns are laid along the column, stretched in the direction it climbs.
	vec2 c = vec2(up, across);
	// Billowing star clouds, so the light gathers in clumps rather than an even smear.
	float clouds = fbm(c * vec2(0.014, 0.022) + vec2(3.1, 7.7));
	float detail = fbm(c * vec2(0.05, 0.07) + vec2(9.4, 1.2));
	float light = band * (0.25 + 1.1 * clouds * clouds) + inner * (0.4 + 0.6 * detail) * (0.5 + swell);
	// Dark rifts of dust: one long lane along the middle and wisps branching off it.
	float wander = (fbm(c * vec2(0.008, 0.02) + vec2(11.0, 2.0)) - 0.5) * 18.0;
	float rift = exp(-pow((across - 3.0 + wander) / (4.0 + 5.0 * swell), 2.0));
	float wisps = smoothstep(0.55, 0.75, fbm(c * vec2(0.03, 0.045) + vec2(5.0, 9.0))) * band;
	light *= 1.0 - 0.8 * clamp(rift * (0.6 + 0.4 * swell) + wisps * 0.7, 0.0, 1.0);
	// Colour: violet and blue along the faint arms, white-gold towards the middle of the band, a glowing amber heart.
	vec3 arm = mix(vec3(0.32, 0.36, 0.95), vec3(0.62, 0.42, 0.95), smoothstep(0.35, 0.7, noise(p * 0.01)));
	vec3 colour = mix(arm, vec3(1.0, 0.88, 0.72), clamp(inner * 0.9, 0.0, 1.0));
	colour = mix(colour, vec3(1.0, 0.66, 0.32), clamp(inner * swell * 1.8, 0.0, 1.0));
	vec3 total = colour * light * 0.75;
	// Rose-red clouds of glowing gas scattered along the band.
	float gas = smoothstep(0.6, 0.78, fbm(p * 0.03 + vec2(17.0, 4.0))) * band;
	total += vec3(0.95, 0.28, 0.45) * gas * 0.45;
	// The bulge: a broad golden glow where the column leaves the hills, the bright centre of the galaxy.
	total += vec3(1.0, 0.68, 0.36) * exp(-pow(across / 70.0, 2.0) - pow((up - 26.0) / 40.0, 2.0)) * 0.42 * (1.0 - 0.6 * rift);
	// Stars: many more inside the band, in white, blue-white, gold and orange, the brightest ones twinkling.
	float h = hash(p + vec2(41.0, 13.0));
	float crowd = 0.988 - 0.05 * band - 0.04 * inner * swell;
	if (h > crowd) {
		float bright = (h - crowd) / (1.0 - crowd);
		float tint = hash(p * 1.37 + vec2(3.0, 91.0));
		vec3 star = tint < 0.5 ? vec3(0.85, 0.9, 1.0) : (tint < 0.8 ? vec3(1.0, 0.95, 0.8) : vec3(1.0, 0.75, 0.5));
		float twinkle = 0.75 + 0.25 * sin(clock * (1.0 + tint * 3.0) + h * 200.0);
		total += star * (0.25 + 0.75 * bright) * twinkle * (0.45 + 0.8 * band);
	}
	// Low down near the hills the light is lost in the haze.
	total *= smoothstep(horizon - 2.0, horizon - 36.0, p.y);
	COLOR = vec4(total * amount, 1.0);
}
