/*
Mandelbrot portal shader for 3D tunnel end caps.
Converted for Godot from pedrotrschneider/shader-fractals 2D/MandelbrotSet.glsl.
Copyright (c) 2020 Pedro Tonini Rosenberg Schneider, MIT License.
*/
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec2 focus = vec2(-0.745428, 0.113009);
uniform float alpha : hint_range(0.0, 1.0) = 0.54;
uniform float zoom : hint_range(0.4, 40.0) = 2.4;
uniform float drift : hint_range(0.0, 2.0) = 0.35;
uniform float portal_phase = 0.0;
uniform int recursion_limit : hint_range(24, 260) = 128;

int mandelbrot(vec2 c, int limit) {
	vec2 z = vec2(0.0);
	int count = 0;
	for (int i = 0; i < 260; i++) {
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
	vec2 uv = (UV - 0.5) * 2.0;
	vec2 color_uv = uv;
	float radial_mask = smoothstep(1.04, 0.72, length(uv));
	float zoom_progress = 1.0 - exp(-portal_phase * 0.16);
	float local_time = 1.0 + zoom_progress * 42.0;
	float animated_zoom = zoom * exp2(zoom_progress * 6.6);
	vec2 focus_drift = vec2(
		sin(portal_phase * 0.71) + 0.42 * sin(portal_phase * 1.37 + 1.8),
		cos(portal_phase * 0.63) + 0.36 * sin(portal_phase * 1.11 + 0.4)
	) * 0.0018 * drift * (0.24 + zoom_progress);
	vec2 c = (uv / animated_zoom) + focus + focus_drift;

	int count = mandelbrot(c, recursion_limit);
	float f = float(count) / float(recursion_limit);
	vec3 col = vec3(1.0);

	if (count >= recursion_limit - 1) {
		col = vec3(0.0);
	} else {
		float decay = max(0.0, 50.0 - local_time);
		float ff = pow(f, 1.0 - (f * decay));
		float band = smoothstep(0.0, 1.0, ff);
		col.r = band * (color_uv.x * 0.5 + 0.5);
		col.b = band * (color_uv.y * 0.5 + 0.5);
		col.g = band * (-color_uv.x * 0.5 + 0.5);
	}

	ALBEDO = col * radial_mask;
	EMISSION = col * radial_mask * 1.75;
	ALPHA = alpha * radial_mask;
}
