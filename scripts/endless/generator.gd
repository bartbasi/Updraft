# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessGenerator
extends RefCounted
## Chooses the order of Endless's pieces (docs/endless-plan.md §2.5). It keeps `h`, the height a
## pilot who flew every ideal line so far is guaranteed when the last piece ends, and only places a
## piece whose need (the lowest entry height that flies it with room to spare) is at least
## `margin` below h, so lift is always in reach. It also never repeats a piece too soon, never runs
## too many pieces without lift in a row, and brings a rest piece round often enough. Pure logic:
## no nodes, so it can be run thousands of times in tests.

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
var _next_tile := 0
var _seen := {}  ## Piece ids placed so far this run.


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
	var metres := _next_tile * TILE_METRES
	var d := difficulty(metres)
	var id: StringName
	if not forced.is_empty():
		id = forced[mini(placed.size(), forced.size() - 1)]
		if forced_d >= 0.0:
			d = forced_d
	elif placed.size() < OPENING.size():
		id = OPENING[placed.size()]
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


func _choose(metres: float, d: float) -> StringName:
	var pool: Array[StringName] = []
	for id: StringName in EndlessPieces.ids():
		var info := EndlessPieces.info(id)
		if bool(info.get("fixed", false)) or float(info["min_m"]) > metres:
			continue
		pool.append(id)
	# Not one of the last few.
	var recent := _recent(no_repeat(d))
	pool = pool.filter(func(id: StringName) -> bool: return not recent.has(id))
	# Lift after too many pieces without it.
	if _trailing_without_lift() >= max_without_lift(d):
		pool = pool.filter(func(id: StringName) -> bool: return bool(EndlessPieces.info(id)["lift"]))
	# A rest piece if none has come for a while.
	if _since_rest() >= rest_every(d) - 1:
		pool = pool.filter(func(id: StringName) -> bool: return bool(EndlessPieces.info(id)["rest"]))
	# Only what can be flown from the height a good pilot is sure to have.
	var room := h - margin(d)
	pool = pool.filter(func(id: StringName) -> bool: return EndlessPieces.need_in(id, d) <= room)
	if pool.is_empty():
		return RESCUE
	# And not a piece after which nothing could fairly follow (the rescue would have to repeat).
	var onward := pool.filter(func(id: StringName) -> bool: return _something_follows(id, d, metres))
	if not onward.is_empty():
		pool.assign(onward)
	var weights := PackedFloat32Array()
	for id in pool:
		var w := 1.0 if int(EndlessPieces.info(id)["tiles"]) == 1 else 0.6
		if not _seen.has(id):
			w *= 1.5
		weights.append(w)
	return pool[rng.rand_weighted(weights)]


## Whether some piece could fairly come after `id` (placed now, `metres` along): one not among
## the last few with it, with lift if it lacks it and the run without lift is at its limit, a rest
## piece if one is due, and needing no more than the height a good pilot leaves `id` with.
func _something_follows(id: StringName, d: float, metres: float) -> bool:
	var after := EndlessPieces.out(id, d, h)
	d = difficulty(metres + EndlessPieces.tiles(id) * TILE_METRES)  # the rules the next piece is placed by
	var recent := _recent(no_repeat(d) - 1)
	recent.append(id)
	var lift_due := not bool(EndlessPieces.info(id)["lift"]) and _trailing_without_lift() + 1 >= max_without_lift(d)
	var rest_due := not bool(EndlessPieces.info(id)["rest"]) and _since_rest() + 1 >= rest_every(d) - 1
	for next_id: StringName in EndlessPieces.ids():
		var info := EndlessPieces.info(next_id)
		if bool(info.get("fixed", false)) or recent.has(next_id):
			continue
		if (lift_due and not bool(info["lift"])) or (rest_due and not bool(info["rest"])):
			continue
		if EndlessPieces.need_in(next_id, d) <= after - margin(d):
			return true
	return false


func _recent(count: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for i in range(maxi(placed.size() - count, 0), placed.size()):
		out.append(placed[i].id)
	return out


## How many of the last placed pieces in a row have no lift.
func _trailing_without_lift() -> int:
	var n := 0
	for i in range(placed.size() - 1, -1, -1):
		if bool(EndlessPieces.info(placed[i].id)["lift"]):
			break
		n += 1
	return n


## How many places since the last rest piece (0 if the last one was a rest piece).
func _since_rest() -> int:
	var n := 0
	for i in range(placed.size() - 1, -1, -1):
		if bool(EndlessPieces.info(placed[i].id)["rest"]):
			break
		n += 1
	return n
