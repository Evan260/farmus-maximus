shader_type canvas_item;
// Recolours a cloud for the hour: its bright parts take the colour of the light, its shadows the colour of the sky's
// shade, so the same cloud is white at noon, gold at sunset and blue-grey at night. It is sampled so that each art
// pixel stays a crisp block while the cloud drifts by fractions of a screen pixel.

uniform vec4 light : source_color = vec4(1.0);
uniform vec4 shade : source_color = vec4(0.72, 0.76, 0.9, 1.0);

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 texel = UV * size;
	vec2 seam = floor(texel + 0.5);
	vec2 width = max(fwidth(texel), vec2(0.0001));
	texel = seam + clamp((texel - seam) / width, -0.5, 0.5);
	vec4 c = texture(TEXTURE, texel / size);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float k = smoothstep(0.45, 0.97, l);
	COLOR = vec4(mix(shade.rgb, light.rgb, k), c.a * COLOR.a);
}
