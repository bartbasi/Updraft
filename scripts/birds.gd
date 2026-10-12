class_name Birds
extends MultiMeshInstance3D
## Birds riding the air outdoors, all in one draw call: over each thermal a few circle slowly
## near its top (the tell a glider pilot looks for), and over the ridge a few hang almost still
## on the breeze, bobbing gently. Looks only: nothing collides. (Not a tool script: in the
## editor the birds sit still where they start.)

const COLOR := Color("6f6478")
const WINGSPAN := 1.6
## Circling birds: this fraction of the thermal's radius out, this many units below its top
## (each a little higher or lower), turning at this rate (radians/second).
const CIRCLE_FRACTION := 0.5
const BELOW_TOP := 4.0
const CIRCLE_SPEED := 0.45
## Hovering birds bob up and down this far over this many seconds.
const BOB := 0.3
const BOB_PERIOD := 3.0

## One entry per bird: {"centre": Vector3, "radius": float, "phase": float} circles;
## a radius of 0 hovers in place, facing into the breeze (+X).
var flock: Array[Dictionary] = []
var _time := 0.0


## Three birds circling over each thermal and three hovering over the ridge.
func setup(thermals: Array, hover_spots: Array[Vector3]) -> void:
	flock.clear()
	for t: Dictionary in thermals:
		var at: Vector2 = t["at"]
		for i in 3:
			var y := float(t["top"]) - BELOW_TOP + (i - 1) * 1.5
			flock.append({"centre": Vector3(at.x, y, at.y), "radius": float(t["radius"]) * CIRCLE_FRACTION, "phase": TAU * i / 3.0})
	for i in hover_spots.size():
		flock.append({"centre": hover_spots[i], "radius": 0.0, "phase": i * 1.3})
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = build_bird_mesh()
	mm.instance_count = flock.size()
	multimesh = mm
	material_override = Art.material(true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_place(0.0)


func _process(delta: float) -> void:
	_time += delta
	_place(_time)


## Where each bird is at time `t`.
func bird_transform(i: int, t: float) -> Transform3D:
	var b := flock[i]
	var centre: Vector3 = b["centre"]
	var radius: float = b["radius"]
	var phase: float = b["phase"]
	if radius <= 0.0:
		var bob := sin(TAU * t / BOB_PERIOD + phase) * BOB
		return Transform3D(Basis.looking_at(Vector3.RIGHT), centre + Vector3(0.0, bob, 0.0))  # nose into the breeze
	var a := phase + t * CIRCLE_SPEED
	var at := centre + Vector3(cos(a), 0.0, sin(a)) * radius
	# Flying round the circle, nose along it, banked into the turn.
	var along := Vector3(-sin(a), 0.0, cos(a))
	return Transform3D(Basis.looking_at(along) * Basis(Vector3.FORWARD, 0.35), at)


func _place(t: float) -> void:
	for i in flock.size():
		multimesh.set_instance_transform(i, bird_transform(i, t))


## A soft V of two swept wings, nose toward -Z, about WINGSPAN across.
static func build_bird_mesh() -> ArrayMesh:
	var b := Art.Builder.new()
	var half := WINGSPAN * 0.5
	var body := Vector3(0.0, 0.0, -0.15)
	for s in [-1.0, 1.0]:
		var tip := Vector3(s * half, 0.18, 0.2)
		var elbow := Vector3(s * half * 0.45, 0.12, -0.05)
		b.triangle(body, elbow, Vector3(0.0, 0.0, 0.15), COLOR)
		b.triangle(elbow, tip, Vector3(s * half * 0.4, 0.1, 0.15), COLOR)
	return b.commit()
