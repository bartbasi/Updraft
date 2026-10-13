# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Renders the launcher icons from the SVG layers in icons/ into PNGs for the Android export, and
## composes the full rounded icon (icon.svg, the editor's and older Androids' icon) from the same
## layers so they never drift apart.
##   godot --headless --path . -s res://tools/make_icons.gd

const LAYERS := {
	"res://icons/foreground.svg": "res://icons/adaptive_foreground_432.png",
	"res://icons/background.svg": "res://icons/adaptive_background_432.png",
	"res://icons/monochrome.svg": "res://icons/adaptive_monochrome_432.png",
}


## The foreground is drawn this much bigger on the full icon than in the adaptive layer (which keeps
## its art inside the safe zone, at 0.79 of its drawn size).
const FULL_ICON_SCALE := 1.582


func _initialize() -> void:
	_compose_full_icon()
	for svg in LAYERS:
		_render(svg, 1.0).save_png(LAYERS[svg])
		print("saved ", LAYERS[svg])
	# The classic launcher icon (older Android): the full rounded icon at 192 px.
	_render("res://icon.svg", 192.0 / 128.0).save_png("res://icons/main_192.png")
	print("saved res://icons/main_192.png")
	quit()


## icon.svg: the background and foreground layers on a rounded square.
func _compose_full_icon() -> void:
	var text := "<!-- Updraft. Copyright (C) 2026 Bart Basi. Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE. -->\n"
	text += "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"128\" height=\"128\" viewBox=\"0 0 432 432\">\n"
	text += "  <!-- Updraft: made by tools/make_icons.gd from icons/background.svg and icons/foreground.svg. -->\n"
	text += "  <clipPath id=\"round\"><rect width=\"432\" height=\"432\" rx=\"96\"/></clipPath>\n"
	text += "  <g clip-path=\"url(#round)\">\n"
	text += _inner("res://icons/background.svg")
	text += "  <g transform=\"translate(216 216) scale(%s) translate(-216 -216)\">\n" % FULL_ICON_SCALE
	text += _inner("res://icons/foreground.svg")
	text += "  </g>\n  </g>\n</svg>\n"
	var file := FileAccess.open("res://icon.svg", FileAccess.WRITE)
	assert(file != null, "could not write res://icon.svg")
	file.store_string(text)
	file.close()
	print("saved res://icon.svg")


## An SVG file's contents without its outer <svg> element.
func _inner(path: String) -> String:
	var s := FileAccess.get_file_as_string(path)
	var start := s.find(">", s.find("<svg")) + 1
	return s.substr(start, s.rfind("</svg>") - start).strip_edges(false, true) + "\n"


func _render(path: String, scale: float) -> Image:
	var image := Image.new()
	var err := image.load_svg_from_string(FileAccess.get_file_as_string(path), scale)
	assert(err == OK, "could not render %s" % path)
	return image
