shader_type spatial;
// Emberset VFX - ribbon for particle trails (GPUParticles3D with trails on and a RibbonTrailMesh).
// Bright at the head, thinning out to nothing at the tail.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, particle_trails;

uniform float emission : hint_range(0.0, 8.0) = 2.0;
// Pulls the middle of the ribbon towards white.
uniform float hot : hint_range(0.0, 1.0) = 0.5;
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
}

void fragment() {
	float across = clamp(1.0 - abs(UV.x * 2.0 - 1.0), 0.0, 1.0);
	// UV y runs from the head of the trail (0) to its tail (1).
	float along = 1.0 - UV.y;
	float a = across * across * along;
	vec3 col = mix(COLOR.rgb, vec3(1.0), clamp(a * hot, 0.0, 1.0)) * emission;
	if (OUTPUT_IS_SRGB) {
		float peak = max(col.r, max(col.g, col.b));
		if (peak > 1.0) {
			col = mix(col / peak, vec3(1.0), clamp((peak - 1.0) * 0.35, 0.0, 1.0));
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * COLOR.a * fade, 0.0, 1.0);
}
