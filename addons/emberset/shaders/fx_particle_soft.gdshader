shader_type spatial;
// Additive particle sprite that fades out where it meets other geometry, so large glows
// and flashes are not cut off in a hard line by the floor or a wall. Reads the depth texture.
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#define EMBERSET_SOFT
#include "fx_particle.gdshaderinc"
