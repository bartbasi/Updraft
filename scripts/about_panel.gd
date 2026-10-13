# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name AboutPanel
extends Control
## About Updraft, opened from the settings: what the game is and who made it, a request for
## feedback with a button that starts an email, a link to the source code, and three pages to
## read: How to fly (the player's guide, HowToFly), License (Updraft's notice, with its additional
## terms, and the GNU GPL) and Credits (the Godot Engine's notices and those of its third-party
## parts). The game builds this panel the
## first time it is opened, and each page's text the first time that page is shown, a few
## paragraphs a frame, so a long page never holds up the game. The labels on those pages don't
## word-wrap (re-wrapping every label as the page grew made filling slow): the license texts
## come in short lines, and the few long ones are broken here.

signal closed

const AUTHOR := "Bart Basi"
const FEEDBACK_EMAIL := "bartbasi@gmail.com"
const SOURCE_URL := "https://github.com/bartbasi/Updraft"
const LICENSE_PATH := "res://LICENSE"
const NOTICE_PATH := "res://NOTICE"
const BLURB := "Ride warm air through a house, down a valley and out over a lake, in a red balloon or a paper plane. Tilt your phone to steer."
const FEEDBACK_ASK := "I'd love to hear what you think: what you enjoyed, where you got stuck, and what you'd like to see next."
const LEGAL := "Copyright © 2026 Bart Basi. Updraft is free software: you may share and change it under the GNU GPL v3, with the terms on the License page. It comes with no warranty."
## A page's text is split into labels of about this many characters, at blank lines, so the
## labels scrolled out of sight are not drawn.
const CHUNK_CHARS := 800
## Lines longer than this are broken at a space (the page is about 100 characters wide).
const WRAP_COLUMN := 92
## Microseconds of each frame spent laying out a page's labels while it fills (at least one).
const FILL_BUDGET_USEC := 4000
const INK := Color("5d5468")  ## The game's ink and lilac (game.gd), for the scroll bar.
const LILAC := Color("c9b2d6")

var guide: Button
var feedback: Button
var source: Button
var license: Button
var credits: Button
var done: Button
var back: Button
var _page: Control  ## The About page.
var _reader: Control  ## The License or Credits page.
var _reader_title: Label
var _scroll: ScrollContainer
var _text_box: VBoxContainer
var _pending: PackedStringArray = []  ## Paragraph chunks still to add to the page shown.
var _showing := ""  ## Which page the reader holds: GUIDE, "License", "Credits" or "".
const GUIDE := "How to fly"


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _scroll_bar_theme()  # everything else comes from the game's theme above
	_build_page()
	_build_reader()
	set_process(false)


## Shows the About page, with its first button ready to press.
func open() -> void:
	visible = true
	_reader.visible = false
	_page.visible = true
	guide.grab_focus()


## Back (or Escape): from a page to the About page, and from there out of About.
func go_back() -> void:
	if _reader.visible:
		_reader.visible = false
		_page.visible = true
		var buttons := {GUIDE: guide, "License": license, "Credits": credits}
		(buttons.get(_showing, guide) as Button).grab_focus()
	else:
		visible = false
		closed.emit()


## The game's version, as the project settings give it (the same as the Android export's).
static func version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))


## The phone (or computer) this is running on, for a feedback email: model and system.
static func device() -> String:
	return "%s, %s %s" % [OS.get_model_name(), OS.get_name(), OS.get_version()]


## A mailto: link that opens the player's email app with a new message to the feedback address:
## the subject names the game and version, and the body leaves room to write above a short line
## saying which version and phone it came from. Nothing is sent unless the player sends it.
static func feedback_url(p_version: String, p_device: String) -> String:
	var subject := "Updraft feedback (version %s)" % p_version
	var body := "\n\n\n--\nSent from Updraft %s on %s" % [p_version, p_device]
	return "mailto:%s?subject=%s&body=%s" % [FEEDBACK_EMAIL, subject.uri_encode(), body.uri_encode()]


## The License page: Updraft's notice and additional terms, then the GNU GPL itself.
static func license_text() -> String:
	return "%s\n\n%s" % [_read(NOTICE_PATH), _read(LICENSE_PATH)]


## The Credits page: who made Updraft, then the Godot Engine's license, the copyright notices
## of the third-party parts built into it, and the full text of each of their licenses.
static func credits_text() -> String:
	var parts := PackedStringArray([
		"Updraft\nMade by %s. Its code, art and sounds were made for Updraft and are covered by Updraft's license (see License), except the watercolour look's random-number hash, which is Chris Wellons' public-domain \"lowbias32\"." % AUTHOR,
		"Built with the Godot Engine %s (godotengine.org)\n\n%s" % [_godot_version(), Engine.get_license_text()],
		"Portions of this software are copyright (c) %s The FreeType Project (www.freetype.org). All rights reserved." % _freetype_years(),
		"On Android, Updraft also includes the AndroidX libraries and the Kotlin standard library, under the Apache License 2.0 (its text is below).",
		"Third-party parts of the Godot Engine",
	])
	for component: Dictionary in Engine.get_copyright_info():
		if component["name"] == "Godot Engine":
			continue  # its license is above
		var lines := PackedStringArray([component["name"]])
		for part: Dictionary in component["parts"]:
			for holder: String in part["copyright"]:
				lines.append("Copyright (c) " + holder)
			lines.append("License: " + String(part["license"]))
		parts.append("\n".join(lines))
	parts.append("License texts")
	var licenses := Engine.get_license_info()
	for license_name: String in licenses:
		parts.append("%s\n\n%s" % [license_name, licenses[license_name]])
	return "\n\n".join(parts)


## The years in FreeType's copyright, as the engine lists it (for the credit FreeType asks for).
static func _freetype_years() -> String:
	for component: Dictionary in Engine.get_copyright_info():
		if String(component["name"]).begins_with("FreeType"):
			return String(component["parts"][0]["copyright"][0]).get_slice(",", 0)
	return "1996-2025"


## The Godot Engine's version, as "4.7.2".
static func _godot_version() -> String:
	var v := Engine.get_version_info()
	return "%d.%d.%d" % [v["major"], v["minor"], v["patch"]]


## Splits `text` at blank lines into chunks of about CHUNK_CHARS characters (a paragraph longer
## than that is a chunk on its own), with lines longer than WRAP_COLUMN broken. With `headings`,
## a paragraph starting "# " is a chunk of its own (the page shows it as a heading).
static func chunks(text: String, headings := false) -> PackedStringArray:
	var out := PackedStringArray()
	var group := PackedStringArray()  # the paragraphs of the chunk being gathered
	var size := 0
	for paragraph in wrap_lines(text, WRAP_COLUMN).split("\n\n"):
		if headings and paragraph.begins_with("# "):  # a heading: a chunk of its own
			if not group.is_empty():
				out.append("\n\n".join(group))
				group.clear()
				size = 0
			out.append(paragraph)
			continue
		if not group.is_empty() and size + paragraph.length() > CHUNK_CHARS:
			out.append("\n\n".join(group))
			group.clear()
			size = 0
		group.append(paragraph)
		size += paragraph.length() + 2
	if not group.is_empty():
		out.append("\n\n".join(group))
	return out


## Breaks each line longer than `column` characters at its last space before the column (or at
## the column, if it has no space there), keeping the line's indent on the lines it breaks into.
## An indent of half the column or more is dropped there, so every break makes progress, and a
## line of nothing but spaces becomes empty.
static func wrap_lines(text: String, column: int) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		if line.strip_edges() == "":
			out.append("")
			continue
		var indent := line.substr(0, line.length() - line.lstrip(" ").length())
		if indent.length() >= column / 2:
			indent = ""
		while line.length() > column:
			var cut := line.rfind(" ", column)
			if cut <= indent.length():
				cut = column
			out.append(line.substr(0, cut).rstrip(" "))
			line = indent + line.substr(cut).lstrip(" ")
		out.append(line)
	return "\n".join(out)


static func _read(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		push_warning("Could not read %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return "(%s is missing; see %s)" % [path.get_file(), SOURCE_URL]
	return text.strip_edges()


func _on_feedback() -> void:
	_open_link(feedback_url(version(), device()))


func _on_source() -> void:
	_open_link(SOURCE_URL)


func _open_link(url: String) -> void:
	var err := OS.shell_open(url)
	if err != OK:
		push_warning("Could not open %s (%s)" % [url, error_string(err)])


## Shows the License or Credits page, filling it the first time (and after the other one).
func show_page(which: String) -> void:
	_page.visible = false
	_reader.visible = true
	back.grab_focus()
	if _showing == which:
		return
	_showing = which
	_reader_title.text = which
	for child in _text_box.get_children():
		child.queue_free()
	_pending = page_chunks(which)
	_pending.reverse()  # taken from the end, so the page fills from the top
	_scroll.scroll_vertical = 0
	set_process(true)


## A page's text in chunks, as its labels show it.
static func page_chunks(which: String) -> PackedStringArray:
	match which:
		GUIDE:
			return chunks(HowToFly.TEXT, true)
		"License":
			return chunks(license_text())
	return chunks(credits_text())


## True once the page shown has all its text.
func is_page_filled() -> bool:
	return _pending.is_empty()


func _process(_delta: float) -> void:
	var start := Time.get_ticks_usec()
	while not _pending.is_empty():
		var label := Label.new()
		var text := _pending[_pending.size() - 1]
		_pending.remove_at(_pending.size() - 1)
		var heading := _showing == GUIDE and text.begins_with("# ")
		label.text = text.trim_prefix("# ") if heading else text
		label.add_theme_font_size_override("font_size", 30 if heading else 20)
		label.add_theme_constant_override("outline_size", 0)
		_text_box.add_child(label)
		label.get_minimum_size()  # lays the text out now, inside this frame's budget
		if Time.get_ticks_usec() - start > FILL_BUDGET_USEC:
			return
	set_process(false)


# --- Building ----------------------------------------------------------------------

func _build_page() -> void:
	_page = CenterContainer.new()
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var box := _panel(_page)
	var title := _label("Updraft", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var byline := _label("Version %s  ·  Made by %s" % [version(), AUTHOR], 22)
	byline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(byline)
	box.add_child(_paragraph(BLURB, 26))
	box.add_child(_paragraph(FEEDBACK_ASK, 26))
	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 14)
	main_row.alignment = BoxContainer.ALIGNMENT_CENTER
	guide = _button(GUIDE, Vector2(300, 80), 32)
	guide.pressed.connect(show_page.bind(GUIDE))
	feedback = _button("Send feedback", Vector2(300, 80), 32)
	feedback.pressed.connect(_on_feedback)
	main_row.add_child(guide)
	main_row.add_child(feedback)
	box.add_child(main_row)
	# The address too, for a phone with no email app (where the button can do nothing).
	var address := _label(FEEDBACK_EMAIL, 22)
	address.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(address)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	source = _button("Source code", Vector2(220, 64), 26)
	source.pressed.connect(_on_source)
	license = _button("License", Vector2(180, 64), 26)
	license.pressed.connect(show_page.bind("License"))
	credits = _button("Credits", Vector2(180, 64), 26)
	credits.pressed.connect(show_page.bind("Credits"))
	done = _button("Done", Vector2(160, 64), 26)
	done.pressed.connect(go_back)
	for b in [source, license, credits, done]:
		row.add_child(b)
	box.add_child(row)
	box.add_child(_paragraph(LEGAL, 19))


func _build_reader() -> void:
	_reader = MarginContainer.new()
	_reader.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		_reader.add_theme_constant_override("margin_" + side, 60)
	for side in ["top", "bottom"]:
		_reader.add_theme_constant_override("margin_" + side, 30)
	_reader.visible = false
	add_child(_reader)
	var box := _panel(_reader)
	var header := HBoxContainer.new()
	_reader_title = _label("", 40)
	_reader_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_reader_title)
	back = _button("Back", Vector2(160, 64), 26)
	back.pressed.connect(go_back)
	header.add_child(back)
	box.add_child(header)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_scroll)
	_text_box = VBoxContainer.new()
	_text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_box.add_theme_constant_override("separation", 20)
	_scroll.add_child(_text_box)


## A soft lilac scroll bar, wide enough to drag with a thumb.
func _scroll_bar_theme() -> Theme:
	var t := Theme.new()
	var track := StyleBoxFlat.new()
	track.bg_color = Color(LILAC, 0.35)
	track.set_corner_radius_all(8)
	track.content_margin_left = 8.0
	track.content_margin_right = 8.0
	t.set_stylebox("scroll", "VScrollBar", track)
	for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var grab := StyleBoxFlat.new()
		grab.bg_color = Color(INK, {"grabber": 0.45, "grabber_highlight": 0.6, "grabber_pressed": 0.75}[state])
		grab.set_corner_radius_all(8)
		t.set_stylebox(state, "VScrollBar", grab)
	return t


## A cream panel (the game's theme) holding a column; returns the column.
func _panel(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	return box


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label


## A centred paragraph that wraps at the About page's width.
func _paragraph(text: String, size: int) -> Label:
	var label := _label(text, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(860, 0)
	return label


func _button(text: String, min_size: Vector2, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	return b
