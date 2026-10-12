class_name Clouds
extends MultiMeshInstance3D
## The cumulus over each outdoor thermal, all in one draw call: a few opaque puffs whose flat
## base sits just above the top of the rising air. Each cloud follows its thermal as the air
## drifts (Thermal.drift_offset). Looks only: nothing collides. (Not a tool script: in the
## editor the clouds sit where they start.)

const COLOR := Color("fdfbf8")
const PUFFS := 4
## Puffs are squashed spheres: wide, flat and a little long.
const STRETCH := Vector3(1.4, 0.55, 1.0)

## One entry per puff: {"zone": index into `zones`, "at": its centre before any drift, "size": its radius}.
var puffs: Array[Dictionary] = []
## The thermal under each cloud, in the order of the thermals passed to setup().
var zones: Array[Thermal] = []
var _offsets: Array[Vector3] = []  ## Each zone's drift as last drawn.


## `thermals` are Course's thermal dictionaries and `p_zones` their Thermal nodes, in the same
## order. A cloud's base sits `above_top` over the top of its thermal.
func setup(thermals: Array, p_zones: Array[Thermal], above_top: float) -> void:
	zones = p_zones
	puffs.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in thermals.size():
		var t: Dictionary = thermals[k]
		var at: Vector2 = t["at"]
		var r := float(t["radius"])
		var base_y := float(t["top"]) + above_top
		for i in PUFFS:
			var size := r * rng.randf_range(0.6, 0.8)
			var off := Vector3(rng.randf_range(-0.5, 0.5) * r, 0.0, rng.randf_range(-0.5, 0.5) * r)
			puffs.append({"zone": k, "at": Vector3(at.x, base_y + size * 0.55, at.y) + off, "size": size})
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = build_puff_mesh()
	mm.instance_count = puffs.size()
	multimesh = mm
	material_override = Art.material()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_offsets.clear()
	_offsets.resize(zones.size())
	_place()


func _process(_delta: float) -> void:
	for k in zones.size():
		if is_instance_valid(zones[k]) and zones[k].drift_offset != _offsets[k]:
			_place()
			return


## Where puff `i` is now.
func puff_transform(i: int) -> Transform3D:
	var p := puffs[i]
	var k: int = p["zone"]
	var zone: Thermal = zones[k] if k < zones.size() else null  # no zones given: no drift
	var drift := zone.drift_offset if is_instance_valid(zone) else Vector3.ZERO
	return Transform3D(Basis.from_scale(Vector3.ONE * float(p["size"])), p["at"] + drift)


func _place() -> void:
	for k in zones.size():
		_offsets[k] = zones[k].drift_offset if is_instance_valid(zones[k]) else Vector3.ZERO
	for i in puffs.size():
		multimesh.set_instance_transform(i, puff_transform(i))


## A squashed sphere of radius 1 (scaled per puff), in the cloud colour.
static func build_puff_mesh() -> ArrayMesh:
	var b := Art.Builder.new()
	b.sphere(Vector3.ZERO, 1.0, COLOR, STRETCH, 10, 5)
	return b.commit()
