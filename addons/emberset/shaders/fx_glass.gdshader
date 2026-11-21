shader_type spatial;
// Emberset - frosted glass. Blurs and tints what is behind the surface and grows frost on it.
// Put it on any mesh (a pane, a window, a block of ice). It reads the screen texture, so it shows
// the opaque scene behind it, not other transparent objects.
render_mode unshaded, cull_disabled, shadows_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
// Pattern of the frost and of the bumps in the glass.
uniform sampler2D noise : repeat_enable, filter_linear;
uniform float noise_scale = 2.0;
// Colour of the glass; alpha is how strongly it colours what is behind it.
uniform vec4 tint : source_color = vec4(0.9, 0.97, 1.0, 0.15);
// Blur of clear glass, in mip levels of the screen (0 = sharp).
uniform float blur : hint_range(0.0, 7.0) = 2.0;
// How much of the surface is frosted over (0 = none, 1 = all of it).
uniform float frost : hint_range(0.0, 1.0) = 0.3;
// Hardness of the frost edge: low = crisp crystals, high = soft haze.
uniform float frost_softness : hint_range(0.01, 0.5) = 0.15;
// Extra frost creeping in from the edges of the UV square (winter windows).
uniform float edge_frost : hint_range(0.0, 2.0) = 0.0;
// Colour of the frost; alpha is how opaque it gets.
uniform vec4 frost_color : source_color = vec4(0.9, 0.96, 1.0, 0.55);
// Extra blur under the frost, in mip levels.
uniform float frost_blur : hint_range(0.0, 6.0) = 3.0;
// How far the bumps bend the picture, in screen widths.
uniform float distortion : hint_range(0.0, 0.1) = 0.006;
// Bright rim at grazing angles.
uniform float rim : hint_range(0.0, 2.0) = 0.25;
// Driven by EmbersetEffect on play() / stop(): 0 = the glass is not there.
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
#ifndef CURRENT_RENDERER
	// Godot 4.3 cannot tell the renderers apart here, and its Compatibility renderer hands back
	// a darker copy of the screen, so the glass is left out there.
	if (OUTPUT_IS_SRGB) {
		discard;
	}
#endif
	vec2 nuv = UV * noise_scale;
	float n = texture(noise, nuv).r;
	float n2 = texture(noise, nuv * 2.7 + vec2(0.37, 0.11)).r;
	vec2 bump = vec2(texture(noise, nuv + vec2(0.02, 0.0)).r - n, texture(noise, nuv + vec2(0.0, 0.02)).r - n) * 12.0;
	float centre = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)) * 2.0;
	float field = mix(n, n2, 0.4) + edge_frost * (0.5 - centre);
	float f = smoothstep(1.0 - frost - frost_softness, 1.0 - frost + frost_softness, field + frost * 0.3) * step(0.001, frost + edge_frost);

	float lod = blur + f * frost_blur;
	vec2 uv = SCREEN_UV + bump * distortion * (0.4 + f);
	// Sixteen taps on a spiral, turned by a different angle on every pixel. Where the screen has mip
	// levels (Forward+, Mobile) each tap is already smooth; where it has none (Compatibility) the
	// taps alone do the blurring and leave a fine grain, which suits frosted glass.
	float radius = (exp2(lod) - 1.0) * 1.5;
	float turn = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715)))) * 6.2831853;
	vec3 scene = vec3(0.0);
	for (int i = 0; i < 16; i++) {
		float t = (float(i) + 0.5) / 16.0;
		float ang = float(i) * 2.3999632 + turn;
		scene += textureLod(screen_texture, uv + vec2(cos(ang), sin(ang)) * sqrt(t) * radius / VIEWPORT_SIZE, lod).rgb;
	}
	scene /= 16.0;

	vec3 col = scene * mix(vec3(1.0), tint.rgb, tint.a);
	col = mix(col, frost_color.rgb * (0.75 + 0.5 * n2), f * frost_color.a);
	float graze = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	col += frost_color.rgb * graze * rim;
	ALBEDO = mix(textureLod(screen_texture, SCREEN_UV, 0.0).rgb, col, fade);
}
