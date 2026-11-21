shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// Emberset VFX - procedural magic circle for a flat QuadMesh: rings, a spinning star,
// dashes and glyph marks, all drawn with maths so it stays sharp at any size.

uniform vec4 color : source_color = vec4(0.6, 0.4, 1.0, 1.0);
uniform vec4 color_inner : source_color = vec4(0.95, 0.9, 1.0, 1.0);
uniform float emission : hint_range(0.0, 8.0) = 1.1;
uniform float spin = 0.3;
uniform int sides : hint_range(3, 8) = 3;
uniform int dashes : hint_range(4, 48) = 24;
uniform float line : hint_range(0.004, 0.05) = 0.012;
uniform float fill : hint_range(0.0, 1.0) = 0.12;
uniform float pulse : hint_range(0.0, 1.0) = 0.15;
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

float band(float x, float centre, float width) {
	return 1.0 - smoothstep(width, width + 0.012, abs(x - centre));
}

void vertex() {
	if (!OUTPUT_IS_SRGB) {
		// Particle and vertex colours arrive in sRGB; the HDR renderers work in linear light.
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float m = band(r, 0.95, line * 1.6) + band(r, 0.84, line) + band(r, 0.62, line) + band(r, 0.2, line);

	float dash = fract((ang + TIME * spin) / TAU * float(dashes));
	m += step(0.86, r) * step(r, 0.93) * smoothstep(0.2, 0.28, abs(dash - 0.5));

	float seg = TAU / float(sides);
	float apothem = 0.62 * cos(seg * 0.5);
	float a1 = ang - TIME * spin * 1.5;
	float d1 = cos(floor(0.5 + a1 / seg) * seg - a1) * r;
	float a2 = a1 + seg * 0.5;
	float d2 = cos(floor(0.5 + a2 / seg) * seg - a2) * r;
	m += (band(d1, apothem, line) + band(d2, apothem, line)) * step(r, 0.63);

	float gk = fract((ang + TIME * spin * 2.0) / TAU * float(sides * 2)) - 0.5;
	vec2 q = vec2(gk * TAU * 0.73 / float(sides * 2), r - 0.73);
	m += 1.0 - smoothstep(0.035, 0.05, abs(q.x) + abs(q.y));

	float glow = fill * (1.0 - smoothstep(0.0, 1.0, r));
	float a = (clamp(m, 0.0, 1.0) * (1.0 + pulse * sin(TIME * 3.0)) + glow) * step(r, 1.0);
	vec3 col = mix(color.rgb, color_inner.rgb, clamp(m, 0.0, 1.0) * 0.3) * COLOR.rgb * emission;
	if (OUTPUT_IS_SRGB) {
		float peak = max(col.r, max(col.g, col.b));
		if (peak > 1.0) {
			col = mix(col / peak, vec3(1.0), clamp((peak - 1.0) * 0.35, 0.0, 1.0));
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * COLOR.a * fade, 0.0, 1.0);
}
