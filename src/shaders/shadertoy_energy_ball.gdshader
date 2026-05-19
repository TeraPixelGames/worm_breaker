/*
Audio-reactive amber glass ball shader for Worm Breaker.
Inspired by the reflective orb look requested from:
https://www.shadertoy.com/view/Mtd3DB
*/
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform float ball_time = 0.0;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;
uniform float device_audio_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float audio_bass : hint_range(0.0, 1.0) = 0.0;
uniform float audio_mid : hint_range(0.0, 1.0) = 0.0;
uniform float audio_treble : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 core_color : source_color = vec4(1.0, 0.38, 0.02, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.93, 0.12, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.58, 0.0, 1.0);

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

float highlight(vec2 p, vec2 center, vec2 scale) {
	vec2 d = (p - center) / scale;
	return exp(-dot(d, d) * 3.6);
}

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv * 2.0 - 1.0;
	float longitude = centered.x;
	float latitude = centered.y;
	float time = ball_time * (0.42 + audio_bass * 0.16) + device_audio_pulse * 0.16;
	float audio_drive = clamp(device_audio_pulse * 0.55 + audio_bass * 0.34 + audio_mid * 0.22 + audio_treble * 0.16, 0.0, 1.0);

	vec3 normal = normalize(NORMAL);
	vec3 view_dir = normalize(VIEW);
	float ndotv = clamp(dot(normal, view_dir), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.65);
	vec3 reflection_dir = reflect(-view_dir, normal);
	vec2 refract_uv = clamp(SCREEN_UV - normal.xy * (0.045 + fresnel * 0.025), vec2(0.001), vec2(0.999));
	vec2 reflect_uv = clamp(SCREEN_UV + reflection_dir.xy * (0.06 + fresnel * 0.04), vec2(0.001), vec2(0.999));
	vec3 scene_refract = textureLod(screen_texture, refract_uv, 2.8).rgb;
	vec3 scene_reflect = textureLod(screen_texture, reflect_uv, 1.2).rgb;

	vec2 swirl = vec2(longitude * 2.7 + sin(latitude * 3.2 + time) * 0.22, latitude * 2.25);
	float glass_grain = fbm(swirl + vec2(time * 0.16, -time * 0.11));
	float curved_band = smoothstep(0.74, 1.0, sin((latitude + glass_grain * 0.18 + time * 0.24) * 8.0) * 0.5 + 0.5);
	float caustic = smoothstep(0.54 - audio_mid * 0.08, 1.0, abs(sin((longitude * 4.2 - latitude * 2.7 + glass_grain * 3.4 + time) * 2.6)));
	float inner_glow = exp(-dot(centered * vec2(0.88, 1.12), centered * vec2(0.88, 1.12)) * 1.35);
	float top_window = highlight(centered, vec2(-0.18, -0.55), vec2(0.64, 0.18));
	float left_window = highlight(centered, vec2(-0.58, 0.06), vec2(0.16, 0.72));
	float hot_core = highlight(centered, vec2(0.04 + sin(time) * 0.03, 0.04), vec2(0.32, 0.38));
	float spec_1 = highlight(centered, vec2(-0.30, -0.42), vec2(0.13, 0.08));
	float spec_2 = highlight(centered, vec2(0.34, -0.24), vec2(0.08, 0.16));
	float horizon_shadow = smoothstep(-0.18, 0.54, latitude) * smoothstep(0.72, 0.12, abs(longitude));

	vec3 amber_tint = mix(core_color.rgb, hot_color.rgb, inner_glow * 0.55 + device_audio_pulse * 0.18);
	vec3 dark_amber = vec3(0.18, 0.095, 0.018);
	vec3 reflected = mix(scene_refract * amber_tint * 1.25, scene_reflect + edge_color.rgb * 0.12, 0.34 + fresnel * 0.45);
	vec3 color = reflected;
	color = mix(color, amber_tint * (0.55 + inner_glow * 1.15), 0.38);
	color = mix(color, dark_amber, horizon_shadow * 0.34);
	color += hot_color.rgb * (hot_core * (0.52 + audio_bass * 0.34) + device_audio_pulse * inner_glow * 0.28);
	color += edge_color.rgb * fresnel * (0.85 + audio_drive * 0.65);
	color += vec3(1.0, 0.86, 0.42) * (curved_band * 0.12 + caustic * 0.1);
	color += vec3(1.0, 0.96, 0.78) * (top_window * 0.72 + left_window * 0.25 + spec_1 * 1.6 + spec_2 * 0.9) * (0.9 + audio_treble * 0.35);
	color += vec3(1.0, 0.55, 0.02) * glass_grain * 0.08;
	color = mix(color, color.bgr * vec3(1.1, 0.62, 0.34), hue_shift * 0.035);

	ALBEDO = color * 0.62;
	EMISSION = color * (0.82 + fresnel * 1.75 + hot_core * 0.9 + device_audio_pulse * 0.75 + audio_treble * 0.18);
}
