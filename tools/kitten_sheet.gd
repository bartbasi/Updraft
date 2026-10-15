# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## The kitten sheet (docs/hazards-plan.md §10): Pip, Smudge and Bramble side by side in each pose
## (asleep, yawning, sitting, watching, wiggling, lunging, flopped, licking a paw, hugging the
## balloon), close up, and sitting at 45 u and 80 u, for judging how cute they are.
##   godot --path . --resolution 1844x720 -s res://tools/kitten_sheet.gd -- --out=<folder>

var _out := "user://kitten_sheet"


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
	env.environment.background_color = Color("c9dcb8")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("f6e1d3")
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 25.0, 0.0)
	world.add_child(sun)
	var wall := MeshInstance3D.new()
	var b := Art.Builder.new()
	b.box(Vector3(0.0, 1.0, -0.9), Vector3(16.0, 7.0, 0.3), Color("c1675a"))
	wall.mesh = b.commit()
	wall.material_override = Art.material()
	world.add_child(wall)
	var kittens: Array[Kitten] = []
	for i in Kitten.COATS.size():
		var k := Kitten.new(Kitten.COATS[i], 3)
		k.position = Vector3((i - 1) * 3.6, 0.0, 0.0)
		world.add_child(k)
		kittens.append(k)
	var balloon := MeshInstance3D.new()
	balloon.mesh = Looks.balloon_mesh("red")
	balloon.material_override = Looks.balloon_material("red")
	balloon.visible = false
	world.add_child(balloon)
	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.current = true
	var poses := [["asleep", Kitten.State.ASLEEP, 0.0], ["yawn", Kitten.State.WAKING, 0.45], ["sitting", Kitten.State.IDLE, 0.0],
		["watching", Kitten.State.WATCHING_YOU, 0.0], ["wiggle", Kitten.State.WIGGLE, 0.4], ["lunge", Kitten.State.LUNGE, 0.2],
		["flop", Kitten.State.MISS, 0.27], ["paw_lick", Kitten.State.MISS, 1.2], ["hug", Kitten.State.HUG, 0.5]]
	for pose in poses:
		for k in kittens:
			k.state = pose[1]
			k._time = pose[2]
			k._wiggle = pose[2]
			k._flyer_local = Vector3(2.5, 3.5, 7.0)
			k._look = Vector2(0.3, -0.3)
			k.paw = Kitten.CHEST + Vector3(0.6, 0.6, 2.6) * (1.0 if pose[0] == "lunge" else 0.0)
			k._process(0.016)
		balloon.visible = pose[0] == "hug"
		balloon.position = kittens[1].hug_point()
		camera.position = Vector3(0.0, 2.2, 10.0)
		camera.look_at(Vector3(0.0, 1.3, 0.0))
		await _frames(4)
		_save("%s_10u" % pose[0])
	for far in [45.0, 80.0]:
		for k in kittens:
			k.state = Kitten.State.IDLE
			k._process(0.016)
		camera.position = Vector3(0.0, 5.0, far)
		camera.look_at(Vector3(0.0, 1.3, 0.0))
		camera.fov = 80.0  # (the chase camera's, so the size is as in flight)
		await _frames(4)
		_save("sitting_%du" % int(far))
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _save(name: String) -> void:
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))
