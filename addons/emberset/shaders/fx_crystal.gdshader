shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

// Emberset VFX - faceted crystal for ice spikes, gems and debris. Flat-shaded with a fixed
// fake light, so it looks the same with or without lights in the scene.
// Particle alpha dissolves the crystal through a noise pattern instead of fading it.

uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec4 color_light : source_color = vec4(0.85, 0.97, 1.0, 1.0);
uniform vec4 color_dark : source_color = vec4(0.2, 0.5, 0.85, 1.0);
uniform vec4 color_rim : source_color = vec4(0.7, 0.95, 1.0, 1.0);
uniform float emission : hint_range(0.0, 8.0) = 1.2;
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	if (!OUTPUT_IS_SRGB) {
		// Particle and vertex colours arrive in sRGB; the HDR renderers work in linear light.
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
}

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (n.z < 0.0) {
		n = -n;
	}
	float light = dot(n, normalize(vec3(0.35, 0.75, 0.55))) * 0.5 + 0.5;
	float rim = pow(1.0 - n.z, 2.0);
	vec3 col = mix(color_dark.rgb, color_light.rgb, light * light) + color_rim.rgb * rim * 0.6;
	ALBEDO = col * COLOR.rgb * emission;
	ALPHA = step(texture(noise, UV * 2.0).r * 0.98, COLOR.a * fade - 0.01);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
