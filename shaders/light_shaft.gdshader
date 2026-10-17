// Updraft. Copyright 2026 Play, Inc.
// Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
// Soft shaft of sunlight from a window down to a warm patch on the floor.
// UV.y runs 0 at the floor to 1 toward the light.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.6, 1.0);
uniform float strength = 0.22;
uniform float floor_glow = 0.55;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Faces seen edge-on (the shaft's silhouette) fade out.
	float facing = abs(dot(NORMAL, VIEW));
	float along = UV.y;
	// Brightest toward the light, fading toward the floor; the floor patch itself glows.
	float shaft = mix(0.35, 1.0, along) * smoothstep(0.0, 0.15, along) * (1.0 - smoothstep(0.85, 1.0, along));
	float is_floor = 1.0 - step(0.001, along);
	float shimmer = 0.85 + 0.15 * sin(TIME * 1.3 + world_pos.x * 0.7 + world_pos.y * 0.4 + world_pos.z * 0.5);
	float a = mix(shaft * strength * (0.4 + 0.6 * facing), floor_glow, is_floor) * shimmer;
	ALBEDO = tint.rgb * a;
}
