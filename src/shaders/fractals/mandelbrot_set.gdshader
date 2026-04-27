/*
Converted for Godot from pedrotrschneider/shader-fractals.
Original: 2D/MandelbrotSet.glsl
Copyright (c) 2020 Pedro Tonini Rosenberg Schneider, MIT License.
*/
shader_type canvas_item;

uniform vec2 focus = vec2(-0.745428, 0.113009);
uniform float alpha : hint_range(0.0, 1.0) = 0.42;
uniform float zoom : hint_range(0.4, 40.0) = 2.4;
uniform float drift : hint_range(0.0, 2.0) = 0.35;
uniform int recursion_limit : hint_range(24, 160) = 96;

int mandelbrot(vec2 c, int limit) {
	vec2 z = vec2(0.0);
	int count = 0;
	for (int i = 0; i < 160; i++) {
		if (i >= limit) {
			break;
		}
		z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
		count = i;
		if (length(z) > 2.0) {
			break;
		}
	}
	return count;
}

void fragment() {
	vec2 aspect = vec2(max(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 0.0001), 1.0);
	vec2 uv = (UV - 0.5) * 2.0 * aspect;
	float animated_zoom = zoom * (1.0 + 0.18 * sin(TIME * 0.16));
	vec2 c = uv / animated_zoom + focus + vec2(sin(TIME * 0.07), cos(TIME * 0.05)) * 0.018 * drift;
	int count = mandelbrot(c, recursion_limit);
	float f = float(count) / float(recursion_limit);
	float edge = smoothstep(0.02, 0.95, f);
	float glow = pow(edge, 0.48);
	vec3 col = vec3(
		0.25 + 0.75 * sin(f * 9.0 + TIME * 0.4),
		0.35 + 0.65 * sin(f * 7.0 + 2.1),
		0.55 + 0.45 * sin(f * 11.0 + 4.2)
	);
	if (count >= recursion_limit - 1) {
		col *= 0.08;
		glow *= 0.4;
	}
	COLOR = vec4(col * glow, alpha * glow);
}
