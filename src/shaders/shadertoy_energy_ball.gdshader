/*
Audio-reactive energy ball shader for Worm Breaker.
Inspired by the procedural Shadertoy-style plasma/orb look requested from:
https://www.shadertoy.com/view/Mtd3DB
*/
shader_type spatial;
render_mode unshaded, cull_back;

uniform float ball_time = 0.0;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;
uniform float device_audio_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float audio_bass : hint_range(0.0, 1.0) = 0.0;
uniform float audio_mid : hint_range(0.0, 1.0) = 0.0;
uniform float audio_treble : hint_range(0.0, 1.0) = 0.0;
uniform vec4 core_color : source_color = vec4(0.12, 1.0, 0.86, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.96, 0.24, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.08, 0.78, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.17);
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
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += noise(p) * amplitude;
		p = mat2(vec2(1.62, -1.18), vec2(1.18, 1.62)) * p + vec2(4.3, 7.1);
		amplitude *= 0.52;
	}
	return value;
}

vec3 hue_rotate(vec3 color, float shift) {
	float angle = shift * 6.2831853;
	float s = sin(angle);
	float c = cos(angle);
	mat3 m = mat3(
		vec3(0.299 + 0.701 * c + 0.168 * s, 0.587 - 0.587 * c + 0.330 * s, 0.114 - 0.114 * c - 0.497 * s),
		vec3(0.299 - 0.299 * c - 0.328 * s, 0.587 + 0.413 * c + 0.035 * s, 0.114 - 0.114 * c + 0.292 * s),
		vec3(0.299 - 0.300 * c + 1.250 * s, 0.587 - 0.588 * c - 1.050 * s, 0.114 + 0.886 * c - 0.203 * s)
	);
	return clamp(m * color, vec3(0.0), vec3(8.0));
}

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv * 2.0 - 1.0;
	float longitude = centered.x;
	float latitude = centered.y;
	float time = ball_time * (0.92 + audio_bass * 0.48) + device_audio_pulse * 0.38;
	float audio_drive = clamp(device_audio_pulse * 0.55 + audio_bass * 0.34 + audio_mid * 0.22 + audio_treble * 0.16, 0.0, 1.0);

	vec2 flow = vec2(longitude * 3.2 + sin(latitude * 2.7 + time) * 0.34, latitude * 2.6);
	flow += vec2(cos(time * 0.7 + latitude * 4.0), sin(time * 0.55 + longitude * 5.0)) * (0.18 + audio_mid * 0.18);
	float cloud = fbm(flow + vec2(time * 0.42, -time * 0.31));
	float counter_cloud = fbm(vec2(-flow.x * 1.25 + time * 0.28, flow.y * 1.16 - time * 0.22));
	float plasma = abs(sin((cloud * 5.8 + counter_cloud * 3.4 + longitude * 4.6 - latitude * 2.8 + time * 2.1) * 3.14159));
	float veins = smoothstep(0.62 - audio_mid * 0.12, 1.0, plasma);
	float hot_cells = smoothstep(0.76 - audio_bass * 0.16 - device_audio_pulse * 0.18, 1.0, cloud + counter_cloud * 0.42);
	float sparks = smoothstep(0.82 - audio_treble * 0.18, 1.0, noise(flow * 9.0 + vec2(time * 3.0, -time * 2.2))) * (0.2 + audio_treble);

	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.3);
	float latitude_rim = smoothstep(0.15, 1.0, abs(latitude));
	vec3 color = core_color.rgb * (0.34 + cloud * 0.62);
	color = mix(color, hot_color.rgb, hot_cells * (0.48 + audio_bass * 0.42));
	color += edge_color.rgb * veins * (0.46 + audio_mid * 0.46);
	color += vec3(0.34, 0.74, 1.0) * sparks * (0.7 + audio_treble * 1.2);
	color += hot_color.rgb * device_audio_pulse * (0.42 + fresnel * 0.8);
	color += edge_color.rgb * fresnel * (0.55 + audio_drive * 1.2);
	color += core_color.rgb * latitude_rim * 0.12;
	color = hue_rotate(color, hue_shift * 0.22 + audio_treble * 0.08);

	ALBEDO = color * 0.68;
	EMISSION = color * (1.45 + veins * 1.35 + hot_cells * 1.8 + fresnel * 2.1 + audio_drive * 2.2);
}
