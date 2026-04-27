/*
Converted for Godot from pedrotrschneider/shader-fractals.
Original: 2D/KochCurve.glsl
Copyright (c) 2020 Pedro Tonini Rosenberg Schneider, MIT License.
*/
shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 0.22, 0.86, 1.0);
uniform vec4 glow_color : source_color = vec4(0.06, 0.95, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.48;
uniform float zoom : hint_range(0.3, 4.0) = 0.95;
uniform float speed : hint_range(0.0, 4.0) = 0.6;
uniform int max_steps : hint_range(0, 7) = 5;

const float FRACTAL_PI = 3.141592653589793238;

vec2 polar_to_cartesian(float angle) {
	return vec2(sin(angle), cos(angle));
}

vec2 fold_reflect(vec2 uv, vec2 p, float angle) {
	vec2 dir = polar_to_cartesian(angle);
	return uv - dir * min(dot(uv - p, dir), 0.0) * 2.0;
}

float koch_curve(inout vec2 uv, int steps) {
	float scale = 1.25;
	uv *= scale;
	uv.y -= sqrt(3.0) / 6.0;
	uv.x = abs(uv.x);
	uv = fold_reflect(uv, vec2(0.5, 0.0), 11.0 / 6.0 * FRACTAL_PI);
	uv.x += 0.5;

	for (int i = 0; i < 7; i++) {
		if (i >= steps) {
			break;
		}
		uv.x -= 0.5;
		scale *= 3.0;
		uv *= 3.0;
		uv.x = abs(uv.x);
		uv.x -= 0.5;
		uv = fold_reflect(uv, vec2(0.0), (2.0 / 3.0) * FRACTAL_PI);
	}

	uv.x = abs(uv.x);
	float d = length(uv - vec2(min(uv.x, 1.0), 0.0)) / scale;
	uv /= scale;
	return d;
}

void fragment() {
	vec2 aspect = vec2(max(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 0.0001), 1.0);
	vec2 uv = (UV - 0.5) * 2.0 * aspect / zoom;
	float rotation = sin(TIME * 0.25 * speed) * 0.55;
	mat2 rot = mat2(vec2(cos(rotation), sin(rotation)), vec2(-sin(rotation), cos(rotation)));
	uv = rot * uv;
	int steps = int(mod(TIME * speed, float(max_steps + 1)));
	float d = koch_curve(uv, steps);
	float line = smoothstep(0.01, 0.0, d);
	float glow = smoothstep(0.13, 0.0, d);
	vec3 col = line_color.rgb * line * 1.8 + glow_color.rgb * glow * 0.42;
	COLOR = vec4(col, alpha * max(line, glow * 0.58));
}
