# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessGenerator
extends RefCounted
## Chooses the order of Endless's pieces (docs/endless-plan.md §2.5). It keeps `h`, the height a
## pilot who flew every ideal line so far is guaranteed when the last piece ends, and only places a
## piece whose need (the lowest entry height that flies it with room to spare) is at least
## `margin` below h, so lift is always in reach. It also never repeats a piece too soon, never runs
## too many pieces without lift in a row, and brings a rest piece round often enough. Forks (two
## roads round a hill: docs/forks-plan.md §4) come every FORK_GAP placements from FORK_FIRST_M on,
## as soon as one is fair; a fork's follower (F2's Viaduct) comes straight after it. Pure logic: no
## nodes, so it can be run thousands of times in tests; and the flight never feeds back into it,
## so a seed (the daily flight's) gives the same country whatever road is flown.

## A placed piece: which one, the tile it starts on, the difficulty it was placed at, and the
## guaranteed heights going in and coming out.
class Placement:
	var id: StringName
	var tile := 0
	var d := 0.0
	var h_in := 0.0
	var h_out := 0.0

	func _init(p_id: StringName, p_tile: int, p_d: float, p_h_in: float, p_h_out: float) -> void:
		id = p_id
		tile = p_tile
		d = p_d
		h_in = p_h_in
		h_out = p_h_out


## Metres a tile is long (96 units, at 4 units to the metre).
const TILE_METRES := 24.0
## Every run begins with these two.
const OPENING: Array[StringName] = [&"rim", &"street"]
## The rescue piece, placed when nothing else is fair.
const RESCUE := &"street"
## Pieces looked ahead when choosing, so a choice never corners the run (see _choose()).
const LOOK_AHEAD := 2
## A piece whose bold line dives to a low opening is this much less likely when a good pilot will
## come in too high for it.
const HIGH_ENTRY_WEIGHT := 0.25
## The first fork is due at the first place at or after this many metres; then the next is due this
## many placements after each fork (a seeded draw, made when the fork is placed).
const FORK_FIRST_M := 120.0
const FORK_GAP := Vector2i(6, 10)
## Pieces with a kitten on the line come at least this many places apart.
const KITTEN_GAP := 3

var tuning: Tuning
var placed: Array[Placement] = []
## The guaranteed height leaving the last placed piece.
var h := 0.0
var rng := RandomNumberGenerator.new()
## For calibrating pieces (tools/endless_log.gd --calibrate): these pieces in this order instead of
## the opening and the rules, at difficulty `forced_d` (if 0 or more), entered at `forced_h`.
var forced: Array[StringName] = []
var forced_d := -1.0
var forced_h := 0.0
## For test pilots: pieces are chosen as if the run had begun this many metres along.
var metres_offset := 0.0
var _next_tile := 0
var _seen := {}  ## Piece ids placed so far this run.
## The placement index at which a fork is due (-1: not yet), the piece that must follow the fork
## just placed (or none), and the last fork placed.
var _fork_due := -1
var _follower: StringName = &""
var _last_fork: StringName = &""


func _init(p_tuning: Tuning, p_seed: int) -> void:
	tuning = p_tuning
	rng.seed = p_seed


## Difficulty (0..1) at a distance in metres.
func difficulty(metres: float) -> float:
	return clampf(metres / tuning.endless_full_distance_m, 0.0, 1.0)


## How far below the guaranteed height a piece's need must be.
func margin(d: float) -> float:
	return lerpf(tuning.endless_margin.x, tuning.endless_margin.y, d)


## The most pieces without lift allowed in a row.
static func max_without_lift(d: float) -> int:
	return 1 if d < 0.5 else 2


## A rest piece must come at least once in this many places.
static func rest_every(d: float) -> int:
	return [3, 3, 4, 4, 5][roundi(clampf(d, 0.0, 1.0) * 4.0)]


## How many of the last pieces may not come again.
static func no_repeat(d: float) -> int:
	return 2 if d < 0.5 else 3


## Places the next piece and returns it.
func next() -> Placement:
	var metres := _next_tile * TILE_METRES + metres_offset
	var d := difficulty(metres)
	var id: StringName
	if not forced.is_empty():
		id = forced[mini(placed.size(), forced.size() - 1)]
		if forced_d >= 0.0:
			d = forced_d
	elif placed.size() < OPENING.size():
		id = OPENING[placed.size()]
	elif _follower != &"":
		id = _follower
		_follower = &""
	else:
		id = _choose(metres, d)
	var info := EndlessPieces.info(id)
	var h_in := h if not placed.is_empty() else (forced_h if not forced.is_empty() else 0.0)
	var h_out := EndlessPieces.out(id, d, h_in)
	var p := Placement.new(id, _next_tile, d, h_in, h_out)
	placed.append(p)
	_seen[id] = true
	h = h_out
	_next_tile += int(info["tiles"])
	return p


## The tile the next piece will start on.
func next_tile() -> int:
	return _next_tile


func _choose(metres: float, _d: float) -> StringName:
	var ids := _placed_ids()
	var fork := _fork(ids, metres)
	if fork != &"":
		return fork
	var pool := _fair(ids, h, metres)
	if pool.is_empty():
		return RESCUE
	# Not a piece after which the run would be cornered (only the rescue left, repeating), looking
	# LOOK_AHEAD pieces on. Picks are tried in the usual weighted order; the first that keeps a way
	# on is taken (nearly always the first).
	var options := pool.duplicate()
	while not options.is_empty():
		var weights := PackedFloat32Array()
		for id in options:
			var w := 1.0 if int(EndlessPieces.info(id)["tiles"]) == 1 else 0.6
			if not _seen.has(id):
				w *= 1.5
			if bool(EndlessPieces.info(id).get("high_line", false)) and h >= EndlessPieces.HIGH_FROM:
				w *= HIGH_ENTRY_WEIGHT  # mostly after a lower exit, where its bold line is in reach
			weights.append(w)
		var pick: StringName = options[rng.rand_weighted(weights)]
		var after := ids.duplicate()
		after.append(pick)
		if _way_on(after, EndlessPieces.out(pick, difficulty(metres), h), metres + EndlessPieces.tiles(pick) * TILE_METRES, LOOK_AHEAD):
			return pick
		options.erase(pick)
	return pool[rng.randi() % pool.size()]


## A fork, if one is due and fair now (and then the next one's due place is drawn, and its
## follower is queued); otherwise none, and it stays due.
func _fork(ids: Array[StringName], metres: float) -> StringName:
	if metres >= FORK_FIRST_M and _fork_due < 0:
		_fork_due = placed.size()
	if _fork_due < 0 or placed.size() < _fork_due:
		return &""
	var d := difficulty(metres)
	if _since_rest(ids) >= rest_every(d) - 1:
		return &""  # a rest piece that is due comes first
	var recent := ids.slice(maxi(ids.size() - no_repeat(d), 0))
	var fair: Array[StringName] = []
	for id: StringName in EndlessPieces.ids():
		var info := EndlessPieces.info(id)
		if not bool(info.get("fork", false)) or float(info["min_m"]) > metres or recent.has(id):
			continue
		if EndlessPieces.need_in(id, d) > h - margin(d):
			continue
		var out := EndlessPieces.out(id, d, h)
		var after := ids.duplicate()
		after.append(id)
		var on_m := metres + EndlessPieces.tiles(id) * TILE_METRES
		var follower: StringName = info.get("follower", &"")
		if follower != &"":
			if EndlessPieces.need_in(follower, difficulty(on_m)) > out - margin(difficulty(on_m)):
				continue  # the follower must be fair after the fork,
			if after.slice(maxi(after.size() - no_repeat(difficulty(on_m)), 0)).has(follower):
				continue  # not one of the last few,
			if _since_rest(ids) + 2 >= rest_every(d):
				continue  # and leave room for the rest piece that will be due
			after.append(follower)
			out = EndlessPieces.out(follower, difficulty(on_m), out)
			on_m += EndlessPieces.tiles(follower) * TILE_METRES
		if _way_on(after, out, on_m, LOOK_AHEAD):
			fair.append(id)
	if fair.is_empty():
		return &""
	if fair.size() > 1 and fair.has(_last_fork):
		fair.erase(_last_fork)  # not the same fork twice running when the other is fair
	var pick: StringName = fair[0] if fair.size() == 1 else fair[rng.randi() % fair.size()]
	_last_fork = pick
	_follower = EndlessPieces.info(pick).get("follower", &"")
	_fork_due = placed.size() + (2 if _follower != &"" else 1) + rng.randi_range(FORK_GAP.x, FORK_GAP.y)
	return pick


## Whether, after the pieces `ids` leaving a good pilot at height `at_h`, `metres` along, there is
## a fair choice for each of the next `depth` pieces.
func _way_on(ids: Array[StringName], at_h: float, metres: float, depth: int) -> bool:
	if depth <= 0:
		return true
	var d := difficulty(metres)
	for id in _fair(ids, at_h, metres):
		var after := ids.duplicate()
		after.append(id)
		if _way_on(after, EndlessPieces.out(id, d, at_h), metres + EndlessPieces.tiles(id) * TILE_METRES, depth - 1):
			return true
	return false


## The pieces the rules allow next, after `ids`, for a good pilot at height `at_h`, `metres` along:
## allowed that far along, not one of the last few, with lift after too many pieces without it, a
## rest piece if none has come for a while, and needing no more than the height a good pilot is
## sure to have, less the margin.
func _fair(ids: Array[StringName], at_h: float, metres: float) -> Array[StringName]:
	var d := difficulty(metres)
	var recent := ids.slice(maxi(ids.size() - no_repeat(d), 0))
	var lift_due := _trailing_without_lift(ids) >= max_without_lift(d)
	# No hazard piece straight after another (two apart early on), and kittens 3 places apart.
	var hazard_near := ids.slice(maxi(ids.size() - (1 if d >= 0.5 else 2), 0)).any(func(id: StringName) -> bool: return bool(EndlessPieces.info(id).get("hazard", false)))
	var kitten_near := ids.slice(maxi(ids.size() - KITTEN_GAP, 0)).any(func(id: StringName) -> bool: return bool(EndlessPieces.info(id).get("kitten", false)))
	var rest_due := _since_rest(ids) >= rest_every(d) - 1
	var room := at_h - margin(d)
	var pool: Array[StringName] = []
	for id: StringName in EndlessPieces.ids():
		var info := EndlessPieces.info(id)
		if bool(info.get("fixed", false)) or bool(info.get("fork", false)) or float(info["min_m"]) > metres or recent.has(id):
			continue  # (forks come only as forks: see _fork(); the look-ahead never counts on one)
		if (lift_due and not bool(info["lift"])) or (rest_due and not bool(info["rest"])):
			continue
		if (hazard_near and bool(info.get("hazard", false))) or (kitten_near and bool(info.get("kitten", false))):
			continue
		if EndlessPieces.need_in(id, d) <= room:
			pool.append(id)
	return pool


func _placed_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for p in placed:
		out.append(p.id)
	return out


## How many of the last pieces in `ids` in a row have no lift.
static func _trailing_without_lift(ids: Array[StringName]) -> int:
	var n := 0
	for i in range(ids.size() - 1, -1, -1):
		if bool(EndlessPieces.info(ids[i])["lift"]):
			break
		n += 1
	return n


## How many places since the last rest piece in `ids` (0 if the last one was a rest piece).
static func _since_rest(ids: Array[StringName]) -> int:
	var n := 0
	for i in range(ids.size() - 1, -1, -1):
		if bool(EndlessPieces.info(ids[i])["rest"]):
			break
		n += 1
	return n
