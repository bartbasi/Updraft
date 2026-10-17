# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Links
extends RefCounted
## The addresses the game hands to the phone (an email draft, the source code, Buy me a coffee)
## and the Buy me a coffee button, shown on the title screen and in About. A link only goes to
## the phone's own email app or browser (OS.shell_open), which needs no permission; the game
## itself sends nothing. If nothing can open it, nothing happens and nothing is shown.

const COFFEE_URL := "https://buymeacoffee.com/playinc"
const COFFEE_TEXT := "Buy me a coffee"
const CUP := Color("5d5468")  ## The game's ink, as the button's words.
const STEAM := Color("a993b8")  ## A deeper lilac.

## Who opens a link. Empty means the phone (OS.shell_open); the test runner puts a recorder
## here so no test ever opens a browser.
static var opener := Callable()


## Hands `url` to the phone's email app or browser.
static func open(url: String) -> void:
	if opener.is_valid():
		opener.call(url)
		return
	var err := OS.shell_open(url)
	if err != OK:
		push_warning("Could not open %s (%s)" % [url, error_string(err)])


static func open_coffee() -> void:
	open(COFFEE_URL)


## A Buy me a coffee button with a little cup beside the words, set in by `inset` pixels (so a
## rounded button's curve doesn't cut into the cup).
static func coffee_button(font_size: int, min_size: Vector2, inset := 0) -> Button:
	var b := Button.new()
	b.text = COFFEE_TEXT
	b.icon = cup_icon(int(font_size * 1.4), inset)
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_constant_override("h_separation", int(font_size * 0.4))
	b.pressed.connect(open_coffee)
	return b


## A cup on a saucer with two curls of steam, `px` pixels square, drawn the way the title's hills
## and cottage are: flat shapes in the game's colours (each pixel sampled 4 x 4 for soft edges),
## with `inset` clear pixels to its left.
static func cup_icon(px: int, inset := 0) -> ImageTexture:
	var img := Image.create_empty(px + inset, px, false, Image.FORMAT_RGBA8)
	const N := 4
	for y in px:
		for x in px:
			var cup := 0
			var steam := 0
			for sy in N:
				for sx in N:
					var p := Vector2((x + (sx + 0.5) / N) / px, (y + (sy + 0.5) / N) / px)
					if _in_cup(p):
						cup += 1
					elif _in_steam(p):
						steam += 1
			var color := Color(CUP, float(cup) / (N * N)) if cup >= steam else Color(STEAM, float(steam) / (N * N))
			img.set_pixel(x + inset, y, color)
	return ImageTexture.create_from_image(img)


## The cup, its handle and the saucer, in a unit square (y down).
static func _in_cup(p: Vector2) -> bool:
	if p.y >= 0.42 and p.y <= 0.84:  # the cup narrows a little toward its foot
		var t := (p.y - 0.42) / 0.42
		var half := lerpf(0.29, 0.22, t * t)
		if absf(p.x - 0.44) <= half:
			return true
	var ring := p.distance_to(Vector2(0.75, 0.58))  # the handle
	if p.x > 0.7 and ring >= 0.07 and ring <= 0.13:
		return true
	var d := Vector2((p.x - 0.44) / 0.4, (p.y - 0.88) / 0.06)  # the saucer
	return d.length_squared() <= 1.0


## Two curls of steam rising over the cup.
static func _in_steam(p: Vector2) -> bool:
	if p.y < 0.06 or p.y > 0.36:
		return false
	for cx: float in [0.35, 0.53]:
		var x := cx + 0.045 * sin((p.y - 0.06) / 0.3 * TAU + cx * 9.0)
		if absf(p.x - x) <= 0.035:
			return true
	return false
