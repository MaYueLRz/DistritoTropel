shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform vec3 color : source_color = vec3(0.35, 0.80, 1.0);
uniform float fuerza : hint_range(0.0, 8.0) = 2.5;
uniform float borde : hint_range(0.1, 8.0) = 2.5;
uniform float velocidad_pulso = 3.0;

void fragment() {
	// Fresnel: brilla donde la superficie se ve de canto y se apaga de frente.
	float f = pow(1.0 - abs(dot(NORMAL, VIEW)), borde);
	float pulso = 0.85 + 0.15 * sin(TIME * velocidad_pulso);
	ALBEDO = color;
	ALPHA = clamp(f * fuerza * pulso, 0.0, 1.0);
}