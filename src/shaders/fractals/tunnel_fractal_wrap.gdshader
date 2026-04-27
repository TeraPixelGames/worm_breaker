/*
Wrapped fractal tunnel shader for Worm Breaker.
Provides depth bands and angular landmarks on the cylinder wall.
*/
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform float tunnel_phase = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;
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

void fragment() {
	vec2 uv = UV;
	float theta = uv.x;
	float depth = uv.y * 18.0 - tunnel_phase;
	vec2 wrapped = vec2(theta * 9.0, depth);

	float fractal = fbm(wrapped * 0.72 + vec2(sin(depth * 0.11), cos(theta * 6.28318)) * 0.8);
	float ring_wave = abs(sin(depth * 3.14159));
	float depth_rings = smoothstep(0.86, 1.0, ring_wave);
	float angular_lines = smoothstep(0.965, 1.0, abs(sin(theta * 6.28318 * 12.0 + fractal * 1.4)));
	float flow = smoothstep(0.38, 0.9, fractal);
	float trace = max(depth_rings * 0.56, angular_lines * 0.34);
	float brightness = clamp((flow * 0.52 + trace) * intensity, 0.0, 1.35);

	vec3 color = palette(brightness + fractal * 0.14);
	color += near_color.rgb * depth_rings * 0.18 * intensity;
	color += far_color.rgb * angular_lines * 0.10 * intensity;

	ALBEDO = mix(base_color.rgb, color, 0.72);
	EMISSION = color * (0.45 + brightness * 1.35);
}
