class_name Autopilot
extends RefCounted
## A simple pilot that flies the demo course: through the radiator thermal, beside the
## hanging lamp (on its left) and under the door frame, through the kettle steam, and out of the window.
## Used by the course tests and the screenshot tool to prove the course can be flown.

## Each stop: where to aim. The pilot moves on to the next stop a few units before
## reaching each one, so it never turns back toward a point it is passing.
var route := [
	{"name": "radiator", "aim": Vector3(-5.0, 9.0, -22.0)},
	{"name": "lamp", "aim": Vector3(-2.9, 6.0, -45.0)},
	{"name": "door", "aim": Vector3(-1.0, 5.6, -52.0)},
	{"name": "kettle", "aim": Vector3(2.4, 10.0, -69.0)},
	{"name": "window", "aim": Vector3(0.0, 7.5, -88.0)},
	{"name": "hills", "aim": Vector3(0.0, 0.0, -1000.0)},
]
var index := 0
var _last_heading := 0.0
## Seconds into the flight at which each stop was passed.
var times := {}


func fly(plane: PaperPlane) -> Vector2:
	var p := plane.global_position
	while p.z < (route[index]["aim"] as Vector3).z + 2.5:
		times[route[index]["name"]] = plane.flight_time
		index += 1
	var stop: Dictionary = route[index]
	var aim: Vector3 = stop["aim"]

	var to := aim - p
	var want := atan2(-to.x, -to.z)
	var error := wrapf(want - plane.model.heading, -PI, PI)
	var turn_rate := wrapf(plane.model.heading - _last_heading, -PI, PI) * 60.0
	_last_heading = plane.model.heading
	var roll := clampf(-error * 2.0 + turn_rate * 0.6, -1.0, 1.0)
	var pitch := 0.0
	if stop["name"] != "hills":
		pitch = clampf((aim.y - p.y) * 0.3 - plane.model.velocity.y * 0.15, -1.0, 0.3)
	return Vector2(pitch, roll)
