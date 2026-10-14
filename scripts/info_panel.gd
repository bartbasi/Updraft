# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name InfoPanel
extends Control
## Info, from the title screen: the player's guide (HowToFly), one section at a time. A rail of
## section buttons runs down the left; the section showing scrolls on the right. Moving focus
## along the rail shows each section in turn, so the arrow keys browse. A section's text is laid
## out a few paragraphs a frame, so a long one never holds up the screen.

signal closed

## Microseconds of each frame spent laying out a section's paragraphs while it fills (at least one).
const FILL_BUDGET_USEC := 4000
const BODY_SIZE := 28
const SUBHEADING_SIZE := 32
## The text column's widest (about 70 characters a line), and how far list items are indented.
const TEXT_WIDTH := 1000.0
const LIST_INDENT := 28.0
## The panel's widest: the rail, the text column and their margins.
const PANEL_WIDTH := 1440.0
## The rail button of the section showing: deeper pink with a lilac rim, to stand out even when
## focus is elsewhere.
const SHOWING_FILL := Color("d9a0b6")

var rail: Array[Button] = []
var back: Button
var showing := -1  ## The section showing (an index into HowToFly.sections()).
var _sections: Array[Dictionary] = []
var _title: Label
var _scroll: ScrollContainer
var _text_box: VBoxContainer
var _pending: PackedStringArray = []  ## Paragraphs still to add to the section showing.
var _right: VBoxContainer
var _margin: MarginContainer
var _list_style: StyleBoxEmpty


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = AboutPanel.page_theme()  # everything else comes from the game's theme above
	_list_style = StyleBoxEmpty.new()
	_list_style.content_margin_left = LIST_INDENT
	_sections = HowToFly.sections()
	_build()
	visible = false
	set_process(false)


## Shows Info on its first section, with that section's button focused.
func open() -> void:
	visible = true
	showing = -1  # always afresh: a section left half-filled is filled again
	show_section(0)
	rail[0].grab_focus()


## Back (or Escape): out of Info.
func go_back() -> void:
	visible = false
	set_process(false)
	closed.emit()


## Shows section `i` from its top, filling it over the next few frames.
func show_section(i: int) -> void:
	rail[i].button_pressed = true
	if showing == i:
		return
	showing = i
	_title.text = _sections[i]["title"]
	for child in _text_box.get_children():
		_text_box.remove_child(child)
		child.queue_free()
	_pending = PackedStringArray(_sections[i]["paragraphs"])
	_pending.reverse()  # taken from the end, so the section fills from the top
	_scroll.scroll_vertical = 0
	set_process(true)


## True once the section showing has all its text.
func is_filled() -> bool:
	return _pending.is_empty()


func _process(_delta: float) -> void:
	var start := Time.get_ticks_usec()
	while not _pending.is_empty():
		var text := _pending[_pending.size() - 1]
		_pending.remove_at(_pending.size() - 1)
		var sub := text.begins_with("## ")
		var label := Label.new()
		label.text = text.trim_prefix("## ")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", SUBHEADING_SIZE if sub else BODY_SIZE)
		label.add_theme_constant_override("outline_size", 0)
		if text.begins_with("- "):  # a list item: wrapped lines stay clear of the dash's column
			label.add_theme_stylebox_override("normal", _list_style)
		_text_box.add_child(label)
		label.get_minimum_size()  # lays the text out now, inside this frame's budget
		if Time.get_ticks_usec() - start > FILL_BUDGET_USEC:
			return
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _right:
		_fit_text()


## The text column takes the room beside the rail, up to TEXT_WIDTH; on a wider screen the panel
## stays its width, centred.
func _fit_text() -> void:
	var side := maxf(40.0, (size.x - PANEL_WIDTH) * 0.5)
	for edge in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + edge, int(side))
	var room := size.x - 2.0 * (side + 32.0) - 280.0 - 2.0 * 32.0
	_right.custom_minimum_size.x = clampf(room, 300.0, TEXT_WIDTH)


func _build() -> void:
	var margin := MarginContainer.new()
	_margin = margin
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var inner := MarginContainer.new()
	for side in ["left", "right"]:
		inner.add_theme_constant_override("margin_" + side, 32)
	for side in ["top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(inner)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	inner.add_child(columns)

	var rail_box := VBoxContainer.new()
	rail_box.add_theme_constant_override("separation", 8)
	rail_box.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(rail_box)
	var group := ButtonGroup.new()
	for i in _sections.size():
		var b := Button.new()
		b.text = _sections[i]["title"]
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(280, 56)
		b.add_theme_font_size_override("font_size", 24)
		for state in ["pressed", "hover_pressed"]:
			var lit := StyleBoxFlat.new()
			lit.bg_color = SHOWING_FILL
			lit.set_corner_radius_all(48)
			lit.set_border_width_all(3)
			lit.border_color = FlightGame.LILAC
			b.add_theme_stylebox_override(state, lit)
		b.pressed.connect(show_section.bind(i))
		b.focus_entered.connect(show_section.bind(i))  # the arrows browse
		rail_box.add_child(b)
		rail.append(b)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	_right = right
	var spare := Control.new()  # any width past TEXT_WIDTH
	spare.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(spare)
	_fit_text()
	var header := HBoxContainer.new()
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 40)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	back = Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(160, 64)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(go_back)
	header.add_child(back)
	right.add_child(header)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_scroll)
	_text_box = VBoxContainer.new()
	_text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_box.add_theme_constant_override("separation", 14)
	_scroll.add_child(_text_box)
