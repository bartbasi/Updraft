extends SceneTree
## Renders the launcher icons from the SVG layers in icons/ into PNGs for the Android export.
##   godot --headless --path . -s res://tools/make_icons.gd

const LAYERS := {
	"res://icons/foreground.svg": "res://icons/adaptive_foreground_432.png",
	"res://icons/background.svg": "res://icons/adaptive_background_432.png",
	"res://icons/monochrome.svg": "res://icons/adaptive_monochrome_432.png",
}


func _initialize() -> void:
	for svg in LAYERS:
		_render(svg, 1.0).save_png(LAYERS[svg])
		print("saved ", LAYERS[svg])
	# The classic launcher icon (older Android): the full rounded icon at 192 px.
	_render("res://icon.svg", 192.0 / 128.0).save_png("res://icons/main_192.png")
	print("saved res://icons/main_192.png")
	quit()


func _render(path: String, scale: float) -> Image:
	var image := Image.new()
	var err := image.load_svg_from_string(FileAccess.get_file_as_string(path), scale)
	assert(err == OK, "could not render %s" % path)
	return image
