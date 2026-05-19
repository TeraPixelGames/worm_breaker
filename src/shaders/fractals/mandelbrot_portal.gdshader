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
uniform float device_audio_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float audio_bass : hint_range(0.0, 1.0) = 0.0;
uniform float audio_mid : hint_range(0.0, 1.0) = 0.0;
uniform float audio_treble : hint_range(0.0, 1.0) = 0.0;
uniform float depth_strength : hint_range(0.0, 2.0) = 1.0;
uniform float volumetric_glow : hint_range(0.0, 2.0) = 0.75;

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

vec3 mandelbrot_palette(float f, vec2 color_uv, float audio_drive) {
	float decay = max(0.0, 50.0 - (1.0 + audio_drive * 8.0));
	float ff = pow(f, 1.0 - (f * decay));
	float band = smoothstep(0.0, 1.0, ff);
	vec3 col = vec3(0.0);
	col.r = band * (color_uv.x * 0.5 + 0.5);
	col.b = band * (color_uv.y * 0.5 + 0.5);
	col.g = band * (-color_uv.x * 0.5 + 0.5);
	col += vec3(0.18, 0.38, 1.0) * audio_bass * band * 0.24;
	col += vec3(1.0, 0.24, 0.85) * audio_mid * band * 0.18;
	col += vec3(1.0, 0.95, 0.28) * audio_treble * band * 0.14;
	return col;
}

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	vec2 color_uv = uv;
	float radial_mask = smoothstep(1.04, 0.72, length(uv));
	float audio_drive = clamp(device_audio_pulse * 0.58 + audio_bass * 0.28 + audio_mid * 0.24 + audio_treble * 0.18, 0.0, 1.0);
	float zoom_progress = 1.0 - exp(-portal_phase * 0.16);
	float local_time = 1.0 + zoom_progress * 42.0;
	float animated_zoom = zoom * exp2(zoom_progress * 6.6 + audio_bass * 0.22);
	vec2 focus_drift = vec2(
		sin(portal_phase * (0.71 + audio_mid * 0.16)) + 0.42 * sin(portal_phase * 1.37 + 1.8),
		cos(portal_phase * (0.63 + audio_treble * 0.18)) + 0.36 * sin(portal_phase * 1.11 + 0.4)
	) * 0.0018 * drift * (0.24 + zoom_progress + audio_drive * 0.36);
	vec3 col = vec3(0.0);
	float accumulated_alpha = 0.0;
	for (int layer_index = 0; layer_index < 5; layer_index++) {
		float layer = float(layer_index) / 4.0;
		float parallax = 1.0 + layer * (1.2 + depth_strength * 0.5);
		float layer_zoom = animated_zoom * (1.0 + layer * (0.38 + zoom_progress * 0.28));
		vec2 layer_uv = uv * parallax;
		layer_uv += vec2(
			sin(portal_phase * 0.19 + layer * 4.1),
			cos(portal_phase * 0.16 + layer * 5.0)
		) * layer * 0.08 * drift;
		vec2 c = (layer_uv / layer_zoom) + focus + focus_drift * (1.0 + layer * 1.8);
		int count = mandelbrot(c, recursion_limit);
		if (count < recursion_limit - 1) {
			float f = float(count) / float(recursion_limit);
			float layer_fade = exp(-layer * 1.2) * smoothstep(1.18, 0.12, length(layer_uv));
			vec3 layer_color = mandelbrot_palette(f, color_uv + layer_uv * 0.12, audio_drive);
			col += layer_color * layer_fade * (0.52 + layer * 0.38);
			accumulated_alpha += layer_fade * smoothstep(0.08, 0.86, f);
		}
	}
	float core_well = pow(max(0.0, 1.0 - length(uv)), 4.0) * (1.0 + audio_drive * 0.5);
	col += vec3(0.35, 0.82, 1.0) * core_well * volumetric_glow;
	col += vec3(1.0, 0.34, 0.92) * radial_mask * audio_mid * 0.16;

	ALBEDO = col * radial_mask;
	EMISSION = col * radial_mask * (1.85 + audio_drive * 0.95 + volumetric_glow * 0.22);
	ALPHA = alpha * radial_mask * clamp(0.5 + accumulated_alpha * 0.22 + audio_drive * 0.18 + depth_strength * 0.08, 0.0, 1.25);
}
