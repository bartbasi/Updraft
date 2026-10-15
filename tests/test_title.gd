# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## The title screen, Info (the player's guide) and the way back: what PLAY opens and says, Back at
## every level, Menu on the end card, and a guide that matches the game.

const SECTIONS: Array[String] = ["Objectives", "Course and Endless", "Places", "Controls", "Updrafts", "Downdrafts", "Points and bonuses", "Hangar and daily flight", "Sounds", "Tips"]


func _title() -> TitleScreen:
	var title: TitleScreen = add_node(load(TitleScreen.SCENE).instantiate())
	title.opens_scenes = false
	await tree.process_frame
	return title


func test_the_game_opens_on_the_title() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == TitleScreen.SCENE, "the main scene is the title")


## PLAY flies the mode flown last, and the caption under it says which (with the bests).
func test_play_opens_the_mode_flown_last_and_says_so() -> void:
	var states := [
		[{}, EndlessGame.COURSE_SCENE, "The Course"],
		[{"unlocked": true, "last_mode": Progress.COURSE}, EndlessGame.COURSE_SCENE, "The Course"],
		[{"unlocked": true, "last_mode": Progress.ENDLESS, "best_m": 812, "stars": 340}, EndlessGame.SCENE, "Endless  ·  best 812 m  ·  340 stars"],
		[{"unlocked": false, "last_mode": Progress.ENDLESS}, EndlessGame.COURSE_SCENE, "The Course"],
	]
	for s in states:
		Progress.save_all(s[0])
		var title := await _title()
		check(title.caption.text.begins_with(s[2]), "caption \"%s\" for %s" % [title.caption.text, s[0]])
		title.play.pressed.emit()
		check(title.launched_to == s[1], "PLAY opens %s (%s)" % [s[1].get_file(), title.launched_to.get_file()])
		check(title.play.disabled and title.play.text == "Taking off...", "and says so, once")
		title.launched_to = "pressed again"
		title.play.pressed.emit()  # a second press (the button is disabled; this is belt and braces)
		check(title.launched_to == "pressed again", "a second press does nothing")
		title.queue_free()
	check(TitleScreen.caption_for(Progress.clean({}), 2340) == "The Course  ·  best 2340", "the Course's best")
	check(TitleScreen.caption_for(Progress.clean({}), 0) == "The Course", "no best yet")


func test_the_title_has_its_three_buttons() -> void:
	var title := await _title()
	check([title.play.text, title.info.text, title.about.text] == ["PLAY", "INFO", "ABOUT"], "PLAY, INFO and ABOUT")
	check(title.play.has_focus(), "PLAY is ready to press")
	check(title.play.size.x >= 440 and title.play.size.y >= 128, "PLAY is big (%s)" % title.play.size)
	for b in [title.info, title.about]:
		check(b.size.x >= 260 and b.size.y >= 96, "%s is thumb-sized (%s)" % [b.text, b.size])


## Back steps out of Info, About and About's pages, one screen at a time, and on the title is left
## to close the game; Escape never closes it.
func test_back_on_the_title_steps_out_one_screen_at_a_time() -> void:
	var title := await _title()
	check(not title.handle_back(), "on the title, Back is left to close the game")
	title.info.pressed.emit()
	check(title._info.visible and not title._menu.visible, "INFO opens Info")
	check(title.handle_back() and not title._info.visible and title._menu.visible, "Back: Info to the title")
	check(title.info.has_focus(), "with INFO focused")
	title.about.pressed.emit()
	var about := title._about
	check(about.visible and about.feedback.has_focus(), "ABOUT opens About, Send feedback first")
	about.show_page("License")
	check(about._reader.visible, "License opens")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	title._unhandled_input(escape)
	check(about._page.visible and not about._reader.visible and about.license.has_focus(), "Escape: License to About, License focused")
	title._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not about.visible and title._menu.visible and title.about.has_focus(), "Back: About to the title, ABOUT focused")
	title._unhandled_input(escape)
	check(title._menu.visible, "Escape on the title does nothing")


func _flight() -> FlightGame:
	var game: FlightGame = add_node(load("res://scenes/main.tscn").instantiate())
	game.opens_scenes = false
	await physics_frames(2)
	return game


## In flight one Back only shows a hint; a second soon after goes to the title. From the end card,
## one Back does; with the settings open, Back closes them first.
func test_back_in_flight_asks_twice() -> void:
	var game := await _flight()
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not game.went_to_title and game._hint.text in [FlightGame.LEAVE_HINT, FlightGame.LEAVE_HINT_PC], "one Back: the hint, and still flying")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.went_to_title, "a second Back soon after: the title")
	game.went_to_title = false
	game._leave_until_msec = Time.get_ticks_msec() - 1  # the hint's moment has passed
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not game.went_to_title, "a second Back after a while asks again")
	game.show_card("Landed", PackedStringArray())
	game.show_settings(true)
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not game._settings_panel.visible and not game.went_to_title, "Back closes the settings first")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.went_to_title, "and from the end card goes to the title")


func test_the_end_card_has_menu_and_settings_have_no_about() -> void:
	var game := await _flight()
	var texts := game._ui.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)
	check(texts.has("Menu") and not texts.has("Quit") and not texts.has("About"), "Menu, no Quit, no About: %s" % [texts])
	check(game.find_children("*", "AboutPanel", true, false).is_empty() and game.get("_about") == null, "a flight never builds About")
	game.show_card("Landed", PackedStringArray())
	check(game._fly_again.has_focus(), "Fly again keeps its focus")
	game._menu.pressed.emit()
	check(game.went_to_title, "Menu goes to the title")


## The guide's sections are Info's rail, in order, and none is empty.
func test_the_guide_has_infos_sections() -> void:
	var sections := HowToFly.sections()
	check(sections.map(func(s: Dictionary) -> String: return s["title"]) == SECTIONS, "the sections, in order: %s" % [sections.map(func(s: Dictionary) -> String: return s["title"])])
	for s in sections:
		check(not (s["paragraphs"] as Array).is_empty(), "%s has text" % s["title"])


## Totals, distances and names in the guide come from the game, not from memory.
func test_the_guide_has_the_games_numbers_and_names() -> void:
	var text := HowToFly.TEXT
	var tune := Tuning.new()
	var total := 0
	for def: Dictionary in Course.style_moment_defs():
		var points := int(tune.style_moments[String(def["id"])]["points"])
		total += points
		var line := "%s: up to %d" % [String(def["title"]).replace("Out the", "Out of the"), points]
		check(text.contains(line), line)
	check(text.contains("All ten together: %d." % total), "the style total, %d" % total)
	check(text.contains("(%d points)" % int(tune.airtime_points_per_second * tune.airtime_max_seconds)), "the airtime cap in points")
	check(text.contains("that's %d points" % (tune.big_star_value * tune.points_per_star)), "a big star in points")
	check(text.contains("worth %d points" % (tune.arc_bonus * tune.points_per_star)), "a full line in points")
	for m in EndlessGame.FRESHENING_AT:
		check(text.contains("%d m" % int(m)), "the breeze freshens at %d m" % int(m))
	for id: StringName in EndlessPieces.TABLE:
		if id == &"rim":
			continue
		check(text.contains(EndlessPieces.NAMES[id]), "names %s" % EndlessPieces.NAMES[id])
		for arc: Dictionary in EndlessPieces.kit(id, 0.0).arcs:
			var t := String(arc.get("title", ""))
			check(t == "" or text.contains(t), "names the line bonus \"%s\"" % t)


## Leaving an Endless run for the title banks its stars, once.
func test_leaving_endless_mid_run_banks_its_stars() -> void:
	Progress.save_all({"unlocked": true, "stars": 40})
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	game.opens_scenes = false
	await physics_frames(2)
	game.stars_run = 7
	game.go_to_title()
	game.go_to_title()
	check(game.went_to_title and Progress.load_all()["stars"] == 47, "the run's 7 stars are banked once (%d)" % Progress.load_all()["stars"])


## Info reopened before a section finished filling fills it afresh.
func test_info_reopened_mid_fill_fills_again() -> void:
	var title := await _title()
	title.show_info()
	var info := title._info
	info.go_back()
	title.show_info()
	var frames := 0
	while not info.is_filled() and frames < 30:
		await tree.process_frame
		frames += 1
	await tree.process_frame
	check(info.is_filled() and info._text_box.get_child_count() == (HowToFly.sections()[0]["paragraphs"] as Array).size(), "Objectives is whole (%d labels)" % info._text_box.get_child_count())


## Every character on the title, Info and About is in the game's font (a phone's own fonts may
## lack some, which would show as boxes).
func test_the_words_are_all_in_the_font() -> void:
	var font := ThemeDB.fallback_font
	var missing := {}
	var all := HowToFly.TEXT + TitleScreen.TAGLINE + AboutPanel.BLURB + AboutPanel.FEEDBACK_ASK + AboutPanel.PRIVACY + AboutPanel.LEGAL \
		+ TitleScreen.caption_for(Progress.clean({"unlocked": true, "last_mode": Progress.ENDLESS}), 0) + FlightGame.LEAVE_HINT + FlightGame.LEAVE_HINT_PC
	for i in all.length():
		var c := all.unicode_at(i)
		if c > 32 and not font.has_char(c):
			missing[String.chr(c)] = true
	check(missing.is_empty(), "characters the font lacks: %s" % [missing.keys()])


## Info shows one section at a time, fills each within a few frames, keeps it within its width,
## and the arrows browse the rail.
func test_info_shows_each_section_quickly() -> void:
	var title := await _title()
	title.show_info()
	var info := title._info
	check(info.showing == 0 and info.rail[0].has_focus() and info.rail[0].button_pressed, "opens on Objectives, its button lit")
	var sections := HowToFly.sections()
	for i in sections.size():
		info.rail[i].grab_focus()
		check(info.showing == i and info.rail[i].button_pressed, "focus on %s shows it" % SECTIONS[i])
		var frames := 0
		while not info.is_filled() and frames < 30:
			await tree.process_frame
			frames += 1
		await tree.process_frame
		check(frames <= 10, "%s fills in %d frames" % [SECTIONS[i], frames])
		check(info._text_box.get_child_count() == (sections[i]["paragraphs"] as Array).size(), "%s: one label a paragraph" % SECTIONS[i])
		check(info._title.text == SECTIONS[i], "titled %s" % SECTIONS[i])
		check(info._text_box.size.x <= info._scroll.size.x + 1.0, "%s wraps within its column" % SECTIONS[i])
	var subs := info._text_box.get_children().filter(func(l: Node) -> bool: return (l as Label).get_theme_font_size("font_size") == InfoPanel.SUBHEADING_SIZE)
	check(subs.all(func(l: Label) -> bool: return not l.text.begins_with("#")), "sub-headings show without their mark")
	info.back.pressed.emit()
	check(not info.visible and title.info.has_focus(), "Back returns to the title")
