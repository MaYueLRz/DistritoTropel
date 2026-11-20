shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert;

// Dos capas de ruido a distinta escala y velocidad.
uniform sampler2D ruido_1;
uniform sampler2D ruido_2;
uniform vec2 velocidad_1 = vec2(-0.004, 0.003);
uniform vec2 velocidad_2 = vec2(0.0005, 0.001);

uniform float escala_uv = 3.0;
uniform float altura : hint_range(0.0, 20.0) = 3.0;

uniform vec4 color_luz : source_color = vec4(0.98, 0.98, 0.98, 1.0);
uniform vec4 color_sombra : source_color = vec4(0.72, 0.80, 0.88, 1.0);
uniform float umbral_alpha : hint_range(0.0, 1.0) = 0.25;
uniform float fuerza_alpha : hint_range(0.0, 4.0) = 1.5;

// Lo que calcula el vértice y usa el píxel: qué tan "llena" está la nube ahí.
varying float masa;


void vertex() {
	vec2 uv = UV * escala_uv;
	float g1 = texture(ruido_1, uv + velocidad_1 * TIME).g;
	float g2 = texture(ruido_2, uv + velocidad_2 * TIME).g;

	// Cada capa se lleva de 0..1 a -1..1, se promedian y se toma el valor absoluto.
	// El abs es lo que hace los bultos redondeados en vez de ondas.
	masa = abs(((g1 * 2.0 - 1.0) + (g2 * 2.0 - 1.0)) * 0.5);

	VERTEX += NORMAL * masa * altura;
}


void fragment() {
	ALBEDO = mix(color_sombra.rgb, color_luz.rgb, masa);
	ALPHA = clamp((masa + umbral_alpha) * fuerza_alpha, 0.0, 1.0);
}