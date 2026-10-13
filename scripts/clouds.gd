# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Clouds
extends MultiMeshInstance3D
## The cumulus over each outdoor thermal, all in one draw call: a few opaque puffs whose flat
## base sits just above the top of the rising air. Each cloud follows its thermal as the air
## drifts (Thermal.drift_offset), and once the plane has climbed to the top of that air the
## cloud shrinks, frays and fades toward the sky over a few seconds: "you've had this one, go
## for the next". The lift itself is unchanged. Looks only: nothing collides. (Not a tool
## script: in the editor the clouds sit where they start.)

const COLOR := Color("fdfbf8")
## A thinned cloud's colour, nearer the sky.
const THIN_COLOR := Color("eef2f6")
const PUFFS := 4
## Puffs are squashed spheres: wide, flat and a little long.
const STRETCH := Vector3(1.4, 0.55, 1.0)

## One entry per puff: {"zone": index into `zones`, "at": its centre before any drift, "size": its radius}.
var puffs: Array[Dictionary] = []
## The thermal under each cloud, in the order of the thermals passed to setup().
var zones: Array[Thermal] = []
## For each cloud, seconds since the plane climbed to the top of its air, or -1 if it hasn't yet.
var thinning: Array[float] = []
## Set by the game; without it the clouds never thin.
var tuning: Tuning
var _centres: Array[Vector3] = []  ## Each cloud's middle, before any drift.
var _offsets: Array[Vector3] = []  ## Each zone's drift as last drawn.


## `thermals` are Course's thermal dictionaries and `p_zones` their Thermal nodes, in the same
## order. A cloud's base sits `above_top` over the top of its thermal.
func setup(thermals: Array, p_zones: Array[Thermal], above_top: float) -> void:
	zones = p_zones
	puffs.clear()
	_centres.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in thermals.size():
		var t: Dictionary = thermals[k]
		var at: Vector2 = t["at"]
		var r := float(t["radius"])
		var base_y := float(t["top"]) + above_top
		var middle := Vector3.ZERO
		for i in PUFFS:
			var size := r * rng.randf_range(0.6, 0.8)
			var off := Vector3(rng.randf_range(-0.5, 0.5) * r, 0.0, rng.randf_range(-0.5, 0.5) * r)
			var puff := Vector3(at.x, base_y + size * 0.55, at.y) + off
			puffs.append({"zone": k, "at": puff, "size": size})
			middle += puff / PUFFS
		_centres.append(middle)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = build_puff_mesh()
	mm.instance_count = puffs.size()
	multimesh = mm
	material_override = Art.material()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	thinning.clear()
	thinning.resize(thermals.size())
	thinning.fill(-1.0)
	_offsets.clear()
	_offsets.resize(zones.size())
	_place()


## Called each physics tick with the plane's position and whether it is climbing in lift (the
## beeps): a cloud starts to thin once the plane climbs inside its thermal (plan view) to within
## `cloud_thin_below_top` of the top. Gliding high over a thermal doesn't count.
func note_plane(at: Vector3, climbing: bool) -> void:
	if tuning == null or not climbing:
		return
	for k in mini(zones.size(), thinning.size()):
		var zone := zones[k]
		if thinning[k] >= 0.0 or not is_instance_valid(zone):
			continue
		var plan := Vector2(at.x - zone.global_position.x, at.z - zone.global_position.z)
		if plan.length() < zone.radius and at.y >= zone.top() - tuning.cloud_thin_below_top:
			thinning[k] = 0.0


func _process(delta: float) -> void:
	var changed := false
	for k in thinning.size():
		if tuning != null and thinning[k] >= 0.0 and thinning[k] < tuning.cloud_thin_seconds:
			thinning[k] += delta
			changed = true
	for k in zones.size():
		if is_instance_valid(zones[k]) and zones[k].drift_offset != _offsets[k]:
			changed = true
	if changed:
		_place()


## 0 for a full cloud, rising to 1 once it has thinned.
func thinned(k: int) -> float:
	if tuning == null or thinning[k] < 0.0:
		return 0.0
	return smoothstep(0.0, 1.0, thinning[k] / maxf(tuning.cloud_thin_seconds, 0.01))


## Where puff `i` is now, and how big.
func puff_transform(i: int) -> Transform3D:
	var p := puffs[i]
	var k: int = p["zone"]
	var zone: Thermal = zones[k] if k < zones.size() else null  # no zones given: no drift
	var drift := zone.drift_offset if is_instance_valid(zone) else Vector3.ZERO
	var amount := thinned(k)
	var at: Vector3 = p["at"]
	var out := at - _centres[k]
	out.y = 0.0  # fraying spreads the puffs sideways, not up or down
	var spread := lerpf(1.0, tuning.cloud_thin_spread, amount) if tuning != null else 1.0
	var shrink := lerpf(1.0, tuning.cloud_thin_scale, amount) if tuning != null else 1.0
	var size := float(p["size"]) * shrink
	return Transform3D(Basis.from_scale(Vector3.ONE * size), at + out * (spread - 1.0) + drift)


func puff_color(i: int) -> Color:
	return COLOR.lerp(THIN_COLOR, thinned(puffs[i]["zone"]))


func _place() -> void:
	for k in zones.size():
		_offsets[k] = zones[k].drift_offset if is_instance_valid(zones[k]) else Vector3.ZERO
	for i in puffs.size():
		multimesh.set_instance_transform(i, puff_transform(i))
		multimesh.set_instance_color(i, puff_color(i))


## A squashed sphere of radius 1 (scaled per puff), white so each puff's instance colour shows.
static func build_puff_mesh() -> ArrayMesh:
	var b := Art.Builder.new()
	b.sphere(Vector3.ZERO, 1.0, Color.WHITE, STRETCH, 10, 5)
	return b.commit()
