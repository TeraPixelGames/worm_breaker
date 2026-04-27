/*
Converted for Godot from pedrotrschneider/shader-fractals.
Original: 2D/JuliaSet.glsl
Copyright (c) 2020 Pedro Tonini Rosenberg Schneider, MIT License.
*/
shader_type canvas_item;

uniform vec2 constant_a = vec2(0.355, 0.355);
uniform vec2 constant_b = vec2(-0.4, -0.59);
uniform float alpha : hint_range(0.0, 1.0) = 0.46;
uniform float zoom : hint_range(0.4, 4.0) = 1.15;
uniform float speed : hint_range(0.0, 3.0) = 0.65;
uniform int recursion_limit : hint_range(24, 160) = 96;

int julia_set(vec2 c, vec2 constant, int limit) {
	vec2 z = c;
	int count = 0;
	for (int i = 0; i < 160; i++) {
		if (i >= limit) {
			break;
		}
		z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + constant;
		count = i;
		if (length(z) > 2.0) {
			break;
		}
	}
	return count;
}

void fragment() {
	vec2 aspect = vec2(max(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 0.0001), 1.0);
	vec2 uv = (UV - 0.5) * 2.0 * aspect / zoom;
	float a = 1.0471975512 + sin(TIME * 0.23 * speed) * 0.45;
	vec2 basis_u = vec2(cos(a), sin(a));
	vec2 basis_v = vec2(-basis_u.y, basis_u.x);
	uv = vec2(dot(uv, basis_u), dot(uv, basis_v)) * 0.9;
	vec2 constant = mix(constant_a, constant_b, 0.5 + 0.5 * sin(TIME * 0.17 * speed));
	int count = julia_set(uv, constant, recursion_limit);
	float f = float(count) / float(recursion_limit);
	float ff = pow(f, 1.0 - f);
	vec3 col = vec3(
		smoothstep(0.0, 1.0, ff) * (uv.x * 0.5 + 0.5),
		smoothstep(0.0, 1.0, ff) * (-uv.x * 0.5 + 0.5),
		smoothstep(0.0, 1.0, ff) * (uv.y * 0.5 + 0.5)
	);
	col *= 2.8 + 1.4 * sin(TIME * 0.7);
	COLOR = vec4(col, alpha * smoothstep(0.02, 0.8, ff));
}
