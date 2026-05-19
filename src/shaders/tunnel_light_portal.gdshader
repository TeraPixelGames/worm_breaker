/*
Stage-rotating tunnel end light for Worm Breaker.
Original Godot shader inspired by neon rays, flowing wire arcs, and volumetric grid glow.
*/
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform int portal_variant = 0;
uniform float alpha : hint_range(0.0, 1.0) = 0.66;
uniform float zoom : hint_range(0.3, 8.0) = 2.5;
uniform float drift : hint_range(0.0, 2.0) = 0.5;
uniform float portal_phase = 0.0;
uniform vec4 primary_color : source_color = vec4(0.08, 1.0, 0.9, 1.0);
uniform vec4 secondary_color : source_color = vec4(1.0, 0.12, 0.82, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 0.92, 0.24, 1.0);
uniform float ray_density : hint_range(4.0, 32.0) = 14.0;
uniform float ring_density : hint_range(2.0, 28.0) = 9.0;
uniform float wire_strength : hint_range(0.0, 1.0) = 0.45;
uniform float grid_strength : hint_range(0.0, 1.0) = 0.32;
uniform float device_audio_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float audio_bass : hint_range(0.0, 1.0) = 0.0;
uniform float audio_mid : hint_range(0.0, 1.0) = 0.0;
uniform float audio_treble : hint_range(0.0, 1.0) = 0.0;
uniform float depth_layers : hint_range(2.0, 9.0) = 6.0;
uniform float depth_strength : hint_range(0.0, 2.0) = 1.0;
uniform float volumetric_glow : hint_range(0.0, 2.0) = 0.8;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float line_band(float value, float width) {
	return 1.0 - smoothstep(width, width + 0.035, abs(fract(value) - 0.5));
}

float spoke_line(float angle, float density, float width) {
	return 1.0 - smoothstep(width, width + 0.022, abs(fract(angle * density / 6.2831853) - 0.5));
}

float hex_grid(vec2 p) {
	vec2 q = vec2(p.x * 0.5773503 + p.y, p.x * 1.1547005);
	vec2 cell = floor(q);
	vec2 f = fract(q) - 0.5;
	float h = max(abs(f.x) * 0.86 + abs(f.y) * 0.5, abs(f.y));
	float n = hash21(cell);
	return (1.0 - smoothstep(0.38, 0.48, h)) * (0.62 + n * 0.38);
}

vec3 variant_color(float amount, float radial, float angle, vec2 uv, float time) {
	vec3 color = vec3(0.0);
	float rings = line_band(radial * ring_density - time * 0.24, 0.035);
	float spokes = spoke_line(angle + sin(radial * 4.0 + time) * 0.11, ray_density, 0.022);
	float core = smoothstep(0.78, 0.0, radial);

	if (portal_variant == 1) {
		float wire_a = line_band(uv.x * 3.2 + sin(uv.y * 5.0 + time * 0.8), 0.052);
		float wire_b = line_band(uv.y * 3.0 + cos(uv.x * 4.0 - time * 0.65), 0.046);
		float flow = max(wire_a, wire_b) * wire_strength;
		color += primary_color.rgb * rings * 0.42;
		color += secondary_color.rgb * flow * (0.85 + amount * 0.3);
		color += accent_color.rgb * spokes * 0.18;
		color += mix(primary_color.rgb, secondary_color.rgb, 0.5) * core * 0.52;
	} else if (portal_variant == 2) {
		float grid = hex_grid(uv * (4.5 + zoom * 0.4) + vec2(sin(time * 0.18), cos(time * 0.21)) * drift) * grid_strength;
		float scan = line_band(radial * (ring_density * 1.35) + angle * 0.8 - time * 0.42, 0.026);
		color += primary_color.rgb * grid * 0.92;
		color += secondary_color.rgb * rings * 0.34;
		color += accent_color.rgb * scan * 0.62;
		color += primary_color.rgb * core * 0.44;
	} else {
		float rays = spokes * (0.44 + 0.56 * sin(radial * 8.0 - time * 1.2) * 0.5 + 0.28);
		float bloom = smoothstep(0.88, 0.0, radial) * (0.58 + amount * 0.34);
		color += primary_color.rgb * bloom;
		color += secondary_color.rgb * rays * 0.72;
		color += accent_color.rgb * rings * 0.58;
		color += mix(primary_color.rgb, accent_color.rgb, 0.4) * core * 0.34;
	}
	return color;
}

vec3 portal_depth_volume(vec2 uv, float time, float audio_drive) {
	vec3 volume = vec3(0.0);
	float total_weight = 0.0;
	int layer_count = int(clamp(depth_layers, 2.0, 9.0));
	for (int i = 0; i < 9; i++) {
		if (i >= layer_count) {
			break;
		}
		float layer = float(i) / max(float(layer_count - 1), 1.0);
		float perspective = 1.0 + layer * (1.15 + depth_strength * 0.42);
		float travel = time * (0.12 + layer * 0.18 + audio_mid * 0.035);
		vec2 layer_uv = uv * perspective;
		layer_uv += vec2(
			sin(time * 0.17 + layer * 3.8),
			cos(time * 0.13 + layer * 4.4)
		) * layer * (0.13 + audio_drive * 0.05) * drift;
		float layer_radial = length(layer_uv);
		float layer_angle = atan(layer_uv.y, layer_uv.x);
		float tunnel_slice = line_band(layer_radial * (ring_density * (0.72 + layer * 0.56)) - travel, 0.032 + layer * 0.012);
		float ray_slice = spoke_line(layer_angle + sin(layer_radial * 3.0 - time * 0.22) * 0.16, ray_density * (0.72 + layer * 0.38), 0.018 + layer * 0.004);
		float cell_slice = hex_grid(layer_uv * (2.2 + layer * 3.8) + time * 0.035) * grid_strength;
		float depth_fade = exp(-layer * 1.45) * smoothstep(1.24, 0.08, layer_radial);
		float layer_light = max(tunnel_slice * 0.68, ray_slice * 0.46);
		layer_light = max(layer_light, cell_slice * 0.35);
		vec3 layer_color = mix(primary_color.rgb, secondary_color.rgb, layer * 0.72);
		layer_color = mix(layer_color, accent_color.rgb, tunnel_slice * (0.18 + audio_bass * 0.16));
		volume += layer_color * layer_light * depth_fade;
		total_weight += depth_fade;
	}
	float center_well = pow(max(0.0, 1.0 - length(uv)), 3.0) * (0.55 + audio_drive * 0.35);
	vec3 core_color = mix(primary_color.rgb, accent_color.rgb, 0.42 + audio_treble * 0.18);
	return volume * depth_strength / max(total_weight * 0.42, 0.34) + core_color * center_well * volumetric_glow;
}

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	float radial = length(uv);
	float angle = atan(uv.y, uv.x);
	float time = portal_phase;
	float audio_drive = clamp(device_audio_pulse * 0.62 + audio_bass * 0.36 + audio_mid * 0.24 + audio_treble * 0.22, 0.0, 1.0);
	float mask = smoothstep(1.02, 0.74, radial);
	float vignette = smoothstep(1.0, 0.1, radial);
	float pulse = max(0.5 + 0.5 * sin(time * (1.4 + audio_mid * 0.24) + radial * 10.0), audio_drive);
	vec2 warped = uv * (1.0 + sin(radial * (5.0 + audio_bass * 2.0) - time * 0.45) * (0.04 + audio_drive * 0.045) * drift);
	warped += vec2(sin(time * (0.27 + audio_treble * 0.08)), cos(time * (0.31 + audio_mid * 0.07))) * (0.035 + audio_drive * 0.035) * drift;

	vec3 color = variant_color(pulse, radial, angle, warped, time);
	color += vec3(1.0) * pow(max(0.0, 1.0 - radial), 7.0) * (1.2 + zoom * 0.22 + audio_drive * 0.9);
	color += primary_color.rgb * audio_bass * line_band(radial * (ring_density + 2.0) - time * 0.34, 0.045) * 0.34;
	color += secondary_color.rgb * audio_mid * spoke_line(angle + time * 0.12, ray_density + 3.0, 0.028) * 0.28;
	color += accent_color.rgb * audio_treble * hex_grid(warped * 7.0 + time * 0.12) * 0.22;
	color += portal_depth_volume(warped, time, audio_drive) * (0.62 + audio_drive * 0.38);
	color *= mask * (0.82 + vignette * 0.44 + audio_drive * 0.18);

	ALBEDO = color;
	EMISSION = color * (1.65 + pulse * 0.4 + audio_drive * 0.82 + volumetric_glow * 0.18);
	ALPHA = alpha * mask * (0.92 + audio_drive * 0.14 + depth_strength * 0.08);
}
