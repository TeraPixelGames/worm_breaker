/*
Transparent signal gate boundary for Worm Breaker.
Electric current pattern adapted from "Procedural Electric Current Shader"
by arlez80, MIT License.
Source: https://godotshaders.com/shader/procedural-electric-current-shader/
*/
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform float gate_time = 0.0;
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;
uniform float break_progress : hint_range(0.0, 1.0) = 0.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.56;
uniform vec4 gate_color : source_color = vec4(0.05, 1.0, 0.95, 1.0);
uniform vec4 hit_color : source_color = vec4(1.0, 0.92, 0.18, 1.0);
uniform vec4 break_color : source_color = vec4(1.0, 0.08, 0.85, 1.0);

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 uv) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 6; i++) {
		value += amplitude * noise(uv);
		uv *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

float electric_thread(vec2 uv, float phase, float offset) {
	vec2 sample_uv = uv * vec2(1.4, 2.8);
	sample_uv.y += phase * 4.8 + offset;
	float current_noise = noise(sample_uv * 5.0);
	float current = cos((uv.x + current_noise * 0.92 + sin(phase * 1.3 + offset) * 0.18) * 24.0);
	return smoothstep(0.64, 1.0, current);
}

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	float radius = length(uv);
	float disc = smoothstep(1.02, 0.86, radius);
	float transparent_core = smoothstep(0.04, 0.78, radius);
	float rim = smoothstep(1.0, 0.92, radius) - smoothstep(0.86, 0.72, radius);

	float angle = atan(uv.y, uv.x);
	float impact_age = 1.0 - hit_strength;
	vec2 angular_uv = vec2(angle / 6.2831853, radius);
	float primary_current = electric_thread(angular_uv, gate_time * 3.2, 0.0);
	float counter_current = electric_thread(vec2(-angular_uv.x, angular_uv.y * 1.18), gate_time * 2.6, 4.7);
	float radial_noise = fbm(vec2(angle * 2.4, radius * 8.5 - gate_time * 5.0));
	float branching = smoothstep(0.68, 0.98, abs(sin(angle * 11.0 + radius * 13.0 + radial_noise * 7.0 + gate_time * 10.0)));
	float collision_current = max(primary_current, counter_current * 0.8) * branching;
	collision_current *= smoothstep(0.98, 0.28, radius) * smoothstep(0.07, 0.26, radius);
	collision_current *= hit_strength;

	float shock_radius = mix(0.16, 0.88, impact_age);
	float shock_ring = smoothstep(0.075, 0.0, abs(radius - shock_radius)) * hit_strength;
	float fork_line = smoothstep(0.985 - hit_strength * 0.22, 1.0, abs(sin(angle * 6.0 + radial_noise * 8.0 + gate_time * 18.0))) * hit_strength;
	float electric = max(collision_current, max(shock_ring, fork_line * smoothstep(0.22, 0.96, radius)));

	float crack_noise = fbm(uv * 8.0 + gate_time);
	float crack = smoothstep(0.84 - break_progress * 0.38, 0.96, crack_noise + break_progress * 0.55);
	float break_holes = smoothstep(0.42, 0.9, break_progress) * smoothstep(0.55, 0.98, crack_noise);

	vec3 color = gate_color.rgb * (0.03 + rim * 0.7 + electric * 1.7);
	color += hit_color.rgb * (shock_ring + collision_current) * (1.15 + hit_strength * 2.8);
	color += break_color.rgb * crack * break_progress * 1.8;

	float membrane = alpha * 0.08 * transparent_core;
	float visibility = disc * (membrane + rim * alpha * 0.52 + electric * 0.92 + break_progress * 0.24);
	visibility *= 1.0 - break_holes * 0.9;
	visibility *= 1.0 - smoothstep(0.82, 1.0, break_progress) * 0.75;

	ALBEDO = color;
	EMISSION = color * (1.15 + electric * 4.8 + hit_strength * 1.8 + break_progress * 1.8);
	ALPHA = clamp(visibility, 0.0, 1.0);
}
