// Emberset VFX - shared scrolling-noise surface (flames, beams, portals, auras, shells).
// Included by fx_surface_add.gdshader and fx_surface_mix.gdshader.
// Works on Forward+, Mobile and Compatibility. No screen or depth textures.

uniform sampler2D noise_a : repeat_enable, filter_linear;
uniform sampler2D noise_b : repeat_enable, filter_linear;

uniform vec4 color_core : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 color_edge : source_color = vec4(0.8, 0.1, 0.02, 1.0);
uniform float emission : hint_range(0.0, 8.0) = 1.5;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

group_uniforms mapping;
// 0 = mesh UVs, 1 = polar (x = angle, y = distance from the centre of the UV square).
uniform int uv_mode : hint_range(0, 1) = 0;
uniform float swirl = 0.0;
uniform vec2 scale_a = vec2(1.0, 1.0);
uniform vec2 scroll_a = vec2(0.0, 1.0);
uniform vec2 scale_b = vec2(2.0, 2.0);
uniform vec2 scroll_b = vec2(0.1, 0.6);
uniform float distort : hint_range(0.0, 1.0) = 0.1;
uniform float blend_b : hint_range(0.0, 1.0) = 0.5;

group_uniforms shape;
uniform float fade_x : hint_range(0.0, 0.5) = 0.0;
uniform float fade_top : hint_range(0.0, 1.0) = 0.0;
uniform float fade_bottom : hint_range(0.0, 1.0) = 0.0;
// Narrows the shape towards the top (flames, cones).
uniform float taper : hint_range(0.0, 1.0) = 0.0;
// x = position along y, y = half width. Width 0 turns the band off.
uniform vec2 ring = vec2(0.0, 0.0);
uniform float gain : hint_range(0.0, 2.0) = 1.0;
uniform float erosion : hint_range(0.0, 1.0) = 0.1;
// Extra erosion as a particle ages, so flames and puffs dissolve instead of fading flat.
uniform float erosion_life : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.001, 1.0) = 0.15;
uniform float ramp_width : hint_range(0.01, 1.0) = 0.5;
// > 0 keeps the rim of a sphere or shell, < 0 keeps the centre.
uniform float fresnel = 0.0;
uniform bool billboard = false;

group_uniforms sweep;
// Particle-carried meshes only (slashes). > 0 reveals the mesh along y in this share of the
// particle's life; after that it burns away from the same end.
uniform float sweep : hint_range(0.0, 1.0) = 0.0;
// Extra heat right behind the leading edge.
uniform float sweep_head : hint_range(0.0, 2.0) = 0.6;
// Moves the brightest line across the blade: 0.5 = centre, 1 = outer edge.
uniform float edge_bias : hint_range(0.0, 1.0) = 0.5;

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
	if (billboard) {
		mat4 m = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		m = m * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = VIEW_MATRIX * m;
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	// y points up the mesh.
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	float mask = 1.0;
	if (uv_mode == 1) {
		vec2 p = UV * 2.0 - 1.0;
		float r = length(p);
		uv = vec2(atan(p.y, p.x) / TAU + 0.5 + swirl * (1.0 - r), r);
		mask *= 1.0 - step(1.0, r);
	} else {
		float half_w = 0.5 * (1.0 - taper * uv.y);
		// edge_bias bends x so the widest, brightest part sits towards one edge.
		float bx = edge_bias == 0.5 ? uv.x : pow(uv.x, log(0.5) / log(clamp(edge_bias, 0.02, 0.98)));
		float dx = half_w - abs(bx - 0.5);
		mask *= fade_x > 0.0 ? smoothstep(0.0, fade_x, dx) : step(0.0, dx);
	}
	if (fade_bottom > 0.0) {
		mask *= smoothstep(0.0, fade_bottom, uv.y);
	}
	if (fade_top > 0.0) {
		mask *= smoothstep(0.0, fade_top, 1.0 - uv.y);
	}
	if (ring.y > 0.0) {
		mask *= 1.0 - smoothstep(0.0, ring.y, abs(uv.y - ring.x));
	}

	float lead = 0.0;
	if (sweep > 0.0) {
		float head = clamp(v_life / sweep, 0.0, 1.0) * 1.05;
		float tail = clamp((v_life - sweep * 0.7) / (1.0 - sweep * 0.7), 0.0, 1.0) * 1.35;
		mask *= smoothstep(0.0, 0.04, head - uv.y) * smoothstep(tail - 0.35, tail, uv.y);
		lead = (1.0 - smoothstep(0.0, 0.3, head - uv.y)) * step(uv.y, head) * (1.0 - smoothstep(sweep, sweep * 1.6, v_life)) * sweep_head;
	}

	vec2 suv = uv + v_seed;
	float nb = texture(noise_b, suv * scale_b - scroll_b * TIME).r;
	float na = texture(noise_a, suv * scale_a - scroll_a * TIME + (nb - 0.5) * distort).r;
	float n = na * mix(1.0, nb * 2.0, blend_b);

	// Subtracting the mask erodes the outline with the noise, which gives licking edges.
	float v = clamp(n * gain + mask - 1.0 + lead * mask, 0.0, 1.0);
	float ero = erosion + v_life * erosion_life;
	float a = smoothstep(ero, ero + softness, v) * smoothstep(0.0, 0.05, mask);

	if (fresnel != 0.0) {
		float ndv = abs(dot(normalize(NORMAL), normalize(VIEW)));
		a *= fresnel > 0.0 ? pow(1.0 - ndv, fresnel) : pow(ndv, -fresnel);
	}

	float h = clamp((v - ero) / ramp_width, 0.0, 1.0);
	vec3 col = mix(color_edge.rgb, color_mid.rgb, smoothstep(0.0, 0.5, h));
	col = mix(col, color_core.rgb, smoothstep(0.4, 1.0, h));

	col *= COLOR.rgb * emission;
	if (OUTPUT_IS_SRGB) {
		// Low dynamic range target (Compatibility without glow): keep the hue of
		// over-bright colours instead of letting each channel clip on its own.
		float peak = max(col.r, max(col.g, col.b));
		if (peak > 1.0) {
			col = mix(col / peak, vec3(1.0), clamp((peak - 1.0) * 0.35, 0.0, 1.0));
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * COLOR.a * alpha * fade, 0.0, 1.0);
}
