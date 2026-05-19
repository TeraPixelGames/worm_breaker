/*
Crystal block material for Worm Breaker.
Uses object-space facets and fresnel lighting to keep bricks readable in the tunnel.
*/
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 crystal_color : source_color = vec4(0.2, 0.9, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.24, 0.95, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float facet_scale : hint_range(2.0, 18.0) = 8.0;
uniform float facet_strength : hint_range(0.0, 1.0) = 0.45;
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform float time_phase = 0.0;
uniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;

float hash31(vec3 p) {
	p = fract(p * vec3(123.34, 456.21, 789.43));
	p += dot(p, p.yzx + 37.19);
	return fract((p.x + p.y) * p.z);
}

float facet_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(cell + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, u.x);
	float nx10 = mix(n010, n110, u.x);
	float nx01 = mix(n001, n101, u.x);
	float nx11 = mix(n011, n111, u.x);
	return mix(mix(nx00, nx10, u.y), mix(nx01, nx11, u.y), u.z);
}

void fragment() {
	vec3 local_pos = VERTEX;
	float facets = facet_noise(local_pos * facet_scale + vec3(time_phase * 0.18, 0.0, time_phase * 0.09));
	float cut_lines = smoothstep(0.045, 0.0, abs(fract((local_pos.x + local_pos.y * 0.63 + local_pos.z * 0.21) * facet_scale) - 0.5));
	float internal_band = smoothstep(0.78, 1.0, sin((local_pos.x - local_pos.y + local_pos.z) * 10.0 + time_phase * 1.7) * 0.5 + 0.5);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.8);
	float damage_glow = 1.0 - clamp(hp_ratio, 0.0, 1.0);

	vec3 base = mix(crystal_color.rgb * 0.56, crystal_color.rgb, facets * facet_strength + 0.22);
	base = mix(base, core_color.rgb, internal_band * (0.18 + damage_glow * 0.2));
	base += crystal_color.rgb * cut_lines * 0.28;
	base += core_color.rgb * fresnel * (0.42 + damage_glow * 0.36);
	base = mix(base, flash_color.rgb, clamp(flash_strength, 0.0, 1.0));

	ALBEDO = base;
	ROUGHNESS = 0.18;
	METALLIC = 0.0;
	SPECULAR = 0.82;
	EMISSION = base * (0.34 + fresnel * 0.86 + cut_lines * 0.32 + internal_band * 0.22 + flash_strength * 1.3);
}
