shader_type spatial;
// Emberset VFX - bends what is behind it: shockwave rings and heat haze. Reads the screen texture,
// so it shows the opaque scene (floor, walls, characters), not other transparent effects.
// Give the material a negative render priority so particles draw on top of it.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D noise : repeat_enable, filter_linear;
// 0 = ring (shockwave; grow it with the particle's scale curve), 1 = haze (rolling noise).
uniform int shape : hint_range(0, 1) = 0;
// Offset in screen widths at full strength.
uniform float strength : hint_range(0.0, 0.2) = 0.03;
uniform float ring_width : hint_range(0.02, 0.6) = 0.25;
uniform float noise_scale = 1.0;
uniform vec2 scroll = vec2(0.0, 0.5);
// Faint colour added on the bent area so the wave reads on a flat background too.
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform bool billboard = true;
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

varying float v_life;
varying float v_alpha;
varying vec2 v_seed;

void vertex() {
	v_life = INSTANCE_CUSTOM.y;
	v_alpha = COLOR.a;
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
#ifndef CURRENT_RENDERER
	// Godot 4.3 cannot tell the renderers apart here, and its Compatibility renderer hands back
	// a darker copy of the screen, so the layer is left out there.
	if (OUTPUT_IS_SRGB) {
		discard;
	}
#endif
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	vec2 offset;
	float amount;
	if (shape == 0) {
		float band = 1.0 - smoothstep(0.0, ring_width, abs(r - (1.0 - ring_width)));
		amount = band * band;
		// Push outwards on the inside of the band and inwards on the outside: a lens-like ridge.
		offset = normalize(p + vec2(0.0001)) * (r - (1.0 - ring_width)) / ring_width;
	} else {
		vec2 n = vec2(texture(noise, UV * noise_scale + v_seed - scroll * TIME).r,
			texture(noise, UV * noise_scale * 1.3 + v_seed.yx + scroll.yx * TIME * 0.7 - scroll * TIME).r);
		amount = clamp(1.0 - r, 0.0, 1.0);
		amount *= amount;
		offset = n - 0.5;
	}
	amount *= v_alpha * fade;
	// UV y runs down the quad and screen y runs down the screen, so the offset keeps its sign.
	vec3 scene = textureLod(screen_texture, SCREEN_UV + offset * amount * strength, 0.0).rgb;
	ALBEDO = scene + color.rgb * color.a * amount;
	ALPHA = step(0.002, amount);
}
