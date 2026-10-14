# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Times every Endless kit's build steps (the longest step, and the whole build, per piece).
## godot --headless --path . -s res://tools/kit_times.gd


func _initialize() -> void:
	var worst_all := 0.0
	for id: StringName in EndlessPieces.TABLE:
		var build := EndlessPieces.KitBuild.new(id, 0.25)
		var total := 0.0
		var worst := 0.0
		var worst_step := -1
		var done := false
		while not done:
			var step: int = build._step
			var t := Time.get_ticks_usec()
			done = build.step()
			var ms := (Time.get_ticks_usec() - t) / 1000.0
			total += ms
			if ms > worst:
				worst = ms
				worst_step = step
		worst_all = maxf(worst_all, worst)
		print("%-10s total %6.1f ms  worst step %d %5.1f ms" % [id, total, worst_step, worst])
	print("worst step anywhere %.1f ms" % worst_all)
	quit()
