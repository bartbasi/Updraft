// Updraft. Copyright 2026 Play, Inc.
// Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
// Soft, shimmering column of moving air drawn around a thermal or downdraft.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.72, 0.3);
uniform float height = 8.0;
uniform float rise_speed = 1.2;
uniform float direction = 1.0;  // 1 = streaks rise, -1 = streaks fall (downdraft)

varying float along;

void vertex() {
	along = VERTEX.y / height + 0.5; // 0 at the bottom of the column, 1 at the top
}

void fragment() {
	// Brightest where we look through the middle of the column, fading at its silhouette.
	float facing = abs(dot(NORMAL, VIEW));
	float body = pow(facing, 1.3);
	float ends = smoothstep(0.0, 0.12, along) * (1.0 - smoothstep(0.65, 1.0, along));
	// Wavy streaks that drift upward.
	float y = along * height;
	float t = TIME * direction;
	float streaks = 0.5 + 0.5 * sin(UV.x * 6.2832 * 9.0 + sin(y * 1.3 - t * 1.7) * 1.4);
	float bands = 0.5 + 0.5 * sin(y * 1.6 - t * rise_speed * 3.0);
	float shimmer = mix(0.45, 1.0, streaks * bands);
	ALBEDO = tint.rgb;
	// Seen from inside or close by, the column thins out, so it never washes over the plane.
	float near_fade = mix(0.35, 1.0, smoothstep(2.0, 8.0, length(VERTEX)));
	ALPHA = tint.a * body * ends * shimmer * near_fade;
}
