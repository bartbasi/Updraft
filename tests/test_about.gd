# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## About, the license and the credits: what they say, how they open and close, and that the
## license notice ships with the game and sits at the top of every source file.

const HEADER := "Updraft. Copyright (C) 2026 Bart Basi."


func test_feedback_email_is_addressed_and_says_which_version_and_phone() -> void:
	var url := AboutPanel.feedback_url("1.2.3", "samsung SM-F946U1, Android 14")
	check(url.begins_with("mailto:bartbasi@gmail.com?subject="), "addressed to the feedback email: %s" % url)
	check(not url.contains(" ") and not url.contains("\n"), "spaces and line breaks are encoded")
	var subject := url.get_slice("subject=", 1).get_slice("&", 0).uri_decode()
	var body := url.get_slice("&body=", 1).uri_decode()
	check(subject == "Updraft feedback (version 1.2.3)", "subject: %s" % subject)
	check(body.begins_with("\n\n\n"), "room to write above the version line")
	check(body.ends_with("Sent from Updraft 1.2.3 on samsung SM-F946U1, Android 14"), "body: %s" % body)
	check(not AboutPanel.device().is_empty(), "the device is named")
	var awkward := AboutPanel.feedback_url("1.0", "A&B #1 ?x=% é")
	check(awkward.count("&") == 1 and awkward.count("?") == 1 and not awkward.contains("#"), "odd characters in a model name are encoded: %s" % awkward)
	check(awkward.get_slice("&body=", 1).uri_decode().ends_with("on A&B #1 ?x=% é"), "and decode back")


func test_license_page_has_the_notice_its_terms_and_the_whole_gpl() -> void:
	var text := AboutPanel.license_text()
	for part in ["Copyright (C) 2026 Bart Basi", "Based on Updraft by Bart Basi", "WITHOUT ANY WARRANTY",
			"https://github.com/bartbasi/Updraft", "GNU GENERAL PUBLIC LICENSE", "Version 3, 29 June 2007",
			"END OF TERMS AND CONDITIONS"]:
		check(text.contains(part), "the License page says \"%s\"" % part)
	check(text.find("Based on Updraft") < text.find("GNU GENERAL PUBLIC LICENSE"), "Updraft's notice comes first")


func test_credits_page_has_godots_license_and_every_third_party_license() -> void:
	var text := AboutPanel.credits_text()
	check(text.contains("Made by Bart Basi"), "names the author")
	check(text.contains("The FreeType Project (www.freetype.org)"), "the credit FreeType asks for")
	check(text.contains("AndroidX") and text.contains("Kotlin"), "the Android libraries in the APK")
	check(text.contains("Apache License"), "and the Apache License text the AndroidX line points to")
	check(text.contains("lowbias32"), "credits the shader's public-domain hash")
	check(text.contains(Engine.get_license_text().strip_edges().get_slice("\n", 0)), "Godot's own license")
	var licenses := Engine.get_license_info()
	check(licenses.size() > 5, "Godot lists its third-party licenses (%d)" % licenses.size())
	for license_name: String in licenses:
		check(text.contains(String(licenses[license_name]).strip_edges().get_slice("\n", 0)), "the text of %s" % license_name)
	var components := 0
	for component: Dictionary in Engine.get_copyright_info():
		if text.contains(String(component["name"])):
			components += 1
	check(components == Engine.get_copyright_info().size(), "every component (%d of %d)" % [components, Engine.get_copyright_info().size()])


func test_long_lines_are_broken_and_nothing_is_lost() -> void:
	var line := "    " + " ".join(PackedStringArray(range(60).map(func(i: int) -> String: return "word%d" % i)))
	var wrapped := AboutPanel.wrap_lines("short\n" + line + "\n" + "x".repeat(130), 40)
	var lines := wrapped.split("\n")
	for l in lines:
		check(l.length() <= 40, "no line over 40: %d" % l.length())
	check(lines[1].begins_with("    word0") and lines[2].begins_with("    word"), "a broken line keeps its indent")
	check(wrapped.replace("\n", "").replace(" ", "") == ("short" + line + "x".repeat(130)).replace(" ", ""), "every word is kept")
	check(AboutPanel.wrap_lines(" ".repeat(100), 92) == "", "a line of spaces becomes empty")
	var deep := AboutPanel.wrap_lines(" ".repeat(95) + "word " + "more ".repeat(30), 92)
	for l in deep.split("\n"):
		check(l.length() <= 92, "a deeply indented line still breaks (%d)" % l.length())
	check(deep.replace("\n", "").replace(" ", "") == ("word" + "more".repeat(30)), "and keeps its words")
	# A first paragraph longer than a chunk on its own (short lines, so nothing is broken), then
	# an empty one, which starts the next chunk.
	var rows := PackedStringArray()
	for _i in 11:
		rows.append("a".repeat(79))
	var blanks := "\n".join(rows) + "\n\n\n\n" + "b".repeat(50) + "\n\n\n\n\n\nc"
	check("\n".join(rows).length() > AboutPanel.CHUNK_CHARS, "(the empty paragraph falls on a chunk's edge)")
	check("\n\n".join(AboutPanel.chunks(blanks)) == blanks, "blank lines at a chunk's edge are kept")
	for page in [AboutPanel.license_text(), AboutPanel.credits_text()]:
		var chunks := AboutPanel.chunks(page)
		check(chunks.size() > 3, "a long page is split (%d chunks)" % chunks.size())
		check("\n\n".join(chunks) == AboutPanel.wrap_lines(page, AboutPanel.WRAP_COLUMN), "chunks hold the whole page in order")
		for c in chunks:
			for l in c.split("\n"):
				check(l.length() <= AboutPanel.WRAP_COLUMN, "lines fit the page (%d)" % l.length())


func test_version_matches_the_android_exports_and_they_ship_the_license() -> void:
	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg") == OK, "export presets load")
	var version := AboutPanel.version()
	check(version != "", "the game has a version")
	for i in 2:
		check(presets.get_value("preset.%d.options" % i, "version/name") == version, "preset %d is version %s" % [i, version])
		var include := String(presets.get_value("preset.%d" % i, "include_filter"))
		check(include.contains("LICENSE") and include.contains("NOTICE"), "preset %d ships LICENSE and NOTICE: %s" % [i, include])


func test_about_opens_from_settings_and_back_steps_out_one_page_at_a_time() -> void:
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	await physics_frames(2)
	check(game._about == null, "About is not built until it is opened")
	game.show_settings(true)
	game.show_about()
	var about: AboutPanel = game._about
	check(about.visible and not game._settings_panel.visible, "About opens over the settings")
	about.show_page("License")
	check(about._reader.visible and not about._page.visible, "License opens")
	var frames := 0
	while not about.is_page_filled() and frames < 300:
		await tree.process_frame
		frames += 1
	check(about.is_page_filled(), "the License page fills (%d frames)" % frames)
	check(about._text_box.get_child_count() == AboutPanel.chunks(AboutPanel.license_text()).size(), "one label per chunk")
	# The phone's Back arrives as a notification, Escape as ui_cancel; both step back.
	check(not ProjectSettings.get_setting("application/config/quit_on_go_back"), "Back doesn't quit before the game can step back")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(about.visible and about._page.visible and not about._reader.visible, "Back: License to About")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	game._unhandled_input(escape)
	check(not about.visible and game._settings_panel.visible, "Escape: About to the settings")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not game._settings_panel.visible and game._card.visible, "Back: the settings close")
	check(not game.handle_back(), "with nothing open, Back is left to quit the game")
	game.show_about()
	check(game._about == about and about.visible and about._page.visible, "About opens again, on its first page")
	about.go_back()
	check(not about.visible and game._settings_panel.visible, "Done goes back to the settings")


func test_switching_pages_while_one_fills_shows_only_the_new_page_and_it_fits() -> void:
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	await physics_frames(2)
	game.show_settings(true)
	game.show_about()
	var about: AboutPanel = game._about
	about.show_page("License")
	var waited := 0
	while about._text_box.get_child_count() == 0 and waited < 60:
		await tree.process_frame
		waited += 1
	var part := about._text_box.get_child_count()
	check(part > 0 and part < AboutPanel.chunks(AboutPanel.license_text()).size(), "License is part filled when Credits is opened (%d labels)" % part)
	about.go_back()
	about.show_page("Credits")
	var frames := 0
	while not about.is_page_filled() and frames < 600:
		await tree.process_frame
		frames += 1
	await tree.process_frame  # the License labels are freed at the end of a frame
	await tree.process_frame
	check(about._reader_title.text == "Credits", "titled Credits")
	check(about._text_box.get_child_count() == AboutPanel.chunks(AboutPanel.credits_text()).size(), "only the Credits labels (%d)" % about._text_box.get_child_count())
	# A line too wide would widen the whole page (the scroll area grows to fit it), so the page
	# must fit the screen.
	var page := about._reader.get_combined_minimum_size().x
	var screen := about.get_viewport_rect().size.x
	check(page > 0.0 and page <= screen, "the page, widest line and all, fits the screen (%.0f of %.0f)" % [page, screen])


func test_every_source_file_carries_the_license_header() -> void:
	var missing := PackedStringArray()
	for dir in ["res://scripts", "res://tests", "res://tools", "res://shaders"]:
		for file in DirAccess.get_files_at(dir):
			if not file.get_extension() in ["gd", "gdshader", "py", "sh"]:
				continue
			var path: String = dir.path_join(file)
			var head := FileAccess.get_file_as_string(path).substr(0, 300)
			if not head.contains(HEADER):
				missing.append(path)
	for path in ["res://icon.svg", "res://icons/background.svg", "res://icons/foreground.svg", "res://icons/monochrome.svg"]:
		if not FileAccess.get_file_as_string(path).begins_with("<!-- " + HEADER):
			missing.append(path)
	check(missing.is_empty(), "files without the header: %s" % ", ".join(missing))


## The guide must say what the game does: every style moment, every landing bonus, the scoring
## numbers, and Endless's star values, as the game has them now.
func test_the_guide_matches_the_game() -> void:
	var text := HowToFly.TEXT.to_lower()
	for def: Dictionary in Course.style_moment_defs():
		var title := String(def["title"]).to_lower()
		check(text.contains(title) or text.contains(title.replace("out the", "out of the")), "names the style moment \"%s\"" % title)
	var tune := Tuning.new()
	var spots := {"lavender": "lavender", "picnic": "picnic blanket", "island": "island", "beach": "beach"}
	for id: String in tune.landing_bonus:
		var line := "%s (+%d)" % [spots[id], int(tune.landing_bonus[id])]
		check(text.contains(line), "gives the %s landing's bonus: %s" % [id, line])
	check(text.contains("%d points for every metre" % int(tune.points_per_meter)), "distance points")
	check(text.contains("%d points for every second in the air outdoors, up to %d seconds" % [int(tune.airtime_points_per_second), int(tune.airtime_max_seconds)]), "airtime points")
	check(text.contains("big stars are worth %d" % tune.big_star_value) and text.contains("(+%d)" % tune.arc_bonus), "star values")
	check(text.contains("%d points for every metre and %d for every star" % [EndlessGame.POINTS_PER_METRE, tune.points_per_star]), "Endless's score")
	for piece in ["barley field", "viaduct"]:
		check(text.contains(piece), "mentions the %s" % piece)


func test_the_guide_page_shows_its_headings() -> void:
	var chunks := AboutPanel.page_chunks(AboutPanel.GUIDE)
	var headings := Array(chunks).filter(func(c: String) -> bool: return c.begins_with("# "))
	check(headings.size() >= 8, "the guide has its sections (%d)" % headings.size())
	check(chunks[1] == "# Controls", "after a line of welcome, it opens with the controls: %s" % chunks[1].left(30))
	var game: Node = add_node(load("res://scenes/main.tscn").instantiate())
	await physics_frames(2)
	game.show_settings(true)
	game.show_about()
	var about: AboutPanel = game._about
	check(about.guide.has_focus(), "How to fly is the first thing to press")
	about.show_page(AboutPanel.GUIDE)
	var frames := 0
	while not about.is_page_filled() and frames < 300:
		await tree.process_frame
		frames += 1
	var big := about._text_box.get_children().filter(func(l: Node) -> bool: return (l as Label).get_theme_font_size("font_size") == 30)
	check(big.size() == headings.size() and (big[0] as Label).text == "Controls", "headings show large, without their mark")
	about.go_back()
	check(about.guide.has_focus(), "Back returns to How to fly")
