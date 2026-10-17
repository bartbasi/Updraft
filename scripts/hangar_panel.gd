# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name HangarPanel
extends Control
## The Hangar: spend banked stars on looks (HangarCatalogue), from the title or over the end card.
## A live preview of the flyer, with the item's name and one action under it, beside tabs and a
## grid of cards (or above them, on a screen taller than wide). Tapping a card tries it on at
## once, owned or not; buying takes two taps and saves before anything changes (Progress.buy);
## wearing a balloon look flies the balloon and a paper look the plane. Closing puts back
## anything only tried on. Stars come only from flying: nothing here costs money.

signal closed

const CARD := Vector2(230, 230)
const ICON := 140.0
const LILAC_FILL := Color("e4d6ee")
const SIDE_BY_SIDE := 1.3  ## Width / height at or above which the preview sits beside the cards.

var back: Button
var action: Button
var tabs: Array[Button] = []
var cards := {}  ## id -> Button
var trying := ""  ## The item on the preview.
var tab := HangarCatalogue.BALLOON
var _progress := {}
var _look := PlayerSettings.BALLOON
var _body: BoxContainer
var _left: BoxContainer  ## The preview and its details: above each other, or side by side when stacked.
var _details: VBoxContainer
var _preview: LookPreview
var _name: Label
var _flies: Label
var _message: Label
var _confirm: HBoxContainer
var _confirm_text: Label
var _confirm_buy: Button
var _confirm_no: Button
var _grid: GridContainer
var _scroll: ScrollContainer
var _bank: Label
var _bank_shown := 0.0
var _sparkle: AudioStreamPlayer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = AboutPanel.page_theme()
	_build()
	visible = false


## Opens on the tab of the flyer flown, with what's worn on the preview.
func open() -> void:
	_progress = Progress.load_all()
	_look = PlayerSettings.load_all()["look"]
	_show_bank(_progress["stars"])
	visible = true
	_fit()
	show_tab(HangarCatalogue.BALLOON if _look == PlayerSettings.BALLOON else HangarCatalogue.PAPER)
	tabs[HangarCatalogue.SLOTS.find(tab)].grab_focus()


## Back: from the confirm row to the item; otherwise out of the Hangar.
func go_back() -> void:
	if _confirm.visible:
		_show_action()
		action.grab_focus()
		return
	visible = false
	closed.emit()


## Shows a tab's cards, trying on what's worn in that slot.
func show_tab(slot: String) -> void:
	tab = slot
	for i in tabs.size():
		tabs[i].button_pressed = HangarCatalogue.SLOTS[i] == slot
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	cards.clear()
	for id in HangarCatalogue.in_slot(slot):
		var card := _card(id)
		cards[id] = card
		_grid.add_child(card)
	_scroll.scroll_vertical = 0
	try_on(_progress["wear"][slot])
	_scroll.ensure_control_visible.call_deferred(cards[trying])  # the worn card in view


## Puts `id` on the preview (owned or not) and shows what can be done with it.
func try_on(id: String) -> void:
	trying = id
	var wear: Dictionary = _progress["wear"].duplicate()
	wear[HangarCatalogue.slot_of(id)] = id
	var slot := HangarCatalogue.slot_of(id)
	var balloon := slot == HangarCatalogue.BALLOON or (slot == HangarCatalogue.TRAIL and _look == PlayerSettings.BALLOON)
	_preview.show_look(wear, balloon)
	_name.text = HangarCatalogue.name_of(id)
	if slot != HangarCatalogue.TRAIL and balloon != (_look == PlayerSettings.BALLOON):
		_flies.text = "Wear it to fly the balloon" if balloon else "Wear it to fly the paper plane"
	else:
		_flies.text = "You fly the balloon" if _look == PlayerSettings.BALLOON else "You fly the paper plane"
	_message.text = ""
	_show_action()
	_refresh_cards()


func owns(id: String) -> bool:
	return HangarCatalogue.is_starter(id) or (_progress["owned"] as Array).has(id)


func wears(id: String) -> bool:
	var slot := HangarCatalogue.slot_of(id)
	var flyer_matches := slot == HangarCatalogue.TRAIL or (slot == HangarCatalogue.BALLOON) == (_look == PlayerSettings.BALLOON)
	return _progress["wear"][slot] == id and flyer_matches


## The action button: Wear, Wearing, Buy (with the price), or how many more stars it needs.
func _show_action() -> void:
	_confirm.visible = false
	action.visible = true
	var id := trying
	var price := HangarCatalogue.price(id)
	action.disabled = false
	if Progress.unreadable:
		action.text = "Can't reach your save right now"
		action.disabled = true
	elif wears(id):
		action.text = "Wearing"
		action.disabled = true
	elif owns(id):
		action.text = "Wear"
	elif price <= int(_progress["stars"]):
		action.text = "Buy  ·  %s stars" % HangarCatalogue.stars_text(price)
	else:
		action.text = "%s stars: %s more" % [HangarCatalogue.stars_text(price), HangarCatalogue.stars_text(price - int(_progress["stars"]))]
		action.disabled = true


func _on_action() -> void:
	var id := trying
	if owns(id):
		_wear(id)
	else:
		action.visible = false
		_confirm.visible = true
		_confirm_text.text = "Buy %s for %s stars?" % [HangarCatalogue.name_of(id), HangarCatalogue.stars_text(HangarCatalogue.price(id))]
		_confirm_buy.grab_focus()


## The second tap: saves the purchase first; only then does anything change.
func _on_confirm() -> void:
	var id := trying
	if not Progress.buy(id):
		_progress = Progress.load_all()
		_show_action()
		_message.text = "Couldn't save. Nothing was spent."
		return
	_progress = Progress.load_all()
	_set_flyer(id)
	create_tween().tween_method(_show_bank, _bank_shown, float(_progress["stars"]), 0.4)  # the bank counts down
	_sparkle.play()
	_preview.hurry()
	try_on(id)
	action.grab_focus()


func _wear(id: String) -> void:
	if not Progress.wear(id):
		_message.text = "Couldn't save. Nothing changed."
		return
	_progress = Progress.load_all()
	_set_flyer(id)
	try_on(id)
	action.grab_focus()


## A balloon look flies the balloon; a paper look, the plane (saved with the settings).
func _set_flyer(id: String) -> void:
	var slot := HangarCatalogue.slot_of(id)
	if slot == HangarCatalogue.TRAIL:
		return
	var look := PlayerSettings.BALLOON if slot == HangarCatalogue.BALLOON else PlayerSettings.PLANE
	if look != _look:
		_look = look
		var settings := PlayerSettings.load_all()
		settings["look"] = look
		if not PlayerSettings.save_all(settings):
			push_warning("Could not save the flyer chosen; it lasts until the game closes.")


func _show_bank(stars: float) -> void:
	_bank_shown = stars
	_bank.text = HangarCatalogue.stars_text(roundi(stars))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _body:
		_fit()


## Side by side on a wide screen, stacked on a tall one.
func _fit() -> void:
	var wide := size.x >= size.y * SIDE_BY_SIDE
	_body.vertical = not wide
	# Stacked (a tall screen): the preview, a fixed 330 tall, with its name and button beside it,
	# and the cards get the rest.
	_left.vertical = wide
	_left.size_flags_vertical = Control.SIZE_EXPAND_FILL if wide else Control.SIZE_SHRINK_BEGIN
	_preview.custom_minimum_size = Vector2(0, 300) if wide else Vector2(0, 330)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL if wide else Control.SIZE_FILL
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.size_flags_vertical = Control.SIZE_SHRINK_END if wide else Control.SIZE_SHRINK_CENTER
	_details.custom_minimum_size = Vector2(0, 0) if wide else Vector2(440, 0)
	var room := size.x * (0.6 if wide else 1.0) - 100.0  # the cards' share, less the margins
	_grid.columns = clampi(int((room + 16.0) / (CARD.x + 16.0)), 2, 4)


# --- Building ----------------------------------------------------------------------

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var inner := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(inner)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	inner.add_child(column)

	var bar := HBoxContainer.new()
	back = _button("Back", Vector2(160, 64), 26)
	back.pressed.connect(go_back)
	bar.add_child(back)
	var title := _label("Hangar", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(title)
	var star := EndlessGame.StarIcon.new()
	star.custom_minimum_size = Vector2(30, 30)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(star)
	_bank = _label("0", 32)
	_bank.custom_minimum_size = Vector2(120, 0)
	bar.add_child(_bank)
	column.add_child(bar)

	_body = BoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 24)
	column.add_child(_body)

	var left := BoxContainer.new()
	left.vertical = true
	_left = left
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.67
	left.add_theme_constant_override("separation", 6)
	_body.add_child(left)
	_preview = LookPreview.new(true)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_preview)
	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 6)
	left.add_child(_details)
	_name = _label("", 34)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details.add_child(_name)
	_flies = _label("", 20)
	_flies.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flies.modulate.a = 0.75
	_details.add_child(_flies)
	action = _button("", Vector2(340, 88), 28)
	action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action.pressed.connect(_on_action)
	_details.add_child(action)
	_confirm = HBoxContainer.new()
	_confirm.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm.add_theme_constant_override("separation", 12)
	_confirm.visible = false
	_confirm_text = _label("", 24)
	_confirm.add_child(_confirm_text)
	_confirm_buy = _button("Buy", Vector2(140, 80), 28)
	var gold := StyleBoxFlat.new()
	gold.bg_color = Color("f4c84a")
	gold.set_corner_radius_all(48)
	_confirm_buy.add_theme_stylebox_override("normal", gold)
	_confirm_buy.pressed.connect(_on_confirm)
	_confirm.add_child(_confirm_buy)
	_confirm_no = _button("Not now", Vector2(160, 80), 24)
	_confirm_no.pressed.connect(go_back)
	_confirm.add_child(_confirm_no)
	_details.add_child(_confirm)
	_message = _label("", 22)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details.add_child(_message)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	_body.add_child(right)
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 12)
	var group := ButtonGroup.new()
	for slot in HangarCatalogue.SLOTS:
		var b := _button(HangarCatalogue.TABS[slot], Vector2(200, 64), 26)
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(show_tab.bind(slot))
		var lit := StyleBoxFlat.new()
		lit.bg_color = InfoPanel.SHOWING_FILL
		lit.set_corner_radius_all(48)
		lit.set_border_width_all(3)
		lit.border_color = FlightGame.LILAC
		b.add_theme_stylebox_override("pressed", lit)
		b.add_theme_stylebox_override("hover_pressed", lit)
		tab_row.add_child(b)
		tabs.append(b)
	right.add_child(tab_row)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_scroll.add_child(_grid)

	_sparkle = AudioStreamPlayer.new()
	_sparkle.stream = load("res://audio/style_perfect.wav")
	_sparkle.volume_db = -6.0
	add_child(_sparkle)


## One item's card: its picture, its name, and whether it's worn, owned or its price.
func _card(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.pressed.connect(try_on.bind(id))
	b.focus_entered.connect(try_on.bind(id))  # the arrows browse
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var icon := ItemIcon.new()
	icon.id = id
	icon.custom_minimum_size = Vector2(ICON, ICON * 0.8)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var title := _label(HangarCatalogue.name_of(id), 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var status := HBoxContainer.new()
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	status.add_theme_constant_override("separation", 4)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.name = "Status"
	box.add_child(status)
	return b


## Every card's status line, and the worn one's lilac fill.
func _refresh_cards() -> void:
	for id: String in cards:
		var b: Button = cards[id]
		var status: HBoxContainer = b.find_child("Status", true, false)
		for child in status.get_children():
			status.remove_child(child)
			child.queue_free()
		var worn := wears(id)
		if worn:
			var fill := StyleBoxFlat.new()
			fill.bg_color = LILAC_FILL
			fill.set_corner_radius_all(24)
			b.add_theme_stylebox_override("normal", fill)
		else:
			var plain := StyleBoxFlat.new()
			plain.bg_color = Color("f8eef3") if id != trying else Color("f2c6d4")
			plain.set_corner_radius_all(24)
			b.add_theme_stylebox_override("normal", plain)
		if worn or owns(id):
			var l := _label("Wearing" if worn else "Owned", 20)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			status.add_child(l)
		else:
			var price := HangarCatalogue.price(id)
			var star := EndlessGame.StarIcon.new()
			star.custom_minimum_size = Vector2(20, 20)
			star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			star.mouse_filter = Control.MOUSE_FILTER_IGNORE
			status.add_child(star)
			var l := _label(HangarCatalogue.stars_text(price), 22)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if price <= int(_progress["stars"]):
				l.add_theme_color_override("font_color", Color("b8862a"))
			else:
				l.modulate.a = 0.5
			status.add_child(l)


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_constant_override("outline_size", 0)
	return l


func _button(text: String, min_size: Vector2, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	return b


## A card's picture: a balloon in its colours or pattern, a paper dart in its colour or design, or
## a little curl of the trail.
class ItemIcon:
	extends Control
	var id := ""

	func _draw() -> void:
		var c := size * 0.5
		match HangarCatalogue.slot_of(id):
			HangarCatalogue.BALLOON:
				var pts := PackedVector2Array()
				var uvs := PackedVector2Array()
				var r := Vector2(size.y * 0.36, size.y * 0.42)
				for k in 32:
					var a := TAU * k / 32.0
					pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
					uvs.append(Vector2(0.5 + cos(a) * 0.22, 0.5 + sin(a) * 0.5))  # the front half, as the camera sees it
				draw_colored_polygon(pts, Color.WHITE, uvs, Looks.icon_texture(id))
				draw_line(c + Vector2(0, r.y), c + Vector2(-3, r.y + size.y * 0.1), Flyer.STRING_COLOR.darkened(0.2), 2.0)
			HangarCatalogue.PAPER:
				var pts := PackedVector2Array([c + Vector2(-size.x * 0.4, size.y * 0.25), c + Vector2(size.x * 0.42, -size.y * 0.3), c + Vector2(-size.x * 0.05, size.y * 0.35)])
				draw_colored_polygon(pts, Color.WHITE, PackedVector2Array([Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1)]), Looks.icon_texture(id))
				draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color("b8acc9"), 2.0)
			_:
				_draw_trail(c)

	func _draw_trail(c: Vector2) -> void:
		var curve := PackedVector2Array()
		for k in 24:
			var t := k / 23.0
			curve.append(c + Vector2(lerpf(-size.x * 0.4, size.x * 0.4, t), sin(t * TAU) * size.y * 0.18))
		match id:
			"ribbon":
				draw_polyline(curve, Color("f29bb8"), 8.0, true)
			"rainbowtrail":
				for k in Looks.RAINBOW.size():
					var off := Vector2(0, (k - 3) * 3.0)
					draw_polyline(Array(curve).map(func(p: Vector2) -> Vector2: return p + off), Looks.RAINBOW[k], 3.0, true)
			"confetti":
				for k in 12:
					draw_rect(Rect2(curve[k * 2] - Vector2(5, 5) + Vector2(0, (k % 3) * 6.0), Vector2(10, 10)), Trail.CONFETTI[k % 5])
			"petals":
				for k in 9:
					draw_set_transform(curve[k * 2 + 2] + Vector2(0, (k % 2) * 8.0), k * 0.7, Vector2(1.6, 1.0))
					draw_circle(Vector2.ZERO, 6.0, Color("f6c3d3") if k % 2 else Color("f29bb8"))
				draw_set_transform(Vector2.ZERO)
			_:
				draw_polyline(curve, Color(FlightGame.INK, 0.25), 2.0, true)  # no trail
