// Emberset VFX - particle sprite with procedural shapes, so no sprite textures are needed.
// Included by fx_particle_add.gdshader and fx_particle_mix.gdshader.
// Colour and alpha come from the particle (ParticleProcessMaterial colour and colour ramp).

// 0 soft dot, 1 hot dot, 2 streak, 3 ring, 4 flare, 5 puff, 6 shard, 7 droplet, 8 bubble, 9 plus
uniform int shape : hint_range(0, 9) = 0;
uniform float emission : hint_range(0.0, 8.0) = 1.5;
// Pulls the centre of the shape towards white.
uniform float hot : hint_range(0.0, 1.0) = 0.0;
uniform float ring_width : hint_range(0.01, 0.5) = 0.12;
// Puff only: how far the noise eats the puff as it ages.
uniform float erosion_life : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D noise : repeat_enable, filter_linear;
#ifdef EMBERSET_SOFT
// Distance in metres over which the sprite fades into the geometry behind it.
// Needs Godot 4.4 or newer on Forward+ or Mobile; otherwise the sprite is drawn as a plain glow.
uniform float soft_distance : hint_range(0.05, 4.0) = 0.6;
#ifdef CURRENT_RENDERER
#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
#define EMBERSET_DEPTH
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
#endif
#endif
#endif
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

varying float v_life;
varying vec2 v_seed;

void vertex() {
	if (!OUTPUT_IS_SRGB) {
		// Particle and vertex colours arrive in sRGB; the HDR renderers work in linear light.
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	v_life = INSTANCE_CUSTOM.y;
	float id = float(INSTANCE_ID);
	v_seed = fract(vec2(id * 0.6180339, id * 0.3819660));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float edge = clamp(1.0 - r, 0.0, 1.0);
	float a = 0.0;
	if (shape == 0) {
		a = edge * edge;
	} else if (shape == 1) {
		a = max(smoothstep(0.55, 0.3, r), edge * edge * edge * 0.6);
	} else if (shape == 2) {
		float w = clamp(1.0 - abs(p.x), 0.0, 1.0);
		a = w * w * smoothstep(-1.0, 0.5, p.y) * (1.0 - smoothstep(0.6, 1.0, p.y));
	} else if (shape == 3) {
		float w = ring_width * (1.0 - v_life * 0.7);
		a = (1.0 - smoothstep(0.0, w, abs(r - (1.0 - ring_width)))) * step(r, 1.0);
	} else if (shape == 4) {
		float star = clamp(0.012 / (abs(p.x * p.y) + 0.012), 0.0, 1.0);
		a = max(star * edge * edge, edge * edge * edge);
	} else if (shape == 5) {
		float n = texture(noise, UV * 0.55 + v_seed).r;
		float ero = 0.08 + v_life * erosion_life;
		a = smoothstep(ero, ero + 0.3, n * (1.0 - r * r)) * smoothstep(0.0, 0.25, edge);
	} else if (shape == 6) {
		a = step(abs(p.x) * 1.7 + abs(p.y), 1.0) * (0.55 + 0.45 * step(0.0, p.x));
	} else if (shape == 7) {
		// UV y runs down the quad, so flip it: round end at the bottom, point at the top.
		float up = -p.y;
		float w = mix(0.75, 0.05, clamp(up * 0.5 + 0.5, 0.0, 1.0));
		a = smoothstep(w, w * 0.4, abs(p.x)) * smoothstep(-1.0, -0.6, up) * (1.0 - smoothstep(0.7, 1.0, up));
	} else if (shape == 8) {
		float rim = 1.0 - smoothstep(0.0, 0.1, abs(r - 0.82));
		float shine = 1.0 - smoothstep(0.08, 0.2, length(p - vec2(-0.35, 0.38)));
		a = max(max(rim, shine), 0.18 * step(r, 0.82));
	} else {
		float bar_v = smoothstep(0.3, 0.2, abs(p.x)) * smoothstep(0.85, 0.75, abs(p.y));
		float bar_h = smoothstep(0.3, 0.2, abs(p.y)) * smoothstep(0.85, 0.75, abs(p.x));
		a = max(bar_v, bar_h);
	}
#ifdef EMBERSET_DEPTH
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 scene = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	a *= clamp((VERTEX.z - scene.z / scene.w) / soft_distance, 0.0, 1.0);
#endif
	vec3 col = mix(COLOR.rgb, vec3(1.0), clamp(a * a * hot, 0.0, 1.0));
	col *= emission;
	if (OUTPUT_IS_SRGB) {
		// Low dynamic range target (Compatibility without glow): keep the hue of
		// over-bright colours instead of letting each channel clip on its own.
		float peak = max(col.r, max(col.g, col.b));
		if (peak > 1.0) {
			col = mix(col / peak, vec3(1.0), clamp((peak - 1.0) * 0.35, 0.0, 1.0));
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * COLOR.a * fade, 0.0, 1.0);
}
