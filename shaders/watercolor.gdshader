// Full-screen pass: soft watercolour look on paper.
// Slight pigment wobble, darker edges where colours meet, paper grain and a gentle vignette.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float edge_darkening = 0.35;
uniform float edge_width = 1.4;    // in pixels at 720p, scaled with resolution
uniform float wobble = 1.3;        // pixels of pigment wobble at 720p
uniform float grain = 0.075;
uniform vec3 paper_tint = vec3(1.0, 0.985, 0.95);
uniform float vignette = 0.25;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	// Work in "720p pixels" so the effect looks the same on any screen.
	float scale = (1.0 / SCREEN_PIXEL_SIZE.y) / 720.0;
	vec2 p720 = SCREEN_UV / SCREEN_PIXEL_SIZE / scale;
	vec2 px = SCREEN_PIXEL_SIZE * scale;

	vec2 w = vec2(noise(p720 * 0.035), noise(p720 * 0.035 + 31.7)) - 0.5;
	vec2 uv = SCREEN_UV + w * wobble * px;
	vec3 c = texture(screen_tex, uv).rgb;

	vec2 e = px * edge_width;
	vec3 n = texture(screen_tex, uv + vec2(0.0, e.y)).rgb;
	vec3 s = texture(screen_tex, uv - vec2(0.0, e.y)).rgb;
	vec3 r = texture(screen_tex, uv + vec2(e.x, 0.0)).rgb;
	vec3 l = texture(screen_tex, uv - vec2(e.x, 0.0)).rgb;
	vec3 lap = abs(n + s + r + l - 4.0 * c);
	float edge = smoothstep(0.03, 0.3, dot(lap, vec3(0.333)));
	c *= 1.0 - edge * edge_darkening;

	// Pigment pools a little unevenly: large soft blotches.
	float blot = noise(p720 * 0.012) * 0.6 + noise(p720 * 0.04) * 0.4;
	c *= 0.95 + 0.08 * blot;

	// Paper fibres.
	float g = noise(p720 * 0.9) * 0.55 + noise(p720 * 0.3 + 7.0) * 0.45;
	c *= 1.0 - grain + grain * 1.4 * g;
	c *= paper_tint;

	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - dot(d, d) * vignette;
	COLOR = vec4(c, 1.0);
}
