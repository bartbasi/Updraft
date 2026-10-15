# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Kitten
extends Node3D
## A kitten in its window (docs/hazards-plan.md §1): Pip, Smudge or Bramble, sitting on the sill
## behind open pink shutters with a ball of yarn. Very much a kitten: a big round head (45% of
## its height), big low eyes with glints, stubby legs, a fluffy tail. It never leaves its window.
## Asleep far off; it wakes as you come (80 u), watches you (45 u), wiggles its bottom (from 18 u),
## then lunges with its back paws still on the sill. Its paws reach REACH from its chest (C) and
## catch within CATCH of them, so nothing further than REACH + CATCH from C can ever be caught,
## at any difficulty; and it never lunges before WIGGLE_MIN of wiggle, nor at what it hasn't
## watched or is behind its wall. A lunge that misses: it flops on its back, then licks a paw.
## One that catches: it hugs the balloon (or holds the plane) and purrs. Its logic steps in the
## physics tick with the flyer (the same flight, the same outcome); drawing in _process. The node
## sits at the sill's middle, facing +z (out of the window).

## What happened in a step (step()'s result).
const NOTHING := ""
const WATCHING := "watching"
const READY := "ready"
const MISSED := "missed"
const CAUGHT := "caught"
const BATTED := "batted"

const WAKE := 80.0
const NOTICE := 45.0
const GET_READY := 18.0
const TRIGGER := 9.0
const WIGGLE_MIN := 0.6
const REACH := 3.0
const CATCH := 1.0
const LUNGE_OUT := 0.15
const LUNGE_HOLD := 0.15
const LUNGE_BACK := 0.3
const REARM := 3.0
const CLOSE_IN := 4.6  ## Lunges at once this close, closing or not.
const CHEST := Vector3(0.0, 1.2, 0.5)  ## C: the pounce centre, from the sill's middle.
const DRAW_RANGE := 150.0

const NAMES := {"pip": "Pip", "smudge": "Smudge", "bramble": "Bramble"}
const COATS: Array[String] = ["pip", "smudge", "bramble"]

enum State { ASLEEP, WAKING, IDLE, WATCHING_YOU, WIGGLE, LUNGE, MISS, HUG }

var coat := "pip"
var state := State.ASLEEP
var rng := RandomNumberGenerator.new()
## The lunge's paw point (kitten-local, so a recentre moves it with its window), and how close the
## flyer came to it.
var paw := CHEST
var closest := INF
## The flyer's closest to C since the kitten began watching it (for logs).
var nearest := INF
var _target := CHEST
var _time := 0.0  ## Seconds in the current state.
var _wiggle := 0.0
var _last_dist := INF
var _clock := 0.0
var _next_blink := 3.0
var _next_twitch := 4.0
var _blink := 0.0
var _twitch := 0.0
var _look := Vector2.ZERO  ## The head's yaw and pitch toward the flyer.
var _flyer_local := Vector3.ZERO
var _yarn: MeshInstance3D
var _rump: Node3D
var _chest: Node3D
var _head: Node3D
var _eyes: Node3D
var _ears: Array[Node3D] = []
var _tail: Node3D
var _tail_tip: Node3D
var _mouth: MeshInstance3D
var _hearts: Array[Node3D] = []
static var _meshes := {}  ## Coat -> its parts' meshes (_build_meshes()).


## A kitten of `coat` ("pip", "smudge" or "bramble"), its idle habits from `p_seed`; awake
## already or asleep, by the same seed.
func _init(p_coat := "pip", p_seed := 1) -> void:
	coat = p_coat if NAMES.has(p_coat) else "pip"
	rng.seed = p_seed
	state = State.ASLEEP if rng.randf() < 0.7 else State.IDLE
	_next_blink = rng.randf_range(2.5, 5.0)
	_next_twitch = rng.randf_range(3.0, 6.0)
	_build()


func kitten_name() -> String:
	return NAMES[coat]


## C, the pounce centre, in world space.
func centre() -> Vector3:
	return global_transform * CHEST


## The head in world space (where the camera looks at a hug).
func head() -> Node3D:
	return _head


## The paw point in world space (where a lunge reaches).
func paw_point() -> Vector3:
	return global_transform * paw


# --- Logic (each physics tick) -----------------------------------------------------

## One physics tick with the flyer at `at` moving at `velocity` (world space); `string` the
## balloon's string points (empty for the plane). Returns what happened (WATCHING the first
## moment it watches you, READY as it starts to wiggle, MISSED or BATTED as a lunge ends without
## a catch, CAUGHT), or NOTHING.
func step(delta: float, at: Vector3, velocity: Vector3, string := PackedVector3Array()) -> String:
	_time += delta
	var local := global_transform.affine_inverse() * at
	_flyer_local = local
	var to := local - CHEST
	var dist := to.length()
	var front := to.normalized().dot(Vector3.BACK) > -0.2  # (+z is out of the window)
	var closing := dist < _last_dist
	_last_dist = dist
	nearest = minf(nearest, dist)
	match state:
		State.ASLEEP:
			if front and dist < WAKE:
				_enter(State.WAKING)
		State.WAKING:
			if _time >= 1.2:
				_enter(State.IDLE)
		State.IDLE:
			if front and dist < NOTICE:
				_enter(State.WATCHING_YOU)
				nearest = dist
				return WATCHING
		State.WATCHING_YOU:
			if not front or dist > NOTICE + 5.0:
				_enter(State.IDLE)
			elif (dist < GET_READY and closing) or dist < TRIGGER:
				_enter(State.WIGGLE)
				_wiggle = 0.0
				return READY
		State.WIGGLE:
			_wiggle += delta
			if not front or dist > NOTICE:
				_enter(State.WATCHING_YOU)
			else:
				# The paws take LUNGE_OUT to reach out: so it springs that long before you pass.
				var lv := global_transform.basis.inverse() * velocity
				var to_closest := -to.dot(lv) / maxf(lv.length_squared(), 0.0001)
				if _wiggle >= WIGGLE_MIN and dist < TRIGGER and to.z > 0.0 and (to_closest <= LUNGE_OUT or dist < CLOSE_IN):
					_lunge(_nearest(local, string), lv)
		State.LUNGE:
			paw = CHEST.lerp(_target, minf(_time / LUNGE_OUT, 1.0))
			if _time <= LUNGE_OUT + LUNGE_HOLD:
				var gap := (local - paw).length()
				closest = minf(closest, gap)
				if gap <= CATCH:
					_enter(State.HUG)
					return CAUGHT
				for p in string:
					if (global_transform.affine_inverse() * p - paw).length() <= CATCH:
						_enter(State.MISS)
						return BATTED
			if _time >= LUNGE_OUT + LUNGE_HOLD + LUNGE_BACK:
				_enter(State.MISS)
				return MISSED
		State.MISS:
			paw = CHEST
			if _time >= REARM:
				_enter(State.WATCHING_YOU if front and dist < NOTICE else State.IDLE)
	return NOTHING


## What it swipes at: the flyer, or the balloon's string where that dangles nearer.
func _nearest(local: Vector3, string: PackedVector3Array) -> Vector3:
	var best := local
	var inverse := global_transform.affine_inverse()
	for p in string:
		var q := inverse * p
		if (q - CHEST).length() < (best - CHEST).length():
			best = q
	return best


## Where the paws go: the flyer (or its string) a moment ahead, no further than REACH from C, in front of the
## wall, no lower than just under the sill.
func _lunge(local: Vector3, local_velocity: Vector3) -> void:
	# The moment in its swipe (from the paws' arrival to the hold's end) the flyer comes nearest
	# to where they can reach, and the paws go there.
	var best := INF
	var target := CHEST
	for i in 7:
		var ahead := local + local_velocity * lerpf(LUNGE_OUT * 0.7, LUNGE_OUT + LUNGE_HOLD, i / 6.0)
		var to := _reachable(ahead)
		var gap := to.distance_to(ahead)
		if gap < best - 0.001:
			best = gap
			target = to
	_target = target
	closest = INF
	_enter(State.LUNGE)


## The nearest point to `p` its paws can reach: within REACH of C, in front of the wall, no lower
## than just under the sill.
func _reachable(p: Vector3) -> Vector3:
	var off := p - CHEST
	if off.length() > REACH:
		off = off.normalized() * REACH
	off.z = maxf(off.z, 0.1)
	var target := CHEST + off
	target.y = maxf(target.y, -0.5)
	if (target - CHEST).length() > REACH:
		target = CHEST + (target - CHEST).normalized() * REACH
	return target


func _enter(s: State) -> void:
	state = s
	_time = 0.0
	if s != State.LUNGE:
		paw = CHEST


## Hugs what it caught: the flyer is drawn to its chest (the game moves it); purring, eyes happy.
func hug_point() -> Vector3:
	return global_transform * Vector3(0.0, 1.0, 0.75)


# --- Drawing ---------------------------------------------------------------------

func _process(delta: float) -> void:
	_clock += delta
	var t := _clock
	var breathe := 1.0 + 0.03 * sin(t * TAU * 0.4)
	# Defaults: sitting up.
	_rump.position = Vector3(0.0, 0.0, 0.0)
	_rump.rotation = Vector3.ZERO
	_chest.position = Vector3(0.0, 0.0, 0.0)
	_chest.rotation = Vector3.ZERO
	_chest.scale = Vector3.ONE
	_head.position = Vector3(0.0, 1.55, 0.18)
	_head.rotation = Vector3.ZERO
	_eyes.scale = Vector3.ONE
	_mouth.visible = false
	_tail.rotation = Vector3(0.6, 0.0, 0.0)
	_tail_tip.rotation = Vector3(0.0, 0.0, 0.0)
	for e in _ears:
		e.rotation = Vector3(0.0, 0.0, 0.0)
	var squint := false
	# Blinks and ear twitches whenever awake.
	_blink = maxf(_blink - delta, 0.0)
	_twitch = maxf(_twitch - delta, 0.0)
	_next_blink -= delta
	_next_twitch -= delta
	if _next_blink <= 0.0:
		_blink = 0.15
		_next_blink = rng.randf_range(2.5, 5.0)
	if _next_twitch <= 0.0:
		_twitch = 0.2
		_next_twitch = rng.randf_range(3.0, 6.0)
	match state:
		State.ASLEEP:  # a curled loaf, breathing; eyes shut, tail round
			_rump.scale = Vector3(1.0, 0.8 * breathe, 1.05)
			_chest.position = Vector3(0.0, 0.05, 0.05)  # (paws tucked: nothing hangs under the sill)
			_chest.scale = Vector3(1.0, 0.6, 1.0)
			_head.position = Vector3(0.0, 0.9, 0.35)
			_head.rotation = Vector3(0.35, 0.3, 0.15)
			squint = true
			_tail.rotation = Vector3(1.75, 1.3, 0.0)  # along the sill, round the paws
		State.WAKING:  # a big pink yawn and a stretch
			var u := clampf(_time / 1.2, 0.0, 1.0)
			_rump.scale = Vector3.ONE
			_head.rotation = Vector3(-0.3 * sin(u * PI), 0.0, 0.0)
			_mouth.visible = u < 0.7
			_mouth.scale = Vector3.ONE * sin(clampf(u / 0.7, 0.0, 1.0) * PI)
			_chest.position = Vector3(0.0, -0.2 * sin(u * PI), 0.25 * sin(u * PI))
			squint = u < 0.5
		State.IDLE, State.MISS, State.WATCHING_YOU, State.WIGGLE, State.LUNGE:
			_rump.scale = Vector3(1.0, breathe, 1.0)
			_tail_tip.rotation = Vector3(0.0, 0.0, deg_to_rad(25.0) * sin(t * TAU * 0.4))
	if state in [State.WATCHING_YOU, State.WIGGLE, State.LUNGE]:
		var to := _flyer_local - _head.position
		var want := Vector2(clampf(atan2(to.x, to.z), deg_to_rad(-75.0), deg_to_rad(75.0)), clampf(-atan2(to.y, Vector2(to.x, to.z).length()), deg_to_rad(-45.0), deg_to_rad(45.0)))
		_look = _look.lerp(want, 1.0 - exp(-delta / 0.15))
		_head.rotation = Vector3(_look.y, _look.x, 0.0)
		_eyes.scale = Vector3.ONE * 1.2
		_tail.rotation = Vector3(-0.2, 0.0, 0.0)  # up, a question-mark hook
		_tail_tip.rotation = Vector3(0.9, 0.0, 0.0)
	else:
		_look = _look.lerp(Vector2.ZERO, 1.0 - exp(-delta / 0.3))
	if state == State.WIGGLE:  # chest low, rump up, the wiggle
		var ramp := clampf(_wiggle / 0.2, 0.0, 1.0)
		_chest.rotation = Vector3(deg_to_rad(25.0), 0.0, 0.0)
		_chest.position = Vector3(0.0, 0.15, 0.1)  # (tipped forward, its paws still on the sill)
		_head.position.y -= 0.3
		var swing := sin(t * TAU * 4.0) * ramp  # (big and slow enough to see at 18 u)
		_rump.rotation = Vector3(-0.25, deg_to_rad(15.0) * swing, 0.0)
		_rump.position = Vector3(0.1 * swing, 0.04 * absf(swing), 0.0)
		_tail.rotation = Vector3(1.2, 0.0, 0.0)
		_tail_tip.rotation = Vector3(0.0, 0.0, 0.6 * sin(t * TAU * 3.0))
	elif state == State.LUNGE:  # stretched out at the paw point, ears back, mouth open
		var reach := paw - CHEST
		var out := clampf(_time / LUNGE_OUT, 0.0, 1.0) if _time <= LUNGE_OUT + LUNGE_HOLD else clampf(1.0 - (_time - LUNGE_OUT - LUNGE_HOLD) / LUNGE_BACK, 0.0, 1.0)
		_chest.position = reach * 0.75 * out + Vector3(0.0, -0.2, 0.0) * out
		_chest.scale = Vector3(1.0, 1.0, 1.0 + 0.8 * out)
		_head.position += reach * 0.85 * out
		_mouth.visible = true
		_mouth.scale = Vector3.ONE * 0.6
		for e in _ears:
			e.rotation = Vector3(-0.35, 0.0, 0.0)
		_tail.rotation = Vector3(1.5, 0.0, 0.0)
	elif state == State.MISS:  # a flop on its back, paws batting; then a dignified paw lick
		if _time < 0.55:
			var f := sin(clampf(_time / 0.55, 0.0, 1.0) * PI)
			_rump.rotation = Vector3(-0.35 * f, 0.0, 0.0)  # (no further: its tail stays above the sill)
			_chest.rotation = Vector3(-1.4 * f, 0.0, 0.0)
			_chest.position = Vector3(0.0, 0.1 * f, -0.4 * f)  # (its paws stay above the sill)
			_head.position = Vector3(0.0, 1.55 - 0.8 * f, 0.18 - 0.6 * f)
			_head.rotation = Vector3(-1.0 * f, 0.0, 0.3 * sin(_time * 30.0))
		elif _time < 2.05:
			_head.rotation = Vector3(0.45, 0.25, 0.0)  # nose down to a raised paw
			_chest.rotation = Vector3(-0.15 + 0.08 * sin(_time * 14.0), 0.0, 0.0)
			squint = true
	elif state == State.HUG:  # holding the flyer to its chest, head rubbing, eyes happy
		_head.rotation = Vector3(0.1, 0.0, deg_to_rad(10.0) * sin(t * TAU * 1.5))
		_chest.position = Vector3(0.0, 0.0, 0.2)
		squint = true
		_mouth.visible = true  # a small open smile with the happy eyes
		_mouth.scale = Vector3.ONE * 0.45
		_tail.rotation = Vector3(0.2, 0.4 * sin(t * TAU * 0.8), 0.0)
	if _twitch > 0.0 and state != State.ASLEEP and _ears.size() == 2:
		_ears[0].rotation.z += deg_to_rad(20.0)
	if squint:
		_eyes.scale = Vector3(1.0, 0.15, 1.0)  # shut, or happy arcs
	elif _blink > 0.0:
		_eyes.scale = Vector3(1.0, 0.1, 1.0)
	_yarn.rotation.x = 0.2 * sin(t * 0.7)


## Three little pink hearts rising from the hug.
func hearts() -> void:
	for i in 3:
		var h := Node3D.new()
		var mi := MeshInstance3D.new()
		var b := Art.Builder.new()
		var pink := Color("f4b0bc")
		b.sphere(Vector3(-0.1, 0.0, 0.0), 0.13, pink, Vector3.ONE, 8, 4)
		b.sphere(Vector3(0.1, 0.0, 0.0), 0.13, pink, Vector3.ONE, 8, 4)
		b.cylinder(Vector3(0.0, -0.3, 0.0), 0.0, 0.2, 0.25, pink, 8, Basis(Vector3.RIGHT, PI))
		mi.mesh = b.commit()
		mi.material_override = Art.material()
		h.add_child(mi)
		h.position = Vector3(-0.5 + 0.5 * i, 2.2, 0.6)
		add_child(h)
		_hearts.append(h)
		var tw := h.create_tween().set_parallel()
		tw.tween_property(h, "position:y", 3.7, 1.2).set_delay(0.15 * i)
		tw.tween_property(h, "scale", Vector3.ONE * 0.05, 1.2).set_delay(0.15 * i).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(h.queue_free)


# --- Building ----------------------------------------------------------------------

## The coat's colours: base, stripes or patches, and the white bits.
static func _colors_of(p_coat: String) -> Dictionary:
	match p_coat:
		"smudge":
			return {"base": Color("b8bccb"), "dark": Color("9a9eb0"), "white": Color("fbeedd"), "ear_l": Color("b8bccb"), "ear_r": Color("b8bccb")}
		"bramble":
			return {"base": Color("fbf4ea"), "dark": Color("f2a65a"), "patch": Color("7d7590"), "white": Color("fbf4ea"), "ear_l": Color("f2a65a"), "ear_r": Color("7d7590")}
	return {"base": Color("f2a65a"), "dark": Color("e08a3c"), "white": Color("fbeedd"), "ear_l": Color("f2a65a"), "ear_r": Color("f2a65a")}


func _part(parent: Node3D, mesh: ArrayMesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Art.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = DRAW_RANGE
	parent.add_child(mi)
	return mi


func _node(parent: Node3D, at: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = at
	parent.add_child(n)
	return n


func _build() -> void:
	if not _meshes.has(coat):
		_meshes[coat] = _build_meshes(coat)
	var m: Dictionary = _meshes[coat]
	_part(self, m["window"]).visibility_range_end = 400.0  # (as far as its home: no blank wall, then a window)
	_yarn = _part(_node(self, Vector3(0.95, 0.15, 0.45)), m["yarn"])
	_rump = _node(self, Vector3.ZERO)
	_part(_rump, m["rump"])
	_tail = _node(_rump, Vector3(0.0, 0.3, -0.75))
	_part(_tail, m["tail"])
	_tail_tip = _node(_tail, Vector3(0.0, 0.7, -0.2))
	_part(_tail_tip, m["tip"])
	_chest = _node(self, Vector3.ZERO)
	_part(_chest, m["chest"])
	_head = _node(self, Vector3(0.0, 1.55, 0.18))
	_part(_head, m["head"])
	for side in [-1.0, 1.0]:
		var ear := _node(_head, Vector3(side * 0.38, 0.4, -0.02))
		ear.rotation = Vector3(0.0, 0.0, -side * deg_to_rad(15.0))
		_part(ear, m["ear_l"] if side < 0.0 else m["ear_r"])
		_ears.append(ear)
	_eyes = _node(_head, Vector3(0.0, -0.08, 0.42))
	_part(_eyes, m["eyes"])
	_mouth = _part(_node(_head, Vector3(0.0, -0.3, 0.5)), m["mouth"])


## Every part's mesh for a coat, built once and shared by every kitten in it (so a kitten's spawn
## only makes nodes: building these takes a phone a frame or two).
static func _build_meshes(p_coat: String) -> Dictionary:
	var c := _colors_of(p_coat)
	var base: Color = c["base"]
	var dark: Color = c["dark"]
	var white: Color = c["white"]
	var pink := Color("f4b0bc")
	var ink := Color("3b3350")
	var out := {}
	# The window: a dark room behind, open pink shutters, a deep sill, the yarn.
	var win := Art.Builder.new()
	win.box(Vector3(0.0, 1.4, -0.75), Vector3(2.6, 3.0, 0.1), Color("4e4256"))
	win.box(Vector3(0.0, -0.1, 0.0), Vector3(2.9, 0.2, 1.5), Color("fbf6ee"))
	for side in [-1.0, 1.0]:
		win.box(Vector3(side * 1.75, 1.4, 0.25), Vector3(0.9, 2.9, 0.08), Color("e7a6c0"), Basis(Vector3.UP, side * 0.5))
	out["window"] = win.commit()
	var yarn := Art.Builder.new()
	yarn.sphere(Vector3.ZERO, 0.24, Color("b9a6dc"), Vector3.ONE, 9, 6)
	yarn.box(Vector3(0.05, -0.25, 0.25), Vector3(0.03, 0.5, 0.03), Color("b9a6dc"))  # a loose strand over the edge
	out["yarn"] = yarn.commit()
	# The rump: body, haunches and hind feet.
	var rump := Art.Builder.new()
	rump.sphere(Vector3(0.0, 0.55, -0.15), 0.55, base, Vector3(0.95, 1.05, 1.18), 12, 8)
	for side in [-1.0, 1.0]:
		rump.sphere(Vector3(side * 0.36, 0.32, -0.3), 0.32, base, Vector3(0.9, 1.0, 1.15), 10, 6)
		rump.sphere(Vector3(side * 0.3, 0.06, 0.08), 0.15, white, Vector3(1.0, 0.7, 1.4), 8, 4)
	if p_coat == "pip":
		for i in 3:  # tabby stripes over the back
			rump.sphere(Vector3(0.0, 0.92 - i * 0.03, -0.1 - i * 0.22), 0.2, dark, Vector3(2.4, 0.35, 0.5), 8, 4)
	elif p_coat == "bramble":
		rump.sphere(Vector3(-0.3, 0.7, -0.35), 0.3, c["patch"], Vector3(1.0, 0.8, 1.2), 8, 5)
		rump.sphere(Vector3(0.28, 0.5, -0.1), 0.26, dark, Vector3(1.0, 0.9, 1.1), 8, 5)
	out["rump"] = rump.commit()
	# The tail: thick, curling, a fluffy tip.
	var tail := Art.Builder.new()
	for i in 4:
		tail.sphere(Vector3(0.0, i * 0.18, -i * 0.05), 0.16 - i * 0.01, base if (i % 2 == 0 or p_coat != "pip") else dark, Vector3.ONE, 8, 5)
	out["tail"] = tail.commit()
	var tip := Art.Builder.new()
	tip.sphere(Vector3(0.0, 0.0, 0.0), 0.14, base, Vector3.ONE, 8, 5)
	tip.sphere(Vector3(0.0, 0.18, 0.02), 0.18, white if p_coat == "pip" else base, Vector3(1.0, 1.1, 1.0), 9, 6)
	out["tip"] = tip.commit()
	# The chest: front body, bib, stubby legs and round white paws.
	var chest := Art.Builder.new()
	chest.sphere(Vector3(0.0, 0.78, 0.22), 0.42, base, Vector3(1.0, 1.12, 0.95), 12, 8)
	chest.sphere(Vector3(0.0, 0.8, 0.5), 0.26, white, Vector3(1.0, 1.3, 0.55), 10, 6)  # the bib
	for side in [-1.0, 1.0]:
		chest.cylinder(Vector3(side * 0.2, 0.12, 0.42), 0.14, 0.14, 0.55, base, 8)
		chest.sphere(Vector3(side * 0.2, 0.1, 0.5), 0.17, white, Vector3(1.0, 0.75, 1.2), 9, 5)
	out["chest"] = chest.commit()
	# The head: big and round, with its own ears and eyes.
	var head := Art.Builder.new()
	head.sphere(Vector3.ZERO, 0.55, base, Vector3(1.18, 1.0, 0.95), 14, 10)
	head.sphere(Vector3(0.0, -0.2, 0.42), 0.21, white, Vector3(1.15, 0.65, 0.8), 10, 6)  # the muzzle
	head.sphere(Vector3(0.0, -0.11, 0.56), 0.065, pink, Vector3(1.4, 0.8, 0.8), 7, 4)  # the nose
	for side in [-1.0, 1.0]:
		head.box(Vector3(side * 0.06, -0.26, 0.565), Vector3(0.1, 0.022, 0.02), ink, Basis(Vector3.BACK, side * 0.5))  # the "w" mouth, smiling
		head.sphere(Vector3(side * 0.38, -0.14, 0.4), 0.11, Color("f6c3c9"), Vector3(1.2, 0.6, 0.4), 8, 4)  # blush
		for w in 3:  # whiskers
			head.box(Vector3(side * 0.42, -0.18 + w * 0.05, 0.48), Vector3(0.5, 0.012, 0.012), Color("fbf6ee"), Basis(Vector3.BACK, side * (w - 1) * 0.15))
	if p_coat == "pip":
		for i in 3:  # stripes on the brow
			head.sphere(Vector3((i - 1) * 0.16, 0.38, 0.3), 0.06, dark, Vector3(0.6, 1.6, 0.6), 6, 4)
	elif p_coat == "smudge":
		head.sphere(Vector3(0.0, -0.05, 0.5), 0.12, dark, Vector3(1.0, 1.4, 0.5), 8, 4)  # the nose smudge
	for i in 2:  # a little head tuft
		head.cylinder(Vector3((i - 0.5) * 0.08, 0.5, 0.05), 0.04, 0.0, 0.14, base, 5, Basis(Vector3.BACK, (i - 0.5) * 0.6))
	out["head"] = head.commit()
	for side in [-1.0, 1.0]:
		var eb := Art.Builder.new()
		eb.cylinder(Vector3.ZERO, 0.24, 0.0, 0.5, c["ear_l"] if side < 0.0 else c["ear_r"], 4)
		eb.cylinder(Vector3(0.0, 0.03, 0.09), 0.14, 0.0, 0.34, pink, 4)
		out["ear_l" if side < 0.0 else "ear_r"] = eb.commit()
	var eyes := Art.Builder.new()
	for side in [-1.0, 1.0]:
		eyes.sphere(Vector3(side * 0.28, 0.0, 0.0), 0.15, ink, Vector3(1.0, 1.2, 0.6), 10, 7)
		eyes.sphere(Vector3(side * 0.28 - 0.05, 0.07, 0.08), 0.055, Color.WHITE, Vector3.ONE, 6, 4)  # the big glint
		eyes.sphere(Vector3(side * 0.28 + 0.05, -0.06, 0.08), 0.025, Color.WHITE, Vector3.ONE, 5, 3)  # and the small one
	out["eyes"] = eyes.commit()
	var mouth := Art.Builder.new()
	mouth.sphere(Vector3.ZERO, 0.12, Color("e8889a"), Vector3(1.0, 1.3, 0.4), 8, 5)
	out["mouth"] = mouth.commit()
	return out
