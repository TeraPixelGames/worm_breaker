/*
Converted for Godot from pedrotrschneider/shader-fractals.
Original: 2D/SierpinskiTriangle.glsl
Copyright (c) 2020 Pedro Tonini Rosenberg Schneider, MIT License.
*/
shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(1.0, 0.08, 0.88, 1.0);
uniform vec4 color_b : source_color = vec4(0.0, 0.95, 1.0, 1.0);
uniform vec4 color_c : source_color = vec4(1.0, 0.82, 0.08, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.55;
uniform float zoom : hint_range(0.4, 4.0) = 1.0;
uniform float speed : hint_range(0.0, 4.0) = 0.7;
uniform int max_steps : hint_range(1, 9) = 7;

const float FRACTAL_PI = 3.141592653589793238;

vec2 polar_to_cartesian(float angle) {
	return vec2(sin(angle), cos(angle));
}

vec2 fold_reflect(vec2 uv, vec2 p, float angle) {
	vec2 dir = polar_to_cartesian(angle);
	return uv - dir * min(dot(uv - p, dir), 0.0) * 2.0;
}

float signed_dist_triangle(vec2 p) {
	float sqrt3 = sqrt(3.0);
	p.x = abs(p.x) - 1.0;
	p.y = p.y + 1.0 / sqrt3;
	if (p.x + sqrt3 * p.y > 0.0) {
		p = vec2(p.x - sqrt3 * p.y, -sqrt3 * p.x - p.y) / 2.0;
	}
	p.x -= clamp(p.x, -2.0, 0.0);
	return -length(p) * sign(p.y);
}

float sierpinski_triangle(inout vec2 uv, int steps) {
	float scale = 0.9;
	uv *= scale;
	for (int i = 0; i < 9; i++) {
		if (i >= steps) {
			break;
		}
		scale *= 2.0;
		uv *= 2.0;
		uv.y -= 2.0 * sqrt(3.0) / 3.0;
		uv.x = abs(uv.x);
		uv = fold_reflect(uv, vec2(1.0, -sqrt(3.0) / 3.0), (11.0 / 6.0) * FRACTAL_PI);
	}
	float d = signed_dist_triangle(uv) / scale;
	uv /= scale;
	return d;
}

void fragment() {
	vec2 aspect = vec2(max(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 0.0001), 1.0);
	vec2 uv = (UV - 0.5) * 2.0 * aspect / zoom;
	vec2 color_uv = uv;
	float rotation = TIME * 0.12 * speed;
	mat2 rot = mat2(vec2(cos(rotation), sin(rotation)), vec2(-sin(rotation), cos(rotation)));
	uv = rot * (uv + vec2(0.0, 0.22));

	int steps = int(mod(TIME * speed, float(max_steps))) + 1;
	float d = sierpinski_triangle(uv, steps);
	float line = smoothstep(0.012, 0.0, abs(d));
	float aura = smoothstep(0.12, 0.0, abs(d));
	vec3 palette = mix(color_a.rgb, color_b.rgb, color_uv.x * 0.5 + 0.5);
	palette = mix(palette, color_c.rgb, color_uv.y * 0.5 + 0.5);
	COLOR = vec4(palette * (line * 1.6 + aura * 0.42), alpha * max(line, aura * 0.72));
}
