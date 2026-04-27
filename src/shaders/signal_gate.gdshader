/*
Transparent signal gate boundary for Worm Breaker.
Electric current pattern adapted from "Procedural Electric Current Shader"
by nonunknown, MIT License.
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

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	float radius = length(uv);
	float disc = smoothstep(1.02, 0.86, radius);
	float transparent_core = smoothstep(0.0, 0.72, radius);
	float rim = smoothstep(1.0, 0.92, radius) - smoothstep(0.86, 0.72, radius);

	float angle = atan(uv.y, uv.x);
	float radial = radius * 7.5;
	vec2 flow_uv = vec2(angle * 2.25 + gate_time * 1.8, radial - gate_time * 3.2);
	float current = fbm(flow_uv * 1.8);
	float branch = abs(sin(angle * 9.0 + current * 8.0 + gate_time * 7.0));
	float electric = smoothstep(0.73, 0.98, current) * smoothstep(0.62, 0.96, branch);

	float hit_ring = smoothstep(0.16 + hit_strength * 0.7, 0.10 + hit_strength * 0.7, abs(radius - hit_strength));
	float crack_noise = fbm(uv * 8.0 + gate_time);
	float crack = smoothstep(0.84 - break_progress * 0.38, 0.96, crack_noise + break_progress * 0.55);
	float break_holes = smoothstep(0.42, 0.9, break_progress) * smoothstep(0.55, 0.98, crack_noise);

	vec3 color = gate_color.rgb * (0.06 + rim * 0.9 + electric * 1.45);
	color += hit_color.rgb * hit_ring * (0.45 + hit_strength * 1.8);
	color += break_color.rgb * crack * break_progress * 1.8;

	float membrane = alpha * 0.20 * transparent_core;
	float visibility = disc * (membrane + rim * alpha * 0.62 + electric * 0.24 + hit_ring * 0.38 + break_progress * 0.24);
	visibility *= 1.0 - break_holes * 0.9;
	visibility *= 1.0 - smoothstep(0.82, 1.0, break_progress) * 0.75;

	ALBEDO = color;
	EMISSION = color * (1.15 + hit_strength * 2.4 + break_progress * 1.8);
	ALPHA = clamp(visibility, 0.0, 1.0);
}
