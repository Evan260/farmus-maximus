shader_type canvas_item;
// Morning mist over the estate: soft wisps of drifting noise, lying thickest in the valleys behind the aqueduct and
// thinly over the fields, thinning out above the hills. Worked out in estate pixels so it pans with the land.

uniform float amount = 0.0;
uniform vec2 view_size = vec2(480.0, 270.0);
// The estate point at the view's top left corner.
uniform vec2 camera = vec2(0.0);
uniform vec4 tint : source_color = vec4(0.94, 0.94, 0.97, 1.0);
uniform float motion = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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
		p = p * 2.03 + vec2(17.1, 3.7);
		weight *= 0.5;
	}
	return total;
}

void fragment() {
	vec2 world = camera + floor(UV * view_size);
	float t = TIME * motion;
	// Mist is wide and flat, so the noise is stretched sideways; two layers drift at different speeds.
	vec2 p = world / vec2(70.0, 14.0);
	float slow = fbm(p + vec2(t * 0.025, 0.0));
	float quick = fbm(p * 1.8 + vec2(-t * 0.045, t * 0.006) + 9.2);
	float wisps = smoothstep(0.3, 0.75, slow * 0.65 + quick * 0.45);
	float y = world.y;
	float valley = exp(-pow((y - 222.0) / 16.0, 2.0));
	float hills = exp(-pow((y - 200.0) / 16.0, 2.0)) * 0.8;
	float fields = smoothstep(232.0, 262.0, y) * 0.45;
	float density = (valley + hills + fields) * (0.3 + 0.9 * wisps);
	COLOR = vec4(tint.rgb, clamp(density * amount * 0.62, 0.0, 0.72));
}
