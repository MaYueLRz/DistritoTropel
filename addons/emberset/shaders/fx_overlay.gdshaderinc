// Emberset VFX - status overlay for a character's Material Overlay slot: flames crawling up,
// a coat of ice, veins of poison, crackling arcs. The noise is projected from three sides in
// the mesh's own space, so it needs no UVs and moves with the model.
// Included by fx_overlay_add.gdshader and fx_overlay_mix.gdshader. EmbersetStatus.attach() drives `fade`.

uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec4 color_core : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 color_edge : source_color = vec4(0.8, 0.1, 0.02, 1.0);
uniform float emission : hint_range(0.0, 8.0) = 1.5;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

group_uniforms pattern;
// Tiles per metre.
uniform float noise_scale = 0.6;
uniform vec3 scroll = vec3(0.0, 0.5, 0.0);
// Share of the surface the pattern covers.
uniform float coverage : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.005, 1.0) = 0.2;
// 0 = patches, 1 = thin veins along the noise contours (arcs, cracks).
uniform float veins : hint_range(0.0, 1.0) = 0.0;
// > 0 covers more near the feet, < 0 more near the head.
uniform float rise : hint_range(-1.0, 1.0) = 0.0;
// Height of the model in metres, for `rise`.
uniform float height = 1.8;
// Re-rolls the pattern this many times a second (0 = smooth scrolling).
uniform float flicker_rate = 0.0;

group_uniforms rim;
uniform float rim : hint_range(0.0, 2.0) = 0.6;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed = 3.0;
// Fake top light for coats that should read as a solid material (ice, stone).
uniform float shade : hint_range(0.0, 1.0) = 0.0;
// Pushes the overlay out along the normals, in metres.
uniform float grow = 0.004;

varying vec3 v_local;
varying vec3 v_normal;

void vertex() {
	v_local = VERTEX;
	v_normal = NORMAL;
	VERTEX += NORMAL * grow;
}

float tri(vec3 p, vec3 w) {
	return texture(noise, p.xy).r * w.z + texture(noise, p.zy).r * w.x + texture(noise, p.xz).r * w.y;
}

void fragment() {
	vec3 w = abs(v_normal);
	w /= w.x + w.y + w.z;
	vec3 jump = vec3(0.0);
	float on = 1.0;
	if (flicker_rate > 0.0) {
		float tick = floor(TIME * flicker_rate);
		jump = fract(sin(vec3(tick * 12.9898, tick * 78.233, tick * 37.719)) * 43758.5453);
		on = step(0.25, jump.x);
	}
	vec3 p = v_local * noise_scale + jump;
	float n = tri(p - scroll * TIME, w) * (0.5 + tri(p * 1.9 + scroll.zxy * TIME * 0.6 - scroll * TIME * 1.3, w));
	n = mix(n, pow(clamp(1.0 - abs(n - 0.5) * 2.0, 0.0, 1.0), 6.0), veins);

	float h = clamp(v_local.y / height, 0.0, 1.0);
	float cover = clamp(coverage + rise * (0.5 - h) * 2.0, 0.0, 1.0);
	float v = smoothstep(1.0 - cover - softness, 1.0 - cover, n) * step(0.001, cover) * on;

	float edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim_power) * rim;
	float beat = 1.0 - pulse * (0.5 + 0.5 * sin(TIME * pulse_speed));
	float a = clamp(v + edge, 0.0, 1.0) * beat;

	float heat = clamp(v * n * 1.6 + edge, 0.0, 1.0);
	vec3 col = mix(color_edge.rgb, color_mid.rgb, smoothstep(0.0, 0.5, heat));
	col = mix(col, color_core.rgb, smoothstep(0.5, 1.0, heat));
	if (shade > 0.0) {
		float up = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
		col *= mix(1.0, 0.55 + 0.45 * up, shade);
	}
	col *= emission;
	if (OUTPUT_IS_SRGB) {
		float peak = max(col.r, max(col.g, col.b));
		if (peak > 1.0) {
			col = mix(col / peak, vec3(1.0), clamp((peak - 1.0) * 0.35, 0.0, 1.0));
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * alpha * fade, 0.0, 1.0);
}
