shader_type canvas_item;
// Plants and trees lean with the wind: the top of the sprite shifts by whole pixels, so the art stays crisp.

uniform float height = 32.0;
uniform float strength = 1.0;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float top = 1.0 - clamp(VERTEX.y / height, 0.0, 1.0);
	// Two slow waves at different scales roll across the estate, so neighbouring plants move together like a field in wind.
	float wave = sin(TIME * 1.6 - world.x * 0.05) * 0.6 + sin(TIME * 0.7 - world.x * 0.013) * 0.4;
	VERTEX.x += floor(wave * strength * top + 0.5);
}
