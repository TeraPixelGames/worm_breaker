/*
Wrapped fractal tunnel shader for Worm Breaker.
Provides depth bands and angular landmarks on the cylinder wall.
*/
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform float tunnel_phase = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;
uniform float device_audio_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float audio_bass : hint_range(0.0, 1.0) = 0.0;
uniform float audio_mid : hint_range(0.0, 1.0) = 0.0;
uniform float audio_treble : hint_range(0.0, 1.0) = 0.0;
uniform float projectm_overlay_strength : hint_range(0.0, 1.0) = 0.32;
uniform float layout_depth_scale : hint_range(8.0, 30.0) = 18.0;
uniform float layout_angle_repeats : hint_range(4.0, 18.0) = 9.0;
uniform float layout_spoke_repeats : hint_range(4.0, 24.0) = 12.0;
uniform float layout_kaleido_segments : hint_range(4.0, 24.0) = 12.0;
uniform float layout_circuit_density : hint_range(12.0, 72.0) = 40.0;
uniform float layout_ring_frequency : hint_range(0.35, 1.2) = 0.72;
uniform sampler2D previous_background_texture : repeat_enable, filter_linear_mipmap;
uniform sampler2D target_background_texture : repeat_enable, filter_linear_mipmap;
uniform float background_texture_blend : hint_range(0.0, 1.0) = 1.0;
uniform float previous_background_strength : hint_range(0.0, 1.0) = 0.0;
uniform float target_background_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 previous_background_scale = vec2(1.0, 1.0);
uniform vec2 target_background_scale = vec2(1.0, 1.0);
uniform float previous_background_scroll = 0.0;
uniform float target_background_scroll = 0.0;
uniform vec4 base_color : source_color = vec4(0.018, 0.0, 0.055, 1.0);
uniform vec4 near_color : source_color = vec4(0.02, 0.9, 0.95, 1.0);
uniform vec4 far_color : source_color = vec4(1.0, 0.1, 0.95, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		value += noise(p) * amp;
		p = p * 2.05 + vec2(7.3, 3.1);
		amp *= 0.5;
	}
	return value;
}

vec3 palette(float t) {
	vec3 a = base_color.rgb;
	vec3 b = mix(near_color.rgb, far_color.rgb, 0.5 + 0.5 * sin(t * 6.28318 + hue_shift * 6.28318));
	return mix(a, b, clamp(t, 0.0, 1.0));
}

float neon_band(float value, float width) {
	float distance_to_center = abs(fract(value) - 0.5);
	return 1.0 - smoothstep(width, width + 0.035, distance_to_center);
}

float neon_line(float value, float width) {
	return 1.0 - smoothstep(width, width + 0.018, abs(value));
}

void fragment() {
	vec2 uv = UV;
	float theta = uv.x;
	float depth = uv.y * layout_depth_scale - tunnel_phase;
	vec2 wrapped = vec2(theta * layout_angle_repeats, depth);

	float fractal = fbm(wrapped * 0.72 + vec2(sin(depth * 0.11), cos(theta * 6.28318)) * 0.8);
	float ring_wave = abs(sin(depth * 3.14159));
	float depth_rings = smoothstep(0.86, 1.0, ring_wave);
	float angular_lines = smoothstep(0.965, 1.0, abs(sin(theta * 6.28318 * layout_spoke_repeats + fractal * 1.4)));
	float beat_wave = abs(sin(depth * 3.14159 - device_audio_pulse * 2.4 - audio_bass * 1.2));
	float beat_rings = smoothstep(0.62 - device_audio_pulse * 0.22 - audio_bass * 0.12, 1.0, beat_wave) * max(device_audio_pulse, audio_bass * 0.72);
	float mid_landmarks = smoothstep(0.94 - audio_mid * 0.12, 1.0, abs(sin(theta * 6.28318 * 5.0 + depth * 0.6))) * audio_mid;
	float treble_sparks = smoothstep(0.72, 1.0, noise(wrapped * 7.4 + vec2(audio_treble * 11.0, tunnel_phase * 1.8))) * audio_treble;
	float flow = smoothstep(0.38, 0.9, fractal);
	float trace = max(max(depth_rings * (0.56 + audio_bass * 0.32), angular_lines * (0.34 + audio_treble * 0.28)), max(beat_rings * 0.42, mid_landmarks * 0.42));
	float brightness = clamp((flow * 0.52 + trace) * intensity, 0.0, 1.35);

	vec3 color = palette(brightness + fractal * 0.14);
	color += near_color.rgb * depth_rings * 0.18 * intensity;
	color += far_color.rgb * angular_lines * (0.10 + audio_treble * 0.18) * intensity;
	color += near_color.rgb * mid_landmarks * 0.24 * intensity;
	color += mix(near_color.rgb, far_color.rgb, 0.35) * beat_rings * 0.24 * intensity;
	color += far_color.rgb * treble_sparks * 0.26 * intensity;

	float audio_drive = clamp(device_audio_pulse * 0.55 + audio_bass * 0.38 + audio_mid * 0.22 + audio_treble * 0.18, 0.0, 1.0);
	float kaleido_theta = abs(fract(theta * layout_kaleido_segments + sin(depth * 0.065 + tunnel_phase * 0.16) * 0.22) - 0.5) * 2.0;
	float mirrored_theta = min(kaleido_theta, 1.0 - kaleido_theta);
	float warped_depth = depth + fbm(vec2(theta * 18.0, depth * 0.28 + tunnel_phase * 0.2)) * (0.9 + audio_mid * 0.7);
	float bass_ring_phase = warped_depth * (layout_ring_frequency + audio_bass * 0.38) - audio_bass * 0.9 - device_audio_pulse * 1.4;
	float neon_rings = neon_band(bass_ring_phase, 0.036 + audio_bass * 0.032 + device_audio_pulse * 0.022);
	float radial_spokes = neon_line(mirrored_theta - 0.18 - sin(warped_depth * 0.24) * 0.04, 0.016 + audio_treble * 0.018);
	float secondary_spokes = neon_line(mirrored_theta - 0.42 + cos(warped_depth * 0.19) * 0.035, 0.012 + audio_mid * 0.014);
	vec2 circuit_cell = floor(vec2(theta * layout_circuit_density + audio_mid * 4.0, warped_depth * 2.35));
	float circuit_gate = smoothstep(0.48 - audio_mid * 0.16, 0.9, hash21(circuit_cell));
	float circuit_blocks = neon_band(theta * layout_circuit_density + floor(warped_depth * 1.1) * 0.13, 0.17) * neon_band(warped_depth * 2.35, 0.13 + audio_mid * 0.04) * circuit_gate;
	float chroma_scan = neon_band(warped_depth * 5.2 + theta * 3.0 + audio_treble * 1.8, 0.028 + audio_treble * 0.024) * (0.35 + audio_treble * 0.95);
	float center_glow = smoothstep(0.56, 0.0, abs(mirrored_theta - 0.5)) * smoothstep(0.35, 1.0, neon_rings + audio_drive);
	float projectm_mask = clamp(neon_rings * 0.46 + radial_spokes * 0.5 + secondary_spokes * 0.32 + circuit_blocks * 0.72 + chroma_scan * 0.38 + center_glow * 0.24, 0.0, 1.65);
	float overlay_mix = projectm_overlay_strength * (0.32 + audio_drive * 0.34);
	vec3 projectm_color = vec3(0.0);
	projectm_color += near_color.rgb * neon_rings * (0.55 + audio_bass * 0.75);
	projectm_color += far_color.rgb * radial_spokes * (0.48 + audio_treble * 0.9);
	projectm_color += vec3(0.35, 1.0, 0.12) * circuit_blocks * (0.35 + audio_mid * 0.86);
	projectm_color += vec3(1.0, 0.16, 0.72) * chroma_scan * (0.32 + audio_treble * 0.78);
	projectm_color += vec3(0.18, 0.45, 1.0) * secondary_spokes * (0.28 + audio_mid * 0.5);
	projectm_color += vec3(1.0, 0.95, 0.28) * beat_rings * audio_drive * 0.52;
	color += projectm_color * overlay_mix;

	vec2 previous_bg_uv = fract(vec2(theta * previous_background_scale.x, uv.y * previous_background_scale.y - tunnel_phase * previous_background_scroll));
	vec2 target_bg_uv = fract(vec2(theta * target_background_scale.x, uv.y * target_background_scale.y - tunnel_phase * target_background_scroll));
	vec3 previous_bg = texture(previous_background_texture, previous_bg_uv).rgb * previous_background_strength;
	vec3 target_bg = texture(target_background_texture, target_bg_uv).rgb * target_background_strength;
	vec3 background = mix(previous_bg, target_bg, background_texture_blend);
	float background_luma = dot(background, vec3(0.2126, 0.7152, 0.0722));
	color = mix(color, max(color, background * (0.72 + audio_drive * 0.32)), clamp(background_luma * 1.35, 0.0, 0.82));
	color += background * (0.18 + audio_drive * 0.18);

	ALBEDO = mix(base_color.rgb, color, 0.72);
	EMISSION = color * (0.45 + brightness * 1.35 + projectm_mask * overlay_mix * 0.58 + device_audio_pulse * 0.72 + audio_bass * 0.48 + audio_mid * 0.24 + audio_treble * 0.36 + background_luma * 0.28);
}
