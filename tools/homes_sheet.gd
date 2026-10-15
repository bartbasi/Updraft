# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## The homes sheet (docs/hazards-plan.md §2-3): every kind of home in both palettes, each with a
## kitten in its window, seen three-quarters on at 30 u and 70 u; then the Farmyard as you come
## into it, and Pip in her hayloft door from the Cat's whiskers! line.
##   godot --path . --resolution 1600x900 -s res://tools/homes_sheet.gd -- --out=<folder>

var _out := "user://homes_sheet"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("bfe3f2")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("f6e1d3")
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 25.0, 0.0)
	world.add_child(sun)
	var camera := Camera3D.new()
	camera.fov = 70.0
	world.add_child(camera)
	camera.current = true
	# The homes in a row on a lawn.
	var lawn := Art.Builder.new()
	lawn.box(Vector3(0.0, -0.05, 0.0), Vector3(200.0, 0.1, 80.0), Color("a8c98e"))
	var lawn_mi := MeshInstance3D.new()
	lawn_mi.mesh = lawn.commit()
	lawn_mi.material_override = Art.material()
	world.add_child(lawn_mi)
	var row := Node3D.new()
	world.add_child(row)
	var types: Array = EndlessHomes.TYPES.keys()
	var i := 0
	for palette in 2:
		for type: String in types:
			var home := {"type": type, "palette": palette, "kitten": Kitten.COATS[i % 3] if float(EndlessHomes.TYPES[type]["sill"]) > 0.0 else "", "seed": 5}
			var built := EndlessHomes.build(&"street", {"at": Vector2.ZERO, "yaw": 0.0}, home)
			var node: Node3D = built["node"]
			node.position = Vector3((i - 3.5) * 20.0, 0.0, 0.0)
			node.rotation.y = -0.5
			row.add_child(node)
			if built["kitten"] != null:
				(built["kitten"] as Kitten).state = Kitten.State.WATCHING_YOU
			i += 1
	for spot in [[Vector3(-35.0, 6.0, 30.0), Vector3(-35.0, 4.0, 0.0), "homes_a"], [Vector3(45.0, 6.0, 30.0), Vector3(45.0, 4.0, 0.0), "homes_b"],
			[Vector3(0.0, 14.0, 70.0), Vector3(0.0, 4.0, 0.0), "homes_70u"]]:
		camera.position = spot[0]
		camera.look_at(spot[1])
		await _frames(4)
		_save(spot[2])
	row.queue_free()
	lawn_mi.queue_free()
	# The Farmyard, as you fly in.
	var kit := EndlessPieces.kit(&"farmyard", 0.5)
	var farm := MeshInstance3D.new()
	farm.mesh = kit.mesh
	farm.material_override = Art.material()
	world.add_child(farm)
	var spec: Dictionary = kit.kittens[0]
	var pip := Kitten.new(spec["coat"], 3)
	pip.position = spec["at"]
	pip.rotation.y = float(spec["yaw"])
	world.add_child(pip)
	pip.state = Kitten.State.WATCHING_YOU
	for spot in [[Vector3(0.0, 12.5, -8.0), Vector3(8.0, 8.0, -50.0), "farmyard_entry"], [Vector3(5.2, 10.6, -38.0), Vector3(16.5, 6.0, -49.0), "farmyard_whiskers"],
			[Vector3(8.6, 8.4, -50.0), Vector3(16.5, 6.0, -49.0), "farmyard_closest"]]:
		camera.position = spot[0]
		camera.look_at(spot[1])
		pip._flyer_local = pip.global_transform.affine_inverse() * camera.global_position
		pip._process(0.016)
		await _frames(4)
		_save(spot[2])
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _save(name: String) -> void:
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))
