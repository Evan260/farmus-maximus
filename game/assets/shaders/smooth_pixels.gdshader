shader_type canvas_item;
// Keeps pixel art crisp while it moves by fractions of a screen pixel: each art pixel stays a sharp block, and only
// the one-screen-pixel seam between two art pixels is blended. Needs the texture drawn with linear filtering.

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 texel = UV * size;
	vec2 seam = floor(texel + 0.5);
	vec2 width = fwidth(texel);
	texel = seam + clamp((texel - seam) / width, -0.5, 0.5);
	COLOR = texture(TEXTURE, texel / size) * COLOR;
}
