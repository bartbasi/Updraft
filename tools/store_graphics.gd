# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Makes the Play store's app icon and feature graphic from the game's own art, into
## docs/store/graphics/. Needs a real window (not --headless) for the feature graphic:
##   godot --path . --resolution 1024x500 -s res://tools/store_graphics.gd
## The icon is the launcher icon's two layers (icons/) on a full square: Play rounds the corners
## and adds the shadow itself. The feature graphic is the title screen's painted sky, flyer and
## name, without its buttons. Uses scratch saves, never the player's own. The screenshots are made
## by tools/make_store_graphics.sh, and tools/check_store.py checks them all.

const OUT := "res://docs/store/graphics"
const ICON_SIZE := 512
const FEATURE := Vector2i(1024, 500)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(out)
	_icon().save_png(out.path_join("icon_512.png"))
	print("saved icon_512.png")
	if root.size != FEATURE:
		push_error("the feature graphic needs --resolution %dx%d (the window is %s)" % [FEATURE.x, FEATURE.y, root.size])
		quit(1)
		return
	Progress.file_path = "user://store_progress.json"
	PlayerSettings.file_path = "user://store_settings.json"
	Progress.save_all({"unlocked": false})
	PlayerSettings.save_all({"look": PlayerSettings.BALLOON})
	var title: TitleScreen = load(TitleScreen.SCENE).instantiate()
	title.opens_scenes = false
	root.add_child(title)
	await process_frame
	# Only the sky, the flyer, the name and the tagline: no buttons, caption or version.
	for node: Control in [title.play, title.caption, title.info.get_parent(), title.coffee.get_parent()]:
		node.visible = false
	for label in title._menu.find_children("*", "Label", true, false):
		if (label as Label).text.begins_with("Version"):
			label.visible = false
	for i in 90:  # the clouds and motes settle into place
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)  # 24-bit, no alpha, as Play asks
	image.save_png(out.path_join("feature_graphic_1024x500.png"))
	print("saved feature_graphic_1024x500.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PlayerSettings.file_path))
	quit()


## The launcher icon's background and foreground (drawn as big as on the full icon, icon.svg) on
## a full square, with every pixel opaque.
func _icon() -> Image:
	var fg_scale: float = load("res://tools/make_icons.gd").FULL_ICON_SCALE
	var text := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"432\" height=\"432\" viewBox=\"0 0 432 432\">\n"
	text += _inner("res://icons/background.svg")
	text += "<g transform=\"translate(216 216) scale(%s) translate(-216 -216)\">\n" % fg_scale
	text += _inner("res://icons/foreground.svg")
	text += "</g>\n</svg>\n"
	var image := Image.new()
	var err := image.load_svg_from_string(text, float(ICON_SIZE) / 432.0)
	assert(err == OK, "could not render the icon")
	image.convert(Image.FORMAT_RGBA8)  # 32-bit, as Play asks
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 1.0:
				image.set_pixel(x, y, Color(c, 1.0))
	return image


## An SVG file's contents without its outer <svg> element.
func _inner(path: String) -> String:
	var s := FileAccess.get_file_as_string(path)
	var start := s.find(">", s.find("<svg")) + 1
	return s.substr(start, s.rfind("</svg>") - start).strip_edges(false, true) + "\n"
