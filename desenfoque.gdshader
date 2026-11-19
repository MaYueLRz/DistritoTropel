shader_type canvas_item;

uniform sampler2D pantalla : hint_screen_texture, filter_linear_mipmap;
uniform float desenfoque = 2.5;
uniform float oscuridad = 0.6;
uniform vec4 tinte : source_color = vec4(1.0, 0.78, 0.5, 1.0);
uniform float vineta = 0.7;
uniform float tamano_puntos = 7.0;
uniform float fuerza_puntos = 0.3;

void fragment() {
	// 1. El juego de fondo, borroso
	vec3 color = textureLod(pantalla, SCREEN_UV, desenfoque).rgb;

	// 2. Tinte naranja y oscurecer
	color *= tinte.rgb * oscuridad;

	// 3. Viñeta: esquinas más oscuras
	float distancia = distance(SCREEN_UV, vec2(0.5));
	color *= 1.0 - smoothstep(0.3, 0.9, distancia) * vineta;

	// 4. Puntos de cómic
	vec2 celda = fract(FRAGCOORD.xy / tamano_puntos) - 0.5;
	float punto = step(length(celda), 0.22);
	color *= 1.0 - punto * fuerza_puntos;

	COLOR = vec4(color, 1.0);
}
