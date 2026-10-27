shader_type canvas_item;
render_mode blend_add;
// The Milky Way on a dark, moonless night: a broad arch of light from one side of the sky to the other, swelling to a
// glowing golden heart low over the hills, bluish and violet along its arms, with rose-red clouds of glowing gas,
// dark rifts of dust and a crowd of coloured stars. Worked out per sky pixel, so it keeps the sky's pixel grid.

uniform float amount = 0.0;
// The sprite's size and top left corner in sky pixels.
uniform vec2 area = vec2(1536.0, 400.0);
uniform vec2 origin = vec2(0.0, -120.0);
uniform float clock = 0.0;
// Where the arch meets the hills and how high it climbs.
uniform float horizon = 205.0;
uniform float rise = 185.0;
// Where along the arch, from 0 to 1, the bright heart of the galaxy sits.
uniform float heart = 0.3;

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
	float along = p.x / area.x;
	float centre = horizon - rise * sin(3.14159 * along);
	float across = p.y - centre;
	// The band is broadest and brightest around the heart, and thins towards its ends.
	float swell = exp(-pow((along - heart) / 0.16, 2.0));
	float width = 30.0 + 26.0 * swell + 6.0 * sin(p.x * 0.011);
	float band = exp(-pow(across / width, 2.0));
	float inner = exp(-pow(across / (width * 0.42), 2.0));
	// Billowing star clouds, so the light gathers in clumps rather than an even smear.
	float clouds = fbm(p * vec2(0.014, 0.022) + vec2(3.1, 7.7));
	float detail = fbm(p * vec2(0.05, 0.07) + vec2(9.4, 1.2));
	float light = band * (0.25 + 1.1 * clouds * clouds) + inner * (0.4 + 0.6 * detail) * (0.5 + swell);
	// Dark rifts of dust: one long lane along the middle and wisps branching off it.
	float wander = (fbm(p * vec2(0.008, 0.02) + vec2(11.0, 2.0)) - 0.5) * 18.0;
	float rift = exp(-pow((across - 3.0 + wander) / (4.0 + 5.0 * swell), 2.0));
	float wisps = smoothstep(0.55, 0.75, fbm(p * vec2(0.03, 0.045) + vec2(5.0, 9.0))) * band;
	light *= 1.0 - 0.8 * clamp(rift * (0.6 + 0.4 * swell) + wisps * 0.7, 0.0, 1.0);
	// Colour: violet and blue along the faint arms, white-gold towards the middle of the band, a glowing amber heart.
	vec3 arm = mix(vec3(0.32, 0.36, 0.95), vec3(0.62, 0.42, 0.95), smoothstep(0.35, 0.7, noise(p * 0.01)));
	vec3 colour = mix(arm, vec3(1.0, 0.94, 0.86), clamp(inner * 1.3, 0.0, 1.0));
	colour = mix(colour, vec3(1.0, 0.72, 0.38), clamp(inner * swell * 1.6, 0.0, 1.0));
	vec3 total = colour * light * 0.75;
	// Rose-red clouds of glowing gas scattered along the band.
	float gas = smoothstep(0.6, 0.78, fbm(p * 0.03 + vec2(17.0, 4.0))) * band;
	total += vec3(0.95, 0.28, 0.45) * gas * 0.45;
	// A soft halo around the heart, as if the light is too much for the air.
	total += vec3(0.9, 0.6, 0.35) * swell * exp(-pow(across / (width * 1.6), 2.0)) * 0.12;
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
