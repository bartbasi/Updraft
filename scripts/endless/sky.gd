# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessSky
extends Node3D
## Endless's clouds and birds, which come and go with the pieces, in one draw call each (the
## Course's Clouds and Birds are built once for a fixed set of thermals). A cloud over a thermal
## follows its drift and, once the plane has climbed to the top of that air (or the air fades),
## shrinks, frays and pales as the Course's clouds do; clouds over a street hang still. Birds circle
## near the top of a thermal, following its drift, or hover on a ridge's breeze. Looks only.

class Cloud:
	var puffs: Array[Dictionary] = []  ## {at (world, before drift), size}
	var centre := Vector3.ZERO
	var zone: Thermal
	var thin := -1.0  ## Seconds thinning so far, or -1.
	var tile := 0

class Bird:
	var centre := Vector3.ZERO
	var radius := 0.0  ## 0 hovers.
	var phase := 0.0
	var zone: Thermal
	var tile := 0

var tuning: Tuning
var clouds: Array[Cloud] = []
var birds: Array[Bird] = []
var _cloud_mm: MultiMeshInstance3D
var _bird_mm: MultiMeshInstance3D
var _time := 0.0
const CLOUD_CAPACITY := 128
const BIRD_CAPACITY := 64


func _ready() -> void:
	_cloud_mm = _multimesh(Clouds.build_puff_mesh(), CLOUD_CAPACITY, true, false)
	_bird_mm = _multimesh(Birds.build_bird_mesh(), BIRD_CAPACITY, false, true)


func _multimesh(mesh: ArrayMesh, capacity: int, colors: bool, double_sided: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	mm.mesh = mesh
	mm.instance_count = capacity
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Art.material(double_sided)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mi


## Adds a piece's clouds and birds (as EndlessPieces.Kit.clouds and .birds) at `origin`; `zones`
## maps zone names to their Thermals.
func add_piece(tile: int, kit_clouds: Array[Dictionary], kit_birds: Array[Dictionary], origin: Vector3, zones: Dictionary) -> void:
	for c in kit_clouds:
		var cloud := Cloud.new()
		cloud.tile = tile
		cloud.zone = zones.get(c["zone"]) if c["zone"] != "" else null
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector2(origin.z, (c["at"] as Vector3).z))
		var r := float(c["radius"])
		var base: Vector3 = origin + c["at"]
		for i in int(c["puffs"]):
			var size := r * rng.randf_range(0.6, 0.85)
			var at := base + Vector3(rng.randf_range(-0.5, 0.5) * r, size * 0.55, rng.randf_range(-0.6, 0.6) * r)
			cloud.puffs.append({"at": at, "size": size})
			cloud.centre += at / float(c["puffs"])
		clouds.append(cloud)
	for b in kit_birds:
		if b.has("zone"):
			var zone: Thermal = zones.get(b["zone"])
			if zone == null:
				continue
			for i in 3:
				var bird := Bird.new()
				bird.tile = tile
				bird.zone = zone
				var at := zone.global_position - zone.drift_offset  # where it started (it is in the tree by now)
				bird.centre = Vector3(at.x, zone.top() - float(b["below_top"]) + (i - 1) * 1.5, at.z)
				bird.radius = zone.radius * Birds.CIRCLE_FRACTION
				bird.phase = TAU * i / 3.0
				birds.append(bird)
		else:
			var bird := Bird.new()
			bird.tile = tile
			bird.centre = origin + b["at"]
			bird.phase = bird.centre.z * 0.13
			birds.append(bird)


func remove_before(tile: int) -> void:
	clouds = clouds.filter(func(c: Cloud) -> bool: return c.tile >= tile)
	birds = birds.filter(func(b: Bird) -> bool: return b.tile >= tile)


## Everything has moved `by` toward +z (EndlessWorld.recentre()).
func recentre(by: float) -> void:
	for c in clouds:
		c.centre.z += by
		for p in c.puffs:
			p["at"] += Vector3(0.0, 0.0, by)
	for b in birds:
		b.centre.z += by


func clear() -> void:
	clouds.clear()
	birds.clear()


## Each physics tick: a cloud starts to thin once the plane climbs (the beeps on) inside its
## thermal to near its top, or once its air has started to fade.
func note_plane(at: Vector3, climbing: bool) -> void:
	if tuning == null:
		return
	for c in clouds:
		if c.thin >= 0.0 or not is_instance_valid(c.zone):
			continue
		var plan := Vector2(at.x - c.zone.global_position.x, at.z - c.zone.global_position.z)
		var topped := climbing and plan.length() < c.zone.radius and at.y >= c.zone.top() - tuning.cloud_thin_below_top
		if topped or c.zone.fading():
			c.thin = 0.0


func _process(delta: float) -> void:
	_time += delta
	for c in clouds:
		if c.thin >= 0.0 and tuning != null and c.thin < tuning.cloud_thin_seconds:
			c.thin += delta
	_place()


func _place() -> void:
	var n := 0
	var mm := _cloud_mm.multimesh
	for c in clouds:
		var drift := c.zone.drift_offset if is_instance_valid(c.zone) else Vector3.ZERO
		var amount := smoothstep(0.0, 1.0, c.thin / maxf(tuning.cloud_thin_seconds, 0.01)) if c.thin >= 0.0 and tuning != null else 0.0
		var spread := lerpf(1.0, tuning.cloud_thin_spread, amount) if tuning != null else 1.0
		var shrink := lerpf(1.0, tuning.cloud_thin_scale, amount) if tuning != null else 1.0
		for p in c.puffs:
			if n >= mm.instance_count:
				break
			var at: Vector3 = p["at"]
			var out := at - c.centre
			out.y = 0.0
			mm.set_instance_transform(n, Transform3D(Basis.from_scale(Vector3.ONE * float(p["size"]) * shrink), at + out * (spread - 1.0) + drift))
			mm.set_instance_color(n, Clouds.COLOR.lerp(Clouds.THIN_COLOR, amount))
			n += 1
	mm.visible_instance_count = n
	var bm := _bird_mm.multimesh
	var k := 0
	for b in birds:
		if k >= bm.instance_count:
			break
		var xf: Transform3D
		if b.radius <= 0.0:
			var bob := sin(TAU * _time / Birds.BOB_PERIOD + b.phase) * Birds.BOB
			xf = Transform3D(Basis.looking_at(Vector3.RIGHT).scaled(Vector3.ONE * Birds.HOVER_SCALE), b.centre + Vector3(0.0, bob, 0.0))
		else:
			var centre := b.centre + (b.zone.drift_offset if is_instance_valid(b.zone) else Vector3.ZERO)
			var a := b.phase + _time * Birds.CIRCLE_SPEED
			var along := Vector3(-sin(a), 0.0, cos(a))
			xf = Transform3D(Basis.looking_at(along) * Basis(Vector3.FORWARD, 0.35), centre + Vector3(cos(a), 0.0, sin(a)) * b.radius)
		bm.set_instance_transform(k, xf)
		k += 1
	bm.visible_instance_count = k
