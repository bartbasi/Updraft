# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EndlessFarmyard
extends RefCounted
## P20 Farmyard (docs/hazards-plan.md §3), the kitten's own piece: a big red barn across the
## valley's right half with its hayloft door open up the valley and Pip sitting in it, watching you
## come. The "Cat's whiskers!" stars swing past the barn's end just outside her reach (a big star
## at the closest point), then a thermal rises over the rickyard. A farmhouse, a duck pond and the
## ricks (solid) make the farm.

const ID := &"farmyard"
const BARN := Rect2(14.0, -62.0, 20.0, 12.0)  ## x 14..34, z -62..-50
const BARN_WALLS := 8.0
const BARN_RIDGE := 13.0
const PIP_AT := Vector3(16.5, 5.0, -49.2)  ## The hayloft door's sill (0.8 out, so its dark room shows).
const PIP_YAW := -0.35  ## Facing up the valley, turned 20 degrees toward the valley's middle.
const RICKYARD := Vector2(-4.0, -80.0)
const RICKS: Array[Vector2] = [Vector2(-20.0, -74.0), Vector2(-24.0, -82.0), Vector2(-19.0, -90.0)]
const POND := Vector2(-8.0, -20.0)
const RED := Color("c1675a")


static func content(k: EndlessPieces.Kit, look: Art.Builder, solid: PackedVector3Array, d: float) -> void:
	# The barn (and Pip with it) stands nearer the whiskers' line the later in a run.
	var shift := -lerpf(1.5, 2.8, d)
	var barn := Rect2(BARN.position + Vector2(shift, 0.0), BARN.size)
	var pip_at := PIP_AT + Vector3(shift, 0.0, 0.0)
	# The yard (straw), the pond and its ducks (looks).
	for i in 8:
		var z0 := -40.0 - i * 1.25
		for j in 13:  # (in 2 u steps, so it lies on the ground between the grid's corners)
			var x0 := 8.0 + shift + j * 2.0
			var a := Vector3(x0, EndlessPieces.grid_height(ID, x0, z0) + EndlessPieces.PAINT_LIFT, z0)
			var b := Vector3(x0 + 2.0, EndlessPieces.grid_height(ID, x0 + 2.0, z0) + EndlessPieces.PAINT_LIFT, z0)
			var c := Vector3(x0, EndlessPieces.grid_height(ID, x0, z0 - 1.25) + EndlessPieces.PAINT_LIFT, z0 - 1.25)
			var e := Vector3(x0 + 2.0, EndlessPieces.grid_height(ID, x0 + 2.0, z0 - 1.25) + EndlessPieces.PAINT_LIFT, z0 - 1.25)
			look.triangle(a, c, b, Color("e9d29a"))
			look.triangle(b, c, e, Color("e9d29a"))
	var pond_y := EndlessPieces.grid_height(ID, POND.x, POND.y) + EndlessPieces.PAINT_LIFT * 2.0
	for i in 16:
		var a0 := TAU * i / 16.0
		var a1 := TAU * (i + 1) / 16.0
		look.triangle(Vector3(POND.x, pond_y, POND.y), Vector3(POND.x + cos(a0) * 5.0, pond_y, POND.y + sin(a0) * 5.0), Vector3(POND.x + cos(a1) * 5.0, pond_y, POND.y + sin(a1) * 5.0), EndlessPieces.WATER)
	for i in 3:
		var duck := Vector3(POND.x - 1.5 + i * 1.4, pond_y + 0.15, POND.y + (i % 2) * 1.2 - 0.6)
		look.sphere(duck, 0.3, Color.WHITE, Vector3(1.3, 0.8, 1.0), 6, 3)
		look.sphere(duck + Vector3(0.3, 0.3, 0.0), 0.16, Color.WHITE, Vector3.ONE, 6, 3)
		look.box(duck + Vector3(0.48, 0.28, 0.0), Vector3(0.14, 0.06, 0.08), Color("f2b63c"))
	# The barn: walls on a plinth, a gambrel roof, cart doors; the hayloft door open (Pip's).
	var floor_y := 0.0
	for x in [barn.position.x, barn.end.x]:
		for z in [barn.position.y, barn.end.y]:
			floor_y = maxf(floor_y, EndlessPieces.ground(ID, x, z))
	var centre := Vector3(barn.get_center().x, floor_y, barn.get_center().y)
	EndlessPieces._solid_box(look, solid, centre + Vector3(0.0, -0.6, 0.0), Vector3(barn.size.x + 0.6, 1.2 + floor_y, barn.size.y + 0.6), Color("d8cfc2"))
	EndlessPieces._solid_box(look, solid, centre + Vector3(0.0, BARN_WALLS * 0.5, 0.0), Vector3(barn.size.x, BARN_WALLS, barn.size.y), RED)
	var half := barn.size.x * 0.5 + 0.5
	var deep := barn.size.y * 0.5 + 0.5
	var profile: Array[Vector2] = [Vector2(-half, BARN_WALLS), Vector2(-half * 0.55, BARN_WALLS + 3.5), Vector2(0.0, BARN_RIDGE), Vector2(half * 0.55, BARN_WALLS + 3.5), Vector2(half, BARN_WALLS)]
	for i in profile.size() - 1:
		var p0 := centre + Vector3(profile[i].x, profile[i].y, deep)
		var p1 := centre + Vector3(profile[i + 1].x, profile[i + 1].y, deep)
		var q0 := centre + Vector3(profile[i].x, profile[i].y, -deep)
		var q1 := centre + Vector3(profile[i + 1].x, profile[i + 1].y, -deep)
		look.triangle(p0, q0, q1, Color("6f6a78"))
		look.triangle(p0, q1, p1, Color("6f6a78"))
		look.triangle(p0, q1, q0, Color("6f6a78"))
		look.triangle(p0, p1, q1, Color("6f6a78"))
		solid.append_array([p0, q0, q1, p0, q1, p1])
	for end in [-1.0, 1.0]:  # gable ends
		for i in profile.size() - 1:
			var a := centre + Vector3(0.0, BARN_WALLS, end * barn.size.y * 0.5)
			var b := centre + Vector3(profile[i].x * 0.95, profile[i].y, end * barn.size.y * 0.5)
			var c := centre + Vector3(profile[i + 1].x * 0.95, profile[i + 1].y, end * barn.size.y * 0.5)
			look.triangle(a, b, c, RED)
			look.triangle(a, c, b, RED)
			solid.append_array([a, b, c])
	var front := barn.end.y + 0.05
	look.box(Vector3(27.0 + shift, floor_y + 2.5, front), Vector3(6.0, 5.0, 0.1), Color("a8534a"))  # the cart doors
	for dd in [-1.0, 1.0]:
		look.box(Vector3(27.0 + shift, floor_y + 2.5, front + 0.05), Vector3(7.4, 0.3, 0.08), Color("fbf6ee"), Basis(Vector3.BACK, dd * 0.69))
	look.box(Vector3(pip_at.x, pip_at.y + 3.9, front + 0.6), Vector3(4.2, 0.25, 1.4), Color("6f6a78"))  # the hay-hood over the door
	look.box(Vector3(pip_at.x + 1.2, pip_at.y + 4.4, front + 1.0), Vector3(0.25, 0.25, 2.2), Color("8b6f5a"))  # the hoist beam
	k.kittens.append({"at": Vector3(pip_at.x, floor_y + pip_at.y, pip_at.z), "yaw": PIP_YAW, "coat": "pip"})
	# The farmhouse across the yard (solid), and the ricks in the rickyard.
	var house := Vector3(-22.0, EndlessPieces.grid_height(ID, -22.0, -40.0), -40.0)
	EndlessPieces._gabled(look, solid, house, Vector3(9.0, 6.5, 12.0), 3.5, Color("f2e3d5"), Color("5f5b70"))
	EndlessPieces._solid_box(look, solid, house + Vector3(0.0, 9.0, -4.0), Vector3(0.9, 2.2, 0.9), Color("b4674f"))
	for x in [-2.6, 2.6]:  # windows on its yard side, closed sage shutters
		for row in [1.6, 4.3]:
			look.box(house + Vector3(4.55, row, x), Vector3(0.1, 1.1, 1.0), Color("6e8fa8"))
			look.box(house + Vector3(4.6, row, x - 0.75), Vector3(0.08, 1.2, 0.45), Color("a8c49a"))
			look.box(house + Vector3(4.6, row, x + 0.75), Vector3(0.08, 1.2, 0.45), Color("a8c49a"))
	for r in RICKS:
		var base := Vector3(r.x, EndlessPieces.grid_height(ID, r.x, r.y) - 0.2, r.y)
		EndlessPieces._solid_cylinder(look, solid, base, 2.2, 2.2, 3.0, Color("e9c98a"), 10)
		look.cylinder(base + Vector3(0.0, 3.0, 0.0), 2.4, 0.2, 1.2, Color("dcb877"), 10)
	# The rickyard's thermal, its spiral and the circle.
	var top := lerpf(25.0, 23.0, d)
	var ground_y := EndlessPieces.ground(ID, RICKYARD.x, RICKYARD.y)
	k.zones.append({"name": "Rickyard", "shape": Thermal.Shape.CYLINDER, "at": Vector3(RICKYARD.x, ground_y, RICKYARD.y), "radius": lerpf(11.0, 10.0, d),
		"height": top - ground_y, "look": Thermal.Look.WARM_AIR, "strength": lerpf(0.85, 0.75, d), "pitch": 1.0, "drifts": true})
	k.clouds.append({"at": Vector3(RICKYARD.x, top + 4.0, RICKYARD.y), "radius": 7.0, "puffs": 4, "zone": "Rickyard"})
	k.birds.append({"zone": "Rickyard", "below_top": 4.0})
	# Cat's whiskers!: past the barn's end, just outside Pip's reach (the big star at the closest).
	# (A gentle swing, a little later late on when a stronger tailwind carries a pilot through the
	# turn; and lower, where a glide in stronger sink arrives.)
	var whiskers := PackedVector3Array([Vector3(1.2, 12.5, -26.0), Vector3(3.0, 11.6, -32.0),
		Vector3(4.8 - 0.4 * d, 10.6, -38.0), Vector3(6.5 - 0.4 * d, lerpf(9.4, 8.6, d), -44.0), Vector3(8.6 - 0.3 * d, lerpf(8.6, 8.1, d), -50.0),
		Vector3(8.6, lerpf(8.2, 7.8, d), -56.0), Vector3(8.2 + 0.4 * d, lerpf(8.0, 7.6, d), -62.0)])
	k.arcs.append({"name": "whiskers", "stars": whiskers, "big": [false, false, false, false, d >= 0.5, false, false], "zone": "",
		"title": "Cat's whiskers!", "bonus": true, "from_entry": 3})
	EndlessPieces._spiral(k, "rickyard spiral", "Rickyard", RICKYARD, 9.0, top, 6, d)
	k.line_points.append({"x": 0.0, "z": -8.0, "dy": 0.0})
	for i in whiskers.size():
		k.line_points.append({"at": whiskers[i]} if i >= 3 else {"x": whiskers[i].x, "z": whiskers[i].z, "dy": -1.0 - i, "max": whiskers[i].y})
	k.line_points.append({"at": Vector3(2.0, 7.6, -68.0)})
	k.line_points.append({"at": Vector3(RICKYARD.x + 4.0, 7.4, RICKYARD.y + 9.0)})
	k.orbits.append({"centre": RICKYARD, "zone": "Rickyard", "radius": 6.0, "to_y": top - 2.0, "up": true, "max_time": 25.0})
	k.line_points.append({"at": Vector3(2.0, top - 5.0, -96.0)})
