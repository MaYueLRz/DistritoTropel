shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// Emberset VFX - procedural lightning bolt running along the Y axis of a tall QuadMesh.
// The shape is re-rolled `rate` times a second. Works on Forward+, Mobile and Compatibility.

uniform vec4 color_core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_glow : source_color = vec4(0.35, 0.6, 1.0, 1.0);
uniform float emission : hint_range(0.0, 8.0) = 2.0;
uniform float thickness : hint_range(0.002, 0.2) = 0.03;
uniform float amplitude : hint_range(0.0, 0.5) = 0.22;
uniform float frequency = 1.0;
uniform float rate = 16.0;
uniform int strands : hint_range(1, 3) = 2;
// 1 keeps that end of the bolt on the centre line.
uniform float pin_start : hint_range(0.0, 1.0) = 1.0;
uniform float pin_end : hint_range(0.0, 1.0) = 1.0;
uniform float flicker : hint_range(0.0, 1.0) = 0.3;
uniform float seed = 0.0;
// Width of the quad divided by its length; keeps the line the same thickness on slanted segments.
uniform float aspect = 0.25;
// Turns the quad around its Y axis so it always faces the camera.
uniform bool axial = true;
// Driven by EmbersetEffect on play() / stop().
uniform float fade : hint_range(0.0, 1.0) = 1.0;

varying float v_seed;

void vertex() {
	if (!OUTPUT_IS_SRGB) {
		// Particle and vertex colours arrive in sRGB; the HDR renderers work in linear light.
		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));
	}
	v_seed = seed + fract(float(INSTANCE_ID) * 0.6180339) * 9.0;
	if (axial) {
		vec3 axis = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
		vec3 on_axis = (MODEL_MATRIX * vec4(0.0, VERTEX.y, 0.0, 1.0)).xyz;
		vec3 side = normalize(cross(axis, CAMERA_POSITION_WORLD - on_axis));
		float width = length((MODEL_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
		POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(on_axis + side * VERTEX.x * width, 1.0);
	} else {
		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	}
}

// Bolt offset at height y: straight segments between random points, which gives hard corners.
// Returns the offset in x and the slope in y.
vec2 zigzag(float y, float segments, float salt) {
	float cell = floor(y * segments);
	float a = fract(sin(cell * 127.1 + salt) * 43758.5453) - 0.5;
	float b = fract(sin((cell + 1.0) * 127.1 + salt) * 43758.5453) - 0.5;
	return vec2(mix(a, b, fract(y * segments)), (b - a) * segments);
}

void fragment() {
	float y = 1.0 - UV.y;
	float tick = floor(TIME * rate) + v_seed;
	float env = mix(1.0, smoothstep(0.0, 0.25, y), pin_start) * mix(1.0, smoothstep(0.0, 0.25, 1.0 - y), pin_end);
	float core = 0.0;
	float glow = 0.0;
	for (int i = 0; i < strands; i++) {
		float fi = float(i);
		float salt = tick * 17.31 + fi * 5.7;
		vec2 big = zigzag(y, frequency * 5.0 * (1.0 + fi * 0.5), salt);
		vec2 fine = zigzag(y, frequency * 17.0, salt + 3.3);
		float amp = amplitude * env * (1.0 + fi * 0.5);
		float off = (big.x * 2.0 + fine.x * 0.5) * amp;
		float slope = (big.y * 2.0 + fine.y * 0.5) * amp * aspect;
		float d = abs(UV.x - 0.5 - off) / sqrt(1.0 + slope * slope);
		float w = thickness / (1.0 + fi * 1.5);
		core += smoothstep(w, w * 0.3, d);
		glow += w / (d + w) * 0.6;
	}
	float on = mix(1.0, step(0.3, fract(sin(tick * 12.9898) * 43758.5453)), flicker);
	float a = clamp(core + glow * glow, 0.0, 1.0) * smoothstep(0.5, 0.25, abs(UV.x - 0.5)) * smoothstep(0.0, 0.05, min(UV.y, 1.0 - UV.y)) * on;
	vec3 col = mix(color_glow.rgb, color_core.rgb, clamp(core, 0.0, 1.0)) * COLOR.rgb * emission;
	if (OUTPUT_IS_SRGB) {
		float peak = max(col.r, max(col.g, col.b));
		if (peak > 1.0) {
			col = mix(col / peak, vec3(1.0), clamp((peak - 1.0) * 0.35, 0.0, 1.0));
		}
	}
	ALBEDO = col;
	ALPHA = clamp(a * COLOR.a * fade, 0.0, 1.0);
}
