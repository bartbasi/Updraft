# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends TestCase
## The Hangar and the daily flight (docs/hangar-plan.md): the save's new fields and its backup,
## buying and wearing, the looks (which never change flying), the daily's seed and bonus, and the
## screens that reach them.

const TODAY_FILE := "{\"unlocked\":true,\"stars\":1204,\"best_m\":520,\"best_score\":4750,\"last_mode\":\"endless\"}"


func _fresh() -> void:
	for path in [Progress.file_path, Progress.file_path + ".bak", Progress.file_path + ".tmp", BestScore.file_path, PlayerSettings.file_path]:
		var global := ProjectSettings.globalize_path(path)
		if DirAccess.dir_exists_absolute(global):
			DirAccess.remove_absolute(global)
		DirAccess.remove_absolute(global)
	Progress.unlocked_this_session = false
	Daily.today_override = ""


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _with_stars(stars: int, extra := {}) -> void:
	var p := {"unlocked": true, "stars": stars}
	p.merge(extra, true)
	check(Progress.save_all(p), "saved a bank of %d" % stars)


# --- The save --------------------------------------------------------------------------

## The owner's file as it is today loads with everything kept and the new fields at their
## defaults, and round-trips.
func test_todays_save_loads_unchanged() -> void:
	_fresh()
	_write(Progress.file_path, TODAY_FILE)
	var p := Progress.load_all()
	check(p["stars"] == 1204 and p["best_m"] == 520 and p["best_score"] == 4750 and p["unlocked"] and p["last_mode"] == Progress.ENDLESS, "the five fields kept: %s" % p)
	check(p["owned"] == [] and p["wear"] == HangarCatalogue.STARTERS and p["daily_paid"] == "" and p["daily_steps"] == 0, "the new ones at their defaults")
	check(Progress.save_all(p) and Progress.load_all() == p, "and it round-trips")


## Random damage never crashes, never makes the bank negative, and always leaves a wearable look.
func test_damaged_saves_load_safely() -> void:
	_fresh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var junk: Array = [null, true, -1, 1.5, 1e30, "x", "2026-13-40", [], {}, [1, "a"], {"balloon": "rainbow"}, "-1", 6, 100000000000]
	var bad := 0
	for i in 500:
		var raw := {}
		for key in ["stars", "owned", "wear", "daily_date", "daily_paid", "daily_steps", "daily_best_m", "unlocked", "v"]:
			if rng.randf() < 0.6:
				raw[key] = junk[rng.randi() % junk.size()]
		if rng.randf() < 0.1:
			var many := []
			for k in 10000:
				many.append("id%d" % k)
			raw["owned"] = many
		var p := Progress.clean(raw)
		var ok: bool = p["stars"] >= 0 and (p["owned"] as Array).size() <= Progress.MAX_OWNED and p["daily_steps"] >= 0 and p["daily_steps"] <= Daily.MAX_STEPS
		for slot in HangarCatalogue.SLOTS:
			var id: String = p["wear"][slot]
			ok = ok and HangarCatalogue.slot_of(id) == slot and (HangarCatalogue.is_starter(id) or (p["owned"] as Array).has(id))
		if not ok:
			bad += 1
	check(bad == 0, "every damaged save cleans to a safe one (%d bad)" % bad)
	check(Progress.clean({"wear": {"balloon": "rainbow"}})["wear"]["balloon"] == "red", "wearing what isn't owned falls back to the starter")


## An id from a later version is kept; a malformed one isn't.
func test_unknown_owned_ids_survive() -> void:
	_fresh()
	_with_stars(10, {"owned": ["sky", "kitten_face", "BAD ID", 7, "sky"]})
	var owned: Array = Progress.load_all()["owned"]
	check(owned == ["sky", "kitten_face"], "kept once each, malformed ones dropped: %s" % [owned])


## A damaged file loads from the backup of the last good one.
func test_a_damaged_file_loads_its_backup() -> void:
	_fresh()
	_with_stars(700)
	_with_stars(800)  # the 700 file is now the backup
	_write(Progress.file_path, "{not json")
	check(Progress.load_all()["stars"] == 700, "the backup's bank (%d)" % Progress.load_all()["stars"])
	check(Progress.save_all(Progress.load_all()), "saving over the damaged file")
	_write(Progress.file_path, "{not json")
	check(Progress.load_all()["stars"] == 700, "the damaged file was never made the backup")
	_write(Progress.file_path + ".bak", "[]")
	check(Progress.load_all()["stars"] == 0, "both damaged: the defaults")


# --- Buying and wearing ----------------------------------------------------------------

func test_buying_takes_the_exact_price_once() -> void:
	_fresh()
	var price := HangarCatalogue.price("mint")
	_with_stars(price - 1)
	check(not Progress.buy("mint") and Progress.load_all()["stars"] == price - 1, "one star short: refused")
	_with_stars(price)
	check(Progress.buy("mint"), "the exact price buys it")
	var p := Progress.load_all()
	check(p["stars"] == 0 and (p["owned"] as Array).has("mint") and p["wear"]["balloon"] == "mint", "the bank is empty, and it's owned and worn")
	_with_stars(1000, {"owned": ["mint"]})
	check(not Progress.buy("mint") and not Progress.buy("red") and not Progress.buy("kitten_face"), "owned, a starter or unknown: refused")
	check(Progress.load_all()["stars"] == 1000, "and nothing spent")
	check(Progress.wear("red") and Progress.load_all()["wear"]["balloon"] == "red", "a starter can always be worn")
	check(not Progress.wear("rainbow"), "what isn't owned can't be")
	check(not Progress.spend(1001) and Progress.spend(1000) and Progress.load_all()["stars"] == 0, "spend never goes below nothing")


## A save that can't be read (only locked for now) is never written over, so nothing bought or worn
## can replace a bank that's only out of reach (buy() and wear() save through save_all(), and
## also refuse on their own when their load finds the file unreadable).
func test_an_unreadable_save_is_never_written_over() -> void:
	_fresh()
	_with_stars(500, {"owned": ["sky"]})
	var before := FileAccess.get_file_as_string(Progress.file_path)
	var real_load := Progress.file_path
	Progress.load_all()
	Progress.unreadable = true  # as if the file were locked
	var refused := not Progress.save_all({"stars": 0})
	Progress.unreadable = false
	check(refused and FileAccess.get_file_as_string(real_load) == before, "an unreadable save is never written over")
	check(Progress.load_all()["stars"] == 500, "and the bank is untouched")


## A save that fails spends nothing and owns nothing.
func test_a_failed_save_spends_nothing() -> void:
	_fresh()
	_with_stars(500)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(Progress.file_path + ".tmp"))  # the save's temp file can't be written
	check(not Progress.buy("sky"), "the purchase reports failure")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.file_path + ".tmp"))
	var p := Progress.load_all()
	check(p["stars"] == 500 and not (p["owned"] as Array).has("sky"), "and nothing changed")


func test_the_catalogue_is_sound() -> void:
	var font := ThemeDB.fallback_font
	var total := 0
	for id: String in HangarCatalogue.ITEMS:
		var slot := HangarCatalogue.slot_of(id)
		check(slot in HangarCatalogue.SLOTS, "%s has a slot" % id)
		check(RegEx.create_from_string("^[a-z0-9_]{1,24}$").search(id) != null, "%s is a well-formed id" % id)
		var price := HangarCatalogue.price(id)
		check((price == 0) == HangarCatalogue.is_starter(id) and price % 5 == 0, "%s's price %d" % [id, price])
		total += price
		var name := HangarCatalogue.name_of(id)
		for i in name.length():
			check(font.has_char(name.unicode_at(i)), "%s's name is in the font" % id)
	check(total == 13200, "the looks cost 13,200 in all (%d)" % total)
	for slot in HangarCatalogue.SLOTS:
		check(HangarCatalogue.in_slot(slot).has(HangarCatalogue.STARTERS[slot]), "%s has its starter" % slot)


# --- Looks -----------------------------------------------------------------------------

## Every look builds; balloons stay light, and every face points outward.
func test_every_look_builds() -> void:
	for id in HangarCatalogue.in_slot(HangarCatalogue.BALLOON):
		var mesh := Looks.balloon_mesh(id)
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check(verts.size() / 3 <= 900, "%s: %d triangles" % [id, verts.size() / 3])
		var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
		var inward := 0
		for i in range(0, Looks.BALLOON_SEGMENTS * (Looks.BALLOON_RINGS - 2) * 6, 3):  # the body's faces
			if normals[i].dot(verts[i] + verts[i + 1] + verts[i + 2]) < 0.0:
				inward += 1
		check(inward == 0, "%s: no face turned inward (%d)" % [id, inward])
		check(Looks.balloon_material(id) != null and Looks.icon_texture(id) != null, "%s has a material and an icon" % id)
	for id in HangarCatalogue.in_slot(HangarCatalogue.PAPER):
		check(Looks.paper_mesh(id).get_surface_count() == 1 and Looks.icon_texture(id) != null, "%s builds" % id)
	for id in ["polka", "smiley", "starry", "notebook", "graph", "newspaper", "map", "waves"]:
		var size: Vector2i = Looks.icon_texture(id).get_size()
		check(size in [Vector2i(128, 64), Vector2i(256, 128), Vector2i(128, 128)], "%s is painted at %s" % [id, size])
	for id in HangarCatalogue.in_slot(HangarCatalogue.TRAIL):
		if id == "none":
			continue
		var trail: Trail = add_node(Trail.new(id))
		check(trail.particle_count() <= 48, "%s: %d particles" % [id, trail.particle_count()])
		for i in 30:
			trail.follow(Vector3(0, 0, -i * 0.1), 6.0, 1.0 / 60.0)
		await tree.process_frame
		trail.queue_free()


## Looks never change flying: every look, on the balloon and on the plane, flies the starter's
## path to the last bit.
func test_looks_never_change_flight() -> void:
	for look in [PlayerSettings.BALLOON, PlayerSettings.PLANE]:
		var wears: Array[Dictionary] = [HangarCatalogue.STARTERS]
		for id: String in HangarCatalogue.ITEMS:
			var wear: Dictionary = HangarCatalogue.STARTERS.duplicate()
			wear[HangarCatalogue.slot_of(id)] = id
			wears.append(wear)
		var first := PackedVector3Array()
		var differ := PackedStringArray()
		for wear in wears:
			var plane: Flyer = add_node(Flyer.new())
			plane.set_look(look)
			plane.set_wear(wear)
			plane.autopilot = func(_p: Flyer) -> Vector2: return Vector2(0.1, 0.3)
			await physics_frames(1)  # each launched at the same point in a tick
			plane.launch(Vector3(0, 40, 0), 0.0)
			var path := PackedVector3Array()
			for i in 45:
				await physics_frames(1)
				path.append(plane.global_position)
			plane.queue_free()
			if first.is_empty():
				first = path
			elif path != first:
				differ.append(str(wear.values()))
		check(differ.is_empty(), "the %s flies the same in every look: %s" % [look, differ])


func test_crashes_take_the_looks_colours() -> void:
	var plane: Flyer = add_node(Flyer.new())
	plane.set_look(PlayerSettings.BALLOON)
	plane.set_wear({"balloon": "candy", "paper": "lemon", "trail": "none"})
	plane.launch(Vector3(0, 5, 0), 0.0)
	await physics_frames(1)
	plane._pop()
	var colors := plane._scraps.map(func(s: MeshInstance3D) -> Color: return (s.material_override as StandardMaterial3D).albedo_color)
	check(colors.has(Color("e0484f")) and colors.has(Looks.CREAM), "candy stripes pop into red and cream scraps")
	check((plane._ball.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Looks.paper_color("lemon") * Color(1.04, 1.04, 1.06)), "the crumpled ball is lemon")


# --- The daily flight ------------------------------------------------------------------

func test_the_daily_seed_is_fixed_by_the_date() -> void:
	check(Daily.seed_for("2026-10-14") == 1263336384, "FNV-1a of the date, as written out (%d)" % Daily.seed_for("2026-10-14"))
	var ids := func(seed: int) -> Array:
		var gen := EndlessGenerator.new(Tuning.new(), seed)
		var out := []
		for i in 30:
			var p := gen.next()
			out.append([p.id, p.d, p.h_in, p.tile])  # what's placed, how hard, and where: all from the seed
		return out
	check(ids.call(Daily.seed_for("2026-10-14")) == ids.call(Daily.seed_for("2026-10-14")), "the same day: the same country")
	check(ids.call(Daily.seed_for("2026-10-14")) != ids.call(Daily.seed_for("2026-10-15")), "the next day: another")
	check(Daily.is_date("2026-02-28") and not Daily.is_date("2026-02-30") and not Daily.is_date("x") and not Daily.is_date(20261014), "dates are checked")


func test_the_daily_bonus_and_its_gentle_streak() -> void:
	var p := Progress.clean({})
	var day := "2026-10-01"
	var paid: Array[int] = []
	for i in 7:
		var r := Daily.reward(p, day)
		paid.append(r["stars"])
		p["daily_paid"] = day
		p["daily_steps"] = r["steps"]
		day = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(day + "T00:00:00") + 86400)
	check(paid == [100, 120, 140, 160, 180, 200, 200], "days in a row: %s" % [paid])
	check(not Daily.reward(p, p["daily_paid"])["pays"], "the same day pays once")
	check(not Daily.reward(p, "2026-09-01")["pays"], "an earlier day never pays")
	check(Daily.reward(p, "2026-10-09")["stars"] == 180, "one day missed costs one step")
	check(Daily.reward(p, "2026-10-17")["stars"] == 100, "a long gap starts again")


func _daily_game() -> EndlessGame:
	EndlessGame.daily_next = true
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	game.opens_scenes = false
	await physics_frames(2)
	return game


## The bonus is paid with the run's stars in one save, once a day, and today's best is its own.
func test_a_daily_run_pays_once_at_its_end() -> void:
	_fresh()
	Daily.today_override = "2026-10-14"
	_with_stars(10)
	var game := await _daily_game()
	check(game.daily and game.run_seed == Daily.seed_for("2026-10-14"), "a daily run flies today's country")
	game.stars_run = 5
	game.daily_reached = true
	game.furthest_z = EndlessWorld.START.z - 4.0 * 150.0
	game._finish("Touchdown", 0.1, "test")
	var p := Progress.load_all()
	check(p["stars"] == 10 + 5 + 100 and p["daily_paid"] == "2026-10-14" and p["daily_steps"] == 1, "stars and the bonus together: %s" % p)
	check(p["daily_best_m"] == 150 and p["daily_date"] == "2026-10-14", "today's best kept")
	EndlessGame.daily_next = true
	game.start_run(false)
	game.stars_run = 2
	game.daily_reached = true
	game._finish("Touchdown", 0.1, "test")
	check(Progress.load_all()["stars"] == 117, "a second run the same day pays only its stars (%d)" % Progress.load_all()["stars"])
	Daily.today_override = "2026-10-15"
	EndlessGame.daily_next = true
	game.start_run(false)
	check(game.daily_best_m == 0 and game._best_at_start == Daily.GOAL_M, "a new day's best starts afresh, and the bunting marks the bonus's goal")
	game.daily_reached = true
	game.go_to_title()
	check(Progress.load_all()["stars"] == 117 + 120, "leaving after reaching 100 m still pays (%d)" % Progress.load_all()["stars"])
	game.queue_free()
	Daily.today_override = ""


## A run that crosses midnight belongs to the day it began; the new day then pays afresh.
func test_a_daily_run_across_midnight_keeps_its_day() -> void:
	_fresh()
	Daily.today_override = "2026-10-14"
	_with_stars(0)
	var game := await _daily_game()
	game.daily_reached = true
	Daily.today_override = "2026-10-15"  # midnight passes mid-run
	game._finish("Touchdown", 0.1, "test")
	var p := Progress.load_all()
	check(p["daily_paid"] == "2026-10-14" and p["stars"] == 100, "paid to the day it began: %s %d" % [p["daily_paid"], p["stars"]])
	EndlessGame.daily_next = true
	game.start_run(false)
	check(game.daily_date == "2026-10-15" and game._daily_pays["pays"] and game._daily_pays["stars"] == 120, "the next run is the new day's, and its bonus is the streak's next")
	game.queue_free()
	Daily.today_override = ""


func test_a_daily_run_that_falls_short_pays_nothing() -> void:
	_fresh()
	Daily.today_override = "2026-10-14"
	_with_stars(10)
	var game := await _daily_game()
	game.furthest_z = EndlessWorld.START.z - 4.0 * 60.0
	game._finish("Touchdown", 0.1, "test")
	check(Progress.load_all()["stars"] == 10 and Progress.load_all()["daily_paid"] == "", "nothing paid, nothing marked")
	game.queue_free()
	Daily.today_override = ""


# --- Screens ---------------------------------------------------------------------------

func _title() -> TitleScreen:
	var title: TitleScreen = add_node(load(TitleScreen.SCENE).instantiate())
	title.opens_scenes = false
	await tree.process_frame
	return title


func test_daily_and_hangar_appear_once_endless_is_unlocked() -> void:
	_fresh()
	Progress.save_all({"unlocked": false})
	var locked := await _title()
	check(locked.daily == null and locked.hangar == null, "locked: no DAILY or HANGAR")
	locked.queue_free()
	Daily.today_override = "2026-10-14"
	Progress.save_all({"unlocked": true})
	var title := await _title()
	check(title.daily and title.hangar and title.daily_badge.visible and title.daily_badge.text == "+100", "unlocked: both, and today's bonus shows")
	title.daily.pressed.emit()
	check(title.launched_to == EndlessGame.SCENE and EndlessGame.daily_next, "DAILY flies today's flight")
	EndlessGame.daily_next = false
	title.queue_free()
	Progress.save_all({"unlocked": true, "daily_paid": "2026-10-14"})
	var paid := await _title()
	check(not paid.daily_badge.visible, "paid today: no badge")
	paid.queue_free()
	Daily.today_override = ""


## Before Endless is unlocked the Course's card has no Hangar; once it is, the title's arrows reach
## DAILY from PLAY.
func test_locked_cards_have_no_hangar() -> void:
	_fresh()
	Progress.save_all({"unlocked": false})
	var game: FlightGame = add_node(load("res://scenes/main.tscn").instantiate())
	game.opens_scenes = false
	await physics_frames(2)
	game.show_card("Landed", PackedStringArray())
	check(not game._hangar_button.visible, "locked: no Hangar on the card")
	game.queue_free()
	Progress.save_all({"unlocked": true})
	var title := await _title()
	check(title.play.get_node(title.play.focus_neighbor_bottom) == title.daily, "Down from PLAY: DAILY")
	check(title.hangar.get_node(title.hangar.focus_neighbor_top) == title.play, "Up from HANGAR: PLAY")
	title.queue_free()


## On the cover screen and the inner one, the cards fit their column, are big enough to tap, and
## the preview and its button sit clear of them.
func test_the_hangar_fits_both_screens() -> void:
	_fresh()
	Progress.save_all({"unlocked": true, "stars": 300})
	for screen in [Vector2(1844, 720), Vector2(1280, 1066)]:
		var frame := Control.new()
		frame.size = screen
		frame.theme = FlightGame.make_theme()
		add_node(frame)
		var hangar := HangarPanel.new()
		frame.add_child(hangar)
		hangar.size = screen
		hangar.open()
		for i in 4:
			await tree.process_frame
		var grid := hangar._grid.get_global_rect()
		var scroll := hangar._scroll.get_global_rect()
		check(grid.size.x <= scroll.size.x + 1.0, "%s: the cards fit their column (%s in %s)" % [screen, grid.size, scroll.size])
		for card: Button in hangar.cards.values():
			check(card.size.x >= 200 and card.size.y >= 200, "%s: a card of %s" % [screen, card.size])
		var preview := hangar._preview.get_global_rect()
		check(not preview.intersects(scroll) and not hangar.action.get_global_rect().intersects(scroll), "%s: the preview and its button clear of the cards" % screen)
		check(scroll.size.y >= 230, "%s: at least a row of cards in view (%.0f)" % [screen, scroll.size.y])
		check(hangar.get_combined_minimum_size().x <= screen.x and hangar.get_combined_minimum_size().y <= screen.y, "%s: nothing spills off the screen (%s)" % [screen, hangar.get_combined_minimum_size()])
		frame.queue_free()


## Trying on, the two-tap buy, Back from the confirm row, and closing back to the title.
func test_the_hangar_tries_buys_and_steps_back() -> void:
	_fresh()
	Progress.save_all({"unlocked": true, "stars": 160})
	var title := await _title()
	title.hangar.pressed.emit()
	var hangar := title._hangar
	await tree.process_frame
	check(hangar.visible and hangar.tab == HangarCatalogue.BALLOON and hangar.trying == "red", "opens on the balloon, wearing red")
	check(hangar.action.text == "Wearing" and hangar.action.disabled, "red: Wearing")
	hangar.try_on("rainbow")
	check(hangar.action.disabled and hangar.action.text.contains("more"), "too dear: how many more (%s)" % hangar.action.text)
	hangar.try_on("mint")
	check(not hangar.action.disabled and hangar.action.text.begins_with("Buy"), "affordable: Buy")
	hangar.action.pressed.emit()
	check(hangar._confirm.visible and not hangar.action.visible, "the first tap asks")
	check(title.handle_back() and not hangar._confirm.visible and hangar.visible, "Back from the question: back to the item")
	check(Progress.load_all()["stars"] == 160, "nothing spent")
	hangar.action.pressed.emit()
	hangar._confirm_buy.pressed.emit()
	var p := Progress.load_all()
	check(p["stars"] == 10 and p["wear"]["balloon"] == "mint" and hangar.action.text == "Wearing", "the second tap buys and wears it")
	check(PlayerSettings.load_all()["look"] == PlayerSettings.BALLOON, "a balloon look flies the balloon")
	for card: Button in hangar.cards.values():
		check(card.size.x >= 200 and card.size.y >= 200, "cards are big enough to tap (%s)" % card.size)
	hangar.show_tab(HangarCatalogue.PAPER)
	hangar.try_on("plain")
	hangar.action.pressed.emit()  # Wear the plain paper
	check(PlayerSettings.load_all()["look"] == PlayerSettings.PLANE, "wearing a paper look flies the plane")
	check(title.handle_back() and not hangar.visible and title.hangar.has_focus(), "Back: to the title, HANGAR focused")


## The card's Hangar and Daily buttons, and the line when a run makes something affordable.
func test_the_endless_card_points_to_the_hangar_and_the_daily() -> void:
	_fresh()
	Daily.today_override = "2026-10-14"
	Progress.save_all({"unlocked": true, "stars": 40})
	var game: EndlessGame = add_node(load(EndlessGame.SCENE).instantiate())
	game.opens_scenes = false
	await physics_frames(2)
	game.stars_run = 15
	game._finish("Touchdown", 0.0, "test")
	await physics_frames(3)
	check(game._card.visible and game._hangar_button.visible, "the card has the Hangar")
	check(game._daily_button.visible and game._daily_button.text == "Daily +100", "and today's flight while it pays")
	check(game._card_lines.text.contains("Enough for Sky blue in the Hangar!"), "the bank just reached the cheapest look: %s" % game._card_lines.text)
	game.show_hangar()
	check(game._hangar.visible and not game._card.visible, "the Hangar opens over the card")
	game.handle_back()
	check(not game._hangar.visible and game._card.visible and game._hangar_button.has_focus(), "Back returns to the card")
	check(EndlessGame._newly_affordable(60, 70, []) == "", "no line unless the bank crosses a price")
	game.queue_free()
	Daily.today_override = ""


## With the measured earnings (docs/hangar-plan.md §0), a first-timer buys something on day 1 with
## the daily and by run 4 without; a casual player owns everything in 15-25 play days.
func test_the_economy_paces_as_planned() -> void:
	var cheapest := HangarCatalogue.price(HangarCatalogue.cheapest_unowned([]))
	check(16 + Daily.BASE_REWARD >= cheapest, "a first-timer's first run with the daily buys something")
	check(16 * 4 >= cheapest, "and by run 4 without it")
	var total := 0
	for id: String in HangarCatalogue.ITEMS:
		total += HangarCatalogue.price(id)
	var week := [450, 450, 450, 630, 750]  # stars a play day, weeks 1-5 (the plan's casual profile)
	var bank := 0
	var days := 0
	while bank < total and days < 60:
		bank += week[mini(days / 5, week.size() - 1)]
		days += 1
	check(days >= 15 and days <= 25, "a casual player owns everything in %d play days" % days)
