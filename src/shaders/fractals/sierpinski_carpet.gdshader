/*
Converted for Godot from pedrotrschneider/shader-fractals.
Original: 2D/SierpinskiCarpet.glsl
Copyright (c) 2020 Pedro Tonini Rosenberg Schneider, MIT License.
*/
shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.05, 1.0, 0.82, 1.0);
uniform vec4 color_b : source_color = vec4(0.92, 0.04, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.45;
uniform float zoom : hint_range(0.25, 3.0) = 0.75;
uniform float speed : hint_range(0.0, 4.0) = 0.55;
uniform int max_steps : hint_range(1, 7) = 5;

float sierpinski_carpet(inout vec2 uv, int steps) {
	float scale = 4.0;
	uv *= 4.0;
	uv = abs(uv);
	for (int i = 0; i < 7; i++) {
		if (i >= steps) {
			break;
		}
		scale *= 3.0;
		uv *= 3.0;
		uv = abs(uv);
		uv *= 1.0 - step(uv.x, 3.0) * step(uv.y, 3.0);
		uv -= vec2(0.0, 3.0);
		uv = abs(uv);
		uv -= vec2(0.0, 3.0);
		uv = abs(uv);
		uv -= vec2(3.0, 0.0);
		uv = abs(uv);
		uv -= vec2(3.0, 0.0);
		uv = abs(uv);
	}
	float d = length(uv - min(uv, vec2(1.0))) / scale;
	uv /= scale;
	return d;
}

void fragment() {
	vec2 aspect = vec2(max(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 0.0001), 1.0);
	vec2 uv = (UV - 0.5) * 2.0 * aspect / zoom;
	float wave = sin(TIME * speed) * 0.12;
	mat2 rot = mat2(vec2(cos(wave), sin(wave)), vec2(-sin(wave), cos(wave)));
	uv = rot * uv;
	vec2 color_uv = uv;
	int steps = int(mod(TIME * speed, float(max_steps))) + 1;
	float d = sierpinski_carpet(uv, steps);
	float line = smoothstep(0.012, 0.0, d);
	float aura = smoothstep(0.09, 0.0, d);
	vec3 palette = mix(color_a.rgb, color_b.rgb, 0.5 + 0.5 * sin(color_uv.x * 2.2 + TIME * 0.7));
	COLOR = vec4(palette * (line * 1.45 + aura * 0.36), alpha * max(line, aura * 0.55));
}
