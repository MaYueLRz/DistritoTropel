shader_type spatial;
// Emberset VFX - energy shield for spheres, domes and flat barriers: rim glow, a hex or noise
// pattern, a bright line where it meets other geometry, and ripples where it is hit.
// EmbersetShield.hit(world_position) drives the ripples.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color_rim : source_color = vec4(0.5, 0.85, 1.0, 1.0);
uniform vec4 color_fill : source_color = vec4(0.1, 0.35, 1.0, 1.0);
uniform vec4 color_hit : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float emission : hint_range(0.0, 8.0) = 1.6;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

group_uniforms surface;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float fill : hint_range(0.0, 1.0) = 0.12;
// 0 = none, 1 = hexagons, 2 = scrolling noise.
uniform int pattern : hint_range(0, 2) = 1;
uniform vec2 pattern_scale = vec2(16.0, 8.0);
uniform float pattern_strength : hint_range(0.0, 2.0) = 0.6;
uniform float line_width : hint_range(0.01, 0.4) = 0.08;
uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec2 scroll = vec2(0.02, 0.08);
// A band of light that travels up the shield.
uniform float scan : hint_range(0.0, 2.0) = 0.5;
uniform float scan_speed = 0.35;
// Cuts the mesh below this height in mesh UV (domes); 0 = keep everything.
uniform float cut_bottom : hint_range(0.0, 1.0) = 0.0;
// Flat barriers: fades the border of the UV square instead of using the view angle.
uniform bool panel = false;

group_uniforms contact;
// Metres over which the shield glows where it meets other geometry.
// Needs Godot 4.4 or newer on Forward+ or Mobile; elsewhere the line is left out.
uniform float contact_distance : hint_range(0.0, 1.0) = 0.18;
#ifdef CURRENT_RENDERER
#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
#define EMBERSET_DEPTH
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
#endif
#endif

group_uniforms hits;
// xyz = hit point in the shield's own space, w = age from 0 to 1 (0 = unused).
uniform vec4 hits[4];
uniform float ripple_reach = 1.4;
uniform float ripple_width = 0.16;
uniform float ripple_push = 0.04;

varying vec3 v_local;
varying float v_life;

float ripples(vec3 at) {
	float sum = 0.0;
	for (int i = 0; i < 4; i++) {
		float age = hits[i].w;
		if (age > 0.0 && age < 1.0) {
			float d = distance(at, hits[i].xyz);
			float wave = 1.0 - smoothstep(0.0, ripple_width, abs(d - age * ripple_reach));
			float flash = (1.0 - smoothstep(0.0, ripple_reach * 0.35, d)) * (1.0 - smoothstep(0.0, 0.3, age));
			sum += (wave + flash) * (1.0 - age);
		}
	}
	return sum;
}

// Distance to the nearest hexagon edge, 0 on the edge.
float hex_edge(vec2 p) {
	const vec2 s = vec2(1.0, 1.7320508);
	vec2 a = mod(p, s) - s * 0.5;
	vec2 b = mod(p - s * 0.5, s) - s * 0.5;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	g = abs(g);
	return 0.5 - max(dot(g, s * 0.5), g.x);
}

void vertex() {
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	v_life = INSTANCE_CUSTOM.y;
	v_local = VERTEX;
	VERTEX += NORMAL * ripples(VERTEX) * ripple_push;
}

void fragment() {
	float y = 1.0 - UV.y;
	float rim;
	if (panel) {
		vec2 e = min(UV, 1.0 - UV);
		rim = 1.0 - smoothstep(0.0, 0.18, min(e.x, e.y));
	} else {
		rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim_power);
	}
	float body = fill;
	if (pattern == 1) {
		float e = hex_edge(UV * pattern_scale);
		body += (1.0 - smoothstep(0.0, line_width, e)) * pattern_strength;
	} else if (pattern == 2) {
		float n = texture(noise, UV * pattern_scale * 0.1 - scroll * TIME).r;
		n *= texture(noise, UV * pattern_scale * 0.17 + scroll.yx * TIME).r * 2.0;
		body += smoothstep(0.3, 0.75, n) * pattern_strength;
	}
	if (scan > 0.0) {
		body *= 1.0 + scan * (1.0 - smoothstep(0.0, 0.12, abs(fract(y - TIME * scan_speed) - 0.5)));
	}
	float hit = ripples(v_local);
	float contact = 0.0;
#ifdef EMBERSET_DEPTH
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 scene = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	if (contact_distance > 0.0) {
		contact = 1.0 - clamp((VERTEX.z - scene.z / scene.w) / contact_distance, 0.0, 1.0);
	}
#endif
	float a = clamp(rim + body + contact, 0.0, 1.5);
	vec3 col = mix(color_fill.rgb, color_rim.rgb, clamp(rim + contact + body * 0.5, 0.0, 1.0));
	col = mix(col, color_hit.rgb, clamp(hit, 0.0, 1.0));
	a += hit;
	if (cut_bottom > 0.0) {
		a *= step(cut_bottom, y);
	}
	col *= COLOR.rgb * emission;
	if (OUTPUT_IS_SRGB) {
		float peak = max(col.r, max(col.g, col.b));
		if (peak > 1.0) {
			col = mix(col / peak, vec3(1.0), clamp((peak - 1.0) * 0.35, 0.0, 1.0));
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * COLOR.a * alpha * fade, 0.0, 1.0);
}
